# Code Review — gem-id-scanner (baseline)

- **Date:** 2026-10-04 (~1:30 PM PDT)
- **Scope:** 26 Swift files + Package.swift + ARCHITECTURE.md, `main` @ `23ede1d` (9 commits)
- **Reviewer:** Mam (automated review)
- **How to use:** Fix P0 items before TestFlight. P1/P2 before App Store submission. P3/P4 as time allows.

---

## P0 — Ship-blockers (must fix before TestFlight)

### 1. `CoreMLClassifierService.swift` — there is NO ML model
`classify()` is a 64x64 average-color heuristic with name-substring matching (e.g. `name.contains("lapis")`) plus hash jitter. It imports CoreML/Vision but makes zero `VNCoreMLRequest` calls.
- `mineral.name.hashValue` is randomly seeded per process → identical photos can rank differently across launches (non-deterministic).
- Hardcodes a 0.15 floor and defaults unknown images to `("Clear Quartz", 0.50)`, violating the prompt's own anti-default rule.
- UI (`AnalyzingView`, Settings "CoreML 1.4", Paywall "on-device CoreML") presents it as a neural classifier.
- **Fix:** ship a real `.mlmodel`, or re-label the UI honestly (e.g. "on-device heuristic pre-filter").

### 2. `GeminiVisionService.swift` — Stage 2 fabricates results when no API key is set
No UI anywhere sets the API key (SettingsView has no key field; `apiKey` is public but unwritten, defaults to nil), so `analyzeSecondOpinion` ALWAYS takes the fallback path: a fake 0.65s delay, then `synthesizeCloudReasoning()` fabricates "Stage 2 visual synthesis confirmed X…" reasoning, visual cues, and a 0.91 score from the local DB without ever looking at the image — and the coordinator merges it as a real second opinion. Even when a key IS set, any network error silently falls back to the same fabricated content.
- **Fix:** add an API-key entry UI (store in Keychain), surface an "offline heuristic" state in the UI, and never fabricate reasoning text.

### 3. `CorrectionFeedbackService.swift` — sync marks uploaded on failure (data loss)
`syncPendingCorrections` "beta mode" marks corrections `isUploaded=true` even when the endpoint is unreachable or returns non-2xx (catch branch sleeps 0.5s then marks synced). The default endpoint `https://api.gemidscanner.com/v1/beta/corrections` is a placeholder that doesn't exist, so real sync NEVER happens and user data is silently marked uploaded. `CorrectionQueueView`/`SettingsView` toast "Successfully synced N corrections!" on top of this.
- **Fix:** only mark uploaded on verified 2xx; retry with exponential backoff; remove fake-sync paths.

### 4. `CorrectionFeedbackService.swift` — model-improvement consent defaults to opt-OUT
`modelImprovementOptIn` defaults to TRUE when no stored value exists, contradicting ARCHITECTURE.md ("Privacy is preserved via user opt-in") and the in-app Privacy Policy ("If you opt into Model Improvement…"). Photos upload as `image_base64` with no per-item consent.
- **Fix:** default false + explicit consent at submission time.

### 5. `GeminiVisionService.swift` — API key in UserDefaults plaintext
Key `"GemIDScanner_GeminiAPIKey"` in UserDefaults.
- **Fix:** Keychain (or remove key handling entirely until the key UI exists).

---

## P1 — Crashes / dead-ends / data loss

6. `AnalyzingView.swift` — `onAppear` does `if let result = try? await coordinator.identify(...)`; on ANY error the view sits on the scanning animation forever, and `.navigationBarBackButtonHidden(true)` removes the only exit. **Fix:** error state + retry/back.
7. `CameraHomeView.swift` shutter action — catch block comment says "Fallback for simulator" but runs on real devices: creates a dummy purple square and runs `processImageScan` on it, consuming one of 5 daily scans and producing a bogus result. **Fix:** gate to `#if targetEnvironment(simulator)` and show the real error.
8. `GemIDScannerApp.swift` init — `fatalError` if ModelContainer init fails = guaranteed launch crash on SwiftData store corruption. **Fix:** recovery path (delete/recreate store, alert user).
9. `CameraHomeView.processImageScan` → `allowance.recordScan()` fires BEFORE analysis runs; no refund on failure/cancel → users burn daily scans on failed captures.
10. `CorrectionFeedbackService.saveQueue()` — writes the entire queue JSON INCLUDING embedded photoData to UserDefaults ("redundant cache"); with photos this exceeds UserDefaults size guidance → slow launches, possible write failures. **Fix:** disk-only queue + separate image files.
11. `CorrectionFeedbackService.exportCorrectionsDatasetZip` — PureSwiftZipWriter builds the ENTIRE archive in one in-memory Data (plus zipEntries holds every photo Data simultaneously) → jetsam kills on large photo sets; `UInt32(zipData.count)`/`UInt16(entry count)` TRAP on overflow (>4GB/>65535 entries); tempDir is created but never cleaned; `.jpg` extension applied to HEIC/PNG data; `try?` write silently fails. **Fix:** streaming writer or ZIPFoundation, background task, cleanup.
12. `ResultView.swift` / `BestGuessesView.swift` / `CollectionView.swift` — `try? modelContext.save()` everywhere silently swallows SwiftData save errors; saveToCollection marks `userConfirmed: true` without user confirmation and allows duplicates.

---

## P2 — Spec drift / false UI claims

