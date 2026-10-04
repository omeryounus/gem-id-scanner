# System Architecture & Technical Specifications 🏛️

**Gem ID Scanner** is engineered with a modular, reactive architecture utilizing SwiftUI, SwiftData, CoreML, and Gemini Vision 2.5 Flash. This document details the subsystem design, data contracts, confidence scoring heuristics, persistence models, and monetization engine.

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
│  │ Stage 1: On-Device CoreML      │  │  │  │ SwiftData ModelContext │  │
│  │ (Vision Neural Classifier)     │  │  │  │ (SpecimenRecord)       │  │
│  └────────────────────────────────┘  │  │  └────────────────────────┘  │
│  ┌────────────────────────────────┐  │  │  ┌────────────────────────┐  │
│  │ Stage 2: Gemini Vision 2.5     │  │  │  │ CorrectionFeedbackQueue│  │
│  │ (Multimodal Cloud Reasoner)    │  │  │  │ (UserDefaults / JSON)  │  │
│  └────────────────────────────────┘  │  │  └────────────────────────┘  │
└──────────────────────────────────────┘  └──────────────────────────────┘
```

---

## 2. Two-Stage Hybrid Identification Pipeline

Mineralogy visual identification presents unique challenges due to pseudomorphism, variable crystal habits, solid solution series, and chromatic impurities. The identification pipeline mitigates single-model hallucinations by combining on-device computer vision with cloud multimodal intelligence.

### Pipeline Flow

```
[Captured Frame / Photo]
          │
          ▼
[Camera Quality Gate] ───(Blur / Low Light / Glare)───► [HUD Quality Warnings]
          │ (Passes Quality Threshold)
          ├──────────────────────────────────────────────────┐
          ▼                                                  ▼
[Stage 1: CoreML On-Device]                     [Stage 2: Gemini Vision 2.5]
- Neural Engine Vision inference                 - Multimodal crystal habit analysis
- Low latency (<100ms)                          - Contextual color zoning & luster
- Top-5 candidate probabilities                 - Top-3 candidate probabilities
          │                                                  │
          └────────────────────────┬─────────────────────────┘
                                   ▼
                   [Identification Coordinator Merge]
                                   │
                   ┌───────────────┴───────────────┐
                   ▼                               ▼
       [High Agreement (≥85%)]        [Ambiguity / Low Conf (<85%)]
                   │                               │
                   ▼                               ▼
          [ResultView.swift]             [BestGuessesView.swift]
      (Direct Specimen Diagnosis)      (Separating Tests & Lookalikes)
```

---

## 3. Confidence Bands & Scientific Ceiling

Non-destructive optical imaging cannot determine internal chemical bonding or isotropic refractive indexes with absolute 100% certainty (which requires X-ray diffraction, electron microprobes, or refractometers). The system enforces an absolute gemological confidence ceiling of **96% (0.96)**.

| Band | Range | Description | Primary UI Screen |
| :--- | :--- | :--- | :--- |
| **Confirmed Match** | `85% – 96%` | Stage 1 and Stage 2 strongly agree on primary species and crystal habit. | [`ResultView.swift`](GemIDScanner/Sources/Views/ResultView.swift) |
| **Likely Match** | `55% – 84%` | High probability match, but visual lookalikes share significant color/habit overlap. | [`ResultView.swift`](GemIDScanner/Sources/Views/ResultView.swift) or [`BestGuessesView.swift`](GemIDScanner/Sources/Views/BestGuessesView.swift) |
| **Best Guesses** | `< 55%` | High visual ambiguity (e.g. tumbled blue minerals, opaque black stones). Requires diagnostic physical tests. | [`BestGuessesView.swift`](GemIDScanner/Sources/Views/BestGuessesView.swift) |

### Merge Heuristic Algorithm

Let $C_1$ and $M_1$ be the top confidence score and mineral name from Stage 1 (CoreML), and $C_2$ and $M_2$ be the score and mineral name from Stage 2 (Gemini Vision):

1. **Species Consensus ($M_1 == M_2$)**:
   $$\text{RawScore} = 0.40 \cdot C_1 + 0.60 \cdot C_2 + 0.08$$
   $$\text{MergedConfidence} = \min(\text{RawScore}, 0.96)$$
2. **Species Divergence ($M_1 \ne M_2$)**:
   $$\text{MergedConfidence} = \min(\max(C_1, C_2) \cdot 0.72, 0.82)$$
   The coordinator flags visual ambiguity, and promotes diagnostic separating tests from `MineralDatabase.lookalikes`.

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
3. In [`SettingsView.swift`](GemIDScanner/Sources/Views/SettingsView.swift) or [`CorrectionQueueView.swift`](GemIDScanner/Sources/Views/CorrectionQueueView.swift), pending corrections can be synced asynchronously to retrain and fine-tune classifier weights.
4. Privacy is preserved via user opt-in (`modelImprovementOptIn` toggle).

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
