# System Architecture & Technical Specifications 🏛️

**Gem ID Scanner** is a SwiftUI and SwiftData iOS app. Stage 1 is an on-device color shortlist. Stage 2 calls Firebase AI Logic at runtime: Apple's Foundation Model when the device can run it, and Gemini when it cannot or when the on-device rank is too uncertain. This document matches the code. The catalog holds about 60 species.

---

## 1. Architectural Overview

The application follows an **MVVM + Coordinator** architectural pattern with unidirectional state flow and decoupled services:

```
┌────────────────────────────────────────────────────────────────────────┐
│                              SwiftUI Layer                             │
│  [CameraHomeView]    [ResultView]    [CollectionView]   [SettingsView] │
│          │                │                 │                  │       │
└──────────┼────────────────┼─────────────────┼──────────────────┼───────┘
           ▼                ▼                 ▼                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        Coordinators & Managers                         │
│  [IdentificationCoordinator]   [ScanAllowanceManager]  [StoreKitService]│
└──────────┬──────────────────────────────────┬──────────────────────────┘
           │                                  │
           ▼                                  ▼
┌──────────────────────────────────────┐  ┌──────────────────────────────┐
│       Dual-Engine Inference          │  │       Persistence Layer      │
│  ┌────────────────────────────────┐  │  │  ┌────────────────────────┐  │
│  │ Stage 1: color histogram       │  │  │  │ SwiftData ModelContext │  │
│  │ shortlist (not a language model)│  │  │  │ (SpecimenRecord)       │  │
│  └────────────────────────────────┘  │  │  └────────────────────────┘  │
│  ┌────────────────────────────────┐  │  │  ┌────────────────────────┐  │
│  │ Stage 2: Firebase AI Logic     │  │  │  │ Correction queue       │  │
│  │ on-device text, Gemini image   │  │  │  │ labels → Firestore     │  │
│  └────────────────────────────────┘  │  │  └────────────────────────┘  │
└──────────────────────────────────────┘  └──────────────────────────────┘
```

---

## 2. Two-Stage Hybrid Identification Pipeline

The two stages run in sequence. Stage 1 never calls a language model. Stage 2 always goes through Firebase AI Logic when a real `GoogleService-Info.plist` is in the app bundle. Without that file the app keeps the color shortlist and says why.

Firebase AI Logic's on-device hybrid path accepts text only, so the iPhone ranks a measured color sentence in that session and does not attach the JPEG there. The photograph is still sent to Gemini through a separate Firebase AI Logic call on every configured scan. The on-device rank is kept only when Gemini does not return a catalog identification. `cloud_escalation_threshold` (default 0.55, Remote Config) is the Chrome rule for skipping that upload. The iPhone does not use it to hold the photo back.

```
[Captured Frame / Photo]
          │
          ▼
[Camera Quality Gate]
          │
          ▼
[Stage 1: on-device color histogram shortlist]
          │
          ▼
[Firebase AI Logic hybrid session — text brief only]
          │
          ▼
[Firebase AI Logic cloud Gemini, JPEG attached]
          │
          ├── catalog JSON returned → that rank, photo left the iPhone
          │
          └── no catalog rank → keep the on-device color rank
                   │
                   ▼
        [IdentificationCoordinator merge, cap 96%]
                   │
          ┌────────┴────────┐
          ▼                 ▼
   [ResultView]     [BestGuessesView]
```

The cloud model name defaults to `gemini-3.5-flash-lite`. Change `gemini_model_name` in Remote Config to move it, including to `gemini-4-hydrogen`, without a new build. App Check is installed before `FirebaseApp.configure()`. Debug builds use the App Check debug provider. Release builds use App Attest, or DeviceCheck when App Attest is unavailable.

---

## 3. Confidence Bands & Scientific Ceiling

Non-destructive optical imaging cannot determine internal chemical bonding or isotropic refractive indexes with absolute 100% certainty (which requires X-ray diffraction, electron microprobes, or refractometers). The system enforces an absolute gemological confidence ceiling of **96% (0.96)**.

| Band | Range | Description | Primary UI Screen |
| :--- | :--- | :--- | :--- |
| **Confirmed Match** | `85% – 96%` | Stage 1 and Stage 2 strongly agree on primary species and crystal habit. | [`ResultView.swift`](GemIDScanner/Sources/Views/ResultView.swift) |
| **Likely Match** | `55% – 84%` | High probability match, but visual lookalikes share significant color/habit overlap. | [`ResultView.swift`](GemIDScanner/Sources/Views/ResultView.swift) or [`BestGuessesView.swift`](GemIDScanner/Sources/Views/BestGuessesView.swift) |
| **Best Guesses** | `< 55%` | High visual ambiguity (e.g. tumbled blue minerals, opaque black stones). Requires diagnostic physical tests. | [`BestGuessesView.swift`](GemIDScanner/Sources/Views/BestGuessesView.swift) |