13. Version triple-mismatch: ARCHITECTURE.md and SettingsView claim "Gemini Vision 2.5 Flash"; code calls `gemini-1.5-flash`; accuracy-testing/README benchmarks `gemini-2.5-flash`. Pick one.
14. SettingsView "Mineral Database: v2026.4 (500+ Species)" vs 60 minerals; "Classification Core: CoreML 1.4 + Gemini 2.5" vs no CoreML model; PaywallView "Identify thousands of crystals…" vs 60-species catalog; accuracy-testing 60-species list DIFFERS from the app's catalog; the Gemini prompt names species absent from the local DB (Rainbow Moonstone, Opalite…), which then fail `MineralDatabase.find` → silent nil paths in ResultView.
15. Merge formula drift: ARCHITECTURE.md specifies consensus `0.40·C1+0.60·C2+0.08` and divergence `min(max(C1,C2)·0.72, 0.82)`; `IdentificationCoordinator.swift` implements `0.35·C1+0.65·C2` (no +0.08) and divergence `min(min(C1,C2), 0.78)`.
16. Paywall feature matrix lists "Diagnostic Lookalike Tests" and "Export Specimen Certificates" as Pro perks, but both are fully accessible on the free tier (ResultView share menu is ungated); ARCHITECTURE.md's "high-res certificate exports = Pro" is unenforced. "Instant Dual-Engine AI" claims a cloud engine that never runs.
17. Privacy Policy (SettingsView/PaywallView) claims "Images are not retained" and on-device-first processing — inconsistent with Gemini cloud transmission (Google retention policy applies). "Clear Local Image Cache" only clears URLCache, which the app barely uses — effectively a no-op button.

---

## P3 — Monetization / App Store review risks

18. `StoreKitService.swift` — `SubscriptionTier.priceString` hardcodes "$4.99 / month" etc. instead of `product.displayPrice`: prices drift from App Store Connect (Guideline 3.1.1). PaywallView renders these hardcoded strings.
19. `StoreKitService.purchase` — `#if DEBUG` simulates success (`isProPurchased=true`) when no product is found; a TestFlight build compiled with DEBUG config = free Pro for everyone. Gate explicitly or remove.
20. SettingsView hardcodes "1.0.0 (Build 2026.10)" instead of `Bundle.main` values — will drift.
21. `ScanAllowanceManager` — enforcement is UserDefaults-only; trivially reset by reinstalling or changing the clock. Fine for v1, don't rely on it server-side later.

---

## P4 — Code quality / dead code / validation

22. `IdentificationCoordinator.swift` — `group.next()!` force-unwrap; instantiates `CameraService()` per `identify()` just to call a pure function; duplicated docstring comment.
23. `CorrectionSheetView.swift` — "Your verified ground-truth labels directly train our neural classifier" is false (no training pipeline); `showSuccessToast` state never set; custom mineral name has no length/sanitization validation.
24. Dead state/components: `CorrectionTriggerModalView` (BestGuessesView) defined but never used; `correctionMineralName`/`correctionNotes`, `showSecondAngleBanner` (ResultView), `showSaveSuccessToast` (ResultView), `isEditing`/`notesText`/`originText`/`weightText`/`selectedForm` (SpecimenDetailSheet).
25. `LegalDocumentView` + `LegalText` duplicated privately in both SettingsView.swift and PaywallView.swift.
26. Dead settings: `GemIDScanner_HighPrecisionCloud` ("High-Precision Multimodal AI" toggle) is never read by any service/coordinator/view; same for AutoTorch (no consumer in CameraService flow).
27. Input validation gaps: `weightString` → `Double()` accepts negatives, no range check; notes free-text unbounded.
28. `MineralDatabase.swift` typo: Jasper lookalike "MookReporting Siltstone / Mudstone" (should be "Mookaite"). `Mineral.imageName` is computed but never consumed by any view (no reference imagery in UI).
29. `ConfidenceBand.init` classifies 0.96–1.0 as `.confirmed` (subtitle says "capped at 96%") — harmless today (clamp enforced in `IdentificationResult.init`/`CandidateItem.init`), but the invariant lives in callers, not the type.
30. Gemini JSON parsing: missing `conf_1` → defaults 0.88; score floor `min(max(score,0.30),0.96)` inflates garbage results; no validation that predicted names exist in the DB.

---

## Still missing for TestFlight v1

- Real Stage 1 model (or honest labeling) and a working Stage 2 (API-key entry UI + Keychain, real error/offline states, no fabricated reasoning).
- Honest sync: real endpoint or remove cloud-sync claims; retry with exponential backoff + BGProcessingTask; opt-in default false with per-submission consent.
- Tests: zero unit/UI tests; CI has only testflight.yml (no build/test workflow). Add XCTest for merge math, ConfidenceBand boundaries, ZIP writer round-trip, allowance reset logic.
- Analytics/crash reporting: none.
- Privacy: photo EXIF/GPS stripping before persistence/upload; privacy manifest (`PrivacyInfo.xcprivacy`); confirm `NSPhotoLibraryUsageDescription` / camera usage strings in the Xcode project.
- SwiftData migration plan: `Schema([SpecimenRecord.self])` with no versioned schema; any future field change risks migration failure.
- Paywall: StoreKit `displayPrice`, remove DEBUG backdoor, restore-purchase edge cases.
- Offline states: no offline banner before scan; quality gate advisory-only.
- Catalog parity: reconcile 60-species app DB vs accuracy-testing list vs prompt species; fix "500+ species"/"thousands" copy; wire up reference images (`imageName` unused).
