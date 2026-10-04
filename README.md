# Gem ID Scanner 💎

A state-of-the-art iOS application for mineral, crystal, gemstone, and rock identification built with **SwiftUI**, **SwiftData**, **CoreML**, **Gemini Vision 2.5 Flash**, and **StoreKit 2**.

Designed for field geologists, rockhounds, lapidary artisans, jewelers, and nature enthusiasts, Gem ID Scanner pairs lightning-fast on-device neural classification with cloud multimodal AI verification to deliver diagnostic mineralogy guidance.

---

## 🌟 Key Features

- 📸 **Smart Camera Viewfinder & Real-Time HUD**: Dynamic focus reticle with optical quality warnings (low light, motion blur, glint reflection, macro distance).
- 🧠 **Dual-Engine Identification Pipeline**:
  - **Stage 1 (On-Device CoreML)**: Sub-100ms classification on Apple Neural Engine.
  - **Stage 2 (Gemini Vision 2.5 Flash)**: Multimodal reasoning evaluating crystal habit, cleavage planes, lustre, and color zoning.
  - **Gemological Confidence Ceiling**: Realistic confidence scores capped at **96%**, honoring the scientific reality that non-destructive optical scans cannot guarantee 100% molecular certainty.
- 🔬 **Diagnostic Separation Guides**: Multi-candidate disambiguation for visual lookalikes (e.g., *Sodalite vs. Lapis Lazuli*, *Pyrite vs. Chalcopyrite*, *Quartz vs. Topaz*) with physical tests (Mohs hardness, streak plate, UV fluorescence, acid test).
- 🏺 **SwiftData Specimen Vault**: Organize and catalog personal finds with photos, weights, locality tags, crystal forms (rough, tumbled, faceted, geode), and custom field notes.
- 🏷️ **Share Card & Certificate Generator**: Render high-resolution specimen identity cards with chemical formulas, crystal systems, and diagnostic metadata.
- 🔁 **Offline Correction Queue & Active Learning**: Queue misidentification feedback offline; synchronize telemetry to continuously train and fine-tune classifier models.
- 💳 **StoreKit 2 Native In-App Purchases**: Transparent subscription tiers (Monthly, Annual with 3-day free trial, Lifetime Pass) with daily allowance enforcement (5 free scans/day, 20 free collection items).

---

## 📱 Screen-by-Screen Architecture

| Screen | View | Description |
| :--- | :--- | :--- |
| **1. Camera Scanner** | [`CameraHomeView.swift`](GemIDScanner/Sources/Views/CameraHomeView.swift) | Full-screen AVFoundation camera, centering reticle, quality tips banner, torch toggle, scan allowance meter, and photo library picker. |
| **2. Capture Tips** | [`CaptureTipsBanner.swift`](GemIDScanner/Sources/Views/CaptureTipsBanner.swift) | Best practices guide for lighting, backgrounds, multi-angle scanning, and specimen cleaning. |
| **3. Analyzing Pulse** | [`AnalyzingView.swift`](GemIDScanner/Sources/Views/AnalyzingView.swift) | Dual-engine progress visualizer showing stage progression and neural network confidence evaluation. |
| **4. Result (High Confidence)** | [`ResultView.swift`](GemIDScanner/Sources/Views/ResultView.swift) | Confirmed (85–96%) and Likely (55–84%) identification result card with Mohs specs, chemical formula, specimen save dialog, and share card export. |
| **5. Disambiguation (Low Confidence)** | [`BestGuessesView.swift`](GemIDScanner/Sources/Views/BestGuessesView.swift) | Multi-candidate selector for ambiguous specimens (<55%) featuring physical separation tests, "Rule this in" guidance, and user correction triggers. |
| **6. Mineral Encyclopedia** | [`MineralDetailView.swift`](GemIDScanner/Sources/Views/MineralDetailView.swift) | Complete gemological reference page containing crystal system, cleavage, fracture, refractive index, specific gravity, UV reaction, and lookalike comparison matrix. |
| **7. Specimen Collection Vault** | [`CollectionView.swift`](GemIDScanner/Sources/Views/CollectionView.swift) | SwiftData-backed grid of saved rock specimens with search, filtering (Rough, Tumbled, Faceted, Geodes), favorite toggles, and detail inspector. |
| **8. Pro Paywall** | [`PaywallView.swift`](GemIDScanner/Sources/Views/PaywallView.swift) | Subscription store with Monthly ($4.99/mo), Annual ($29.99/yr + 3-day trial), and Lifetime ($69.99 once) options, transparent billing disclosures, and purchase restoration. |
| **9. Settings & Correction Queue** | [`SettingsView.swift`](GemIDScanner/Sources/Views/SettingsView.swift) & [`CorrectionQueueView.swift`](GemIDScanner/Sources/Views/CorrectionQueueView.swift) | Daily scan reset countdown, AI improvement opt-in toggle, local cache management, JSON collection export, and offline correction queue inspector. |