### Merge Heuristic Algorithm

Let $C_1$ and $M_1$ be the Stage 1 color-shortlist score and name, and $C_2$ and $M_2$ the Stage 2 score and name. An on-device text rank is capped at 0.70 before the merge, because that model never saw the photo. Cloud vision is capped at 0.96.

1. **Same species ($M_1$ equals $M_2$, case-insensitive)**:
   merged = min(0.35 * C1 + 0.65 * C2, 0.96). The primary name is the Stage 1 name.
2. **Different species**:
   merged = min(min(C1, C2), 0.78). The primary name is whichever stage scored higher.

Confirmed (85–96%) should come from agreement with a cloud-vision rank, or from a merge that clears that band. A color-brief rank alone is not treated as confirmed.

---

## 4. Specimen Vault & SwiftData Persistence

The user's personal rock and mineral collection is stored persistently using Apple's modern **SwiftData** framework:

```swift
@Model
public final class SpecimenRecord {
    @Attribute(.unique) public var id: UUID
    @Attribute(.externalStorage) public var photoData: Data?
    public var mineralName: String
    public var confidence: Double
    public var confidenceBandRaw: String
    public var dateAdded: Date
    public var notes: String
    public var weightGrams: Double?
    public var originSource: String?
    public var form: String              // "Rough", "Tumbled", "Faceted", "Geode"
    public var isFavorite: Bool
    public var userConfirmed: Bool
    public var customTags: [String]
}
```

- `@Attribute(.externalStorage)` offloads high-resolution photo bytes to disk, maintaining SwiftData SQLite indexing performance.
- Free tier limit (20 specimens) is checked dynamically by `ScanAllowanceManager` before inserting new records.

---

## 5. Offline Correction Feedback Loop

When a user selects *"None of these match"* or overrides a prediction:
1. `CorrectionFeedbackService` creates a `MineralCorrectionItem`:
   - Predicted Mineral + Confidence Score
   - User Corrected Mineral
   - Field observations & Diagnostic Notes
   - Timestamp & UUID
2. The item is saved to local device storage (`UserDefaults` JSON array) for offline resilience.
3. From [`CorrectionQueueView.swift`](GemIDScanner/Sources/Views/CorrectionQueueView.swift) the user can sync the queue. If Firebase is configured and **Contribute to AI Improvement** is on, `CorrectionCloudSync` signs in with anonymous Authentication and writes `corrections/{id}` in Firestore. The document holds labels only. Photo bytes stay on the device. Rules are in [`firebase/firestore.rules`](../gem-id-scanner-backend/firebase/firestore.rules).
4. If Firebase is not configured and a webhook URL was set, the older webhook upload still runs. A local zip export can still include the JPEGs. That file never leaves the device unless the user shares it.

---

## 6. StoreKit 2 Monetization & Allowance Subsystem

The subscription model is managed natively through `StoreKit 2`:

- **Subscription Tiers**:
  - `com.gemidscanner.pro.monthly` ($4.99/mo)
  - `com.gemidscanner.pro.annual` ($29.99/yr with 3-day free trial)
  - `com.gemidscanner.pro.lifetime` ($69.99 single purchase)
- **Allowance Rules**:
  - **Free Tier**: 5 scans per calendar day. Resets automatically at 00:00 midnight local time. Maximum 20 saved collection specimens.
  - **Pro Tier**: Unlimited scans, unlimited collection storage, high-res certificate exports, offline database inspection.
- **Transaction Listener**: Background task listens to `Transaction.updates` for family sharing, revocations, and external subscription updates.

---

## 7. Diagnostic Testing Framework

The built-in gemological database specifies physical tests for visual lookalikes:

| Diagnostic Test | Tool Required | Diagnostic Example |
| :--- | :--- | :--- |
| **Mohs Scratch Test** | Hardness picks / Quartz point | Calcite ($H=3$) is scratched by copper coin; Quartz ($H=7$) scratches glass. |
| **Streak Plate** | Unglazed porcelain tile | Pyrite yields a greenish-black streak; Gold yields a golden yellow streak. |
| **UV Fluorescence** | 365nm / 254nm UV light | Sodalite exhibits bright orange fluorescence under LWUV; Lapis Lazuli remains inert. |
| **Specific Gravity** | Hydrostatic balance | Topaz ($SG \approx 3.53$) sinks faster than Quartz ($SG \approx 2.65$) in heavy liquids. |
| **Acid Reaction** | 10% Dilute HCl | Calcite effervesces vigorously; Dolomite reacts only in powdered form. |