---

## 🏗️ Project Structure

```
gem-id-scanner/
├── Package.swift                             # Swift Package Manager Manifest
├── README.md                                 # Overview & Documentation
├── ARCHITECTURE.md                           # System Design & Data Pipelines
└── GemIDScanner/
    └── Sources/
        ├── GemIDScannerApp.swift             # @main SwiftUI App Entry Point & SwiftData Setup
        ├── Models/
        │   ├── ConfidenceBand.swift          # Confirmed, Likely, Best Guesses bands
        │   ├── IdentificationResult.swift    # Dual-engine candidate rankings & merge scores
        │   ├── Lookalike.swift               # Visual lookalike diagnostic separation model
        │   ├── Mineral.swift                 # Comprehensive gemological schema
        │   └── SpecimenRecord.swift          # SwiftData persistent specimen model
        ├── Database/
        │   └── MineralDatabase.swift         # Built-in offline encyclopedia of 500+ species
        ├── Services/
        │   ├── CameraService.swift           # AVFoundation session & image quality analyzer
        │   ├── CoreMLClassifierService.swift # On-device Stage 1 Neural Engine classifier
        │   ├── CorrectionFeedbackService.swift# Offline correction queue & training telemetry
        │   ├── GeminiVisionService.swift     # Cloud Stage 2 Multimodal Vision second-opinion
        │   ├── IdentificationCoordinator.swift# Two-stage orchestration & merge logic
        │   ├── ScanAllowanceManager.swift    # Free tier scan & collection limiter
        │   ├── ShareCardGenerator.swift      # UIGraphics-rendered specimen certificates
        │   └── StoreKitService.swift         # StoreKit 2 subscription & transaction manager
        └── Views/
            ├── MainTabView.swift             # Root Tab Navigation (Scanner, Vault, Settings)
            ├── CameraHomeView.swift          # Live camera viewfinder & scan HUD
            ├── CaptureTipsBanner.swift       # Optical capture best-practice banner
            ├── AnalyzingView.swift           # Dual-engine progress visualizer
            ├── ResultView.swift              # Confirmed identification screen
            ├── BestGuessesView.swift         # Multi-candidate disambiguation screen
            ├── MineralDetailView.swift       # Full mineralogy encyclopedia sheet
            ├── CollectionView.swift          # SwiftData specimen collection vault
            ├── PaywallView.swift             # Pro subscription & StoreKit 2 paywall
            ├── SettingsView.swift            # Preferences, reset countdown & data export
            ├── CorrectionQueueView.swift     # Offline correction queue management
            └── Components/
                ├── ConfidenceRingView.swift  # Circular score indicator
                ├── LookalikeCardView.swift   # Visual lookalike comparison card
                ├── ReticleOverlayView.swift  # Viewfinder laser-grid reticle
                └── SeparatingTestCardView.swift # Mohs/Streak/UV separation test card
```

---

## 🛠️ Requirements & Setup

- **iOS Target**: iOS 17.0+ / iPadOS 17.0+
- **macOS Target** (Optional Catalyst/Designed for iPad): macOS 14.0+
- **Xcode Version**: Xcode 15.0+ or Xcode 16+
- **Swift Version**: Swift 5.9 / Swift 6.0
- **Frameworks**: SwiftUI, SwiftData, AVFoundation, StoreKit 2, CoreML, Vision, PhotosUI

### Opening in Xcode

1. Open Xcode and select **File > Open...**
2. Choose the `Package.swift` file or the `gem-id-scanner` root directory.
3. Select your target device / iOS 17+ Simulator and press **⌘R** to run.

---

## 🔐 Privacy & Offline Reliability

- **On-Device First**: Initial classification happens locally using CoreML on the Apple Neural Engine.
- **Zero Profiling**: Cloud identification via Gemini Vision only transmits specimen imagery for real-time inference without attaching personal identifiers.
- **Offline Vault**: Personal specimen collections, custom notes, and favorite tags are saved locally in the device's private SwiftData storage container.
- **Opt-in Telemetry**: User-submitted corrections are stored in an offline queue and only uploaded if the user explicitly enables "Contribute to AI Improvement".

---

## 📄 License

Copyright © 2026 Gem ID Scanner. All rights reserved.
