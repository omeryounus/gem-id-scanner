# Gem ID Scanner for iOS

This directory is the iOS app inside the [Gem ID Scanner](../README.md) monorepo. Android, web, and the HTTP API live in the sibling packages.

An iOS app that names a mineral from a photo, then tells you the physical test that separates it from the lookalike. Built for rockhounds, field collectors, and lapidary hobbyists.

Stage 1 is an on-device color shortlist across a catalog of about 60 species. Stage 2 calls **Firebase AI Logic** at runtime. A capable iPhone ranks a measured color brief with Apple's Foundation Model, and the photo stays on the device. If that model is unavailable, or the rank is below a Remote Config threshold, Gemini sees the photograph through the same Firebase client.

Confidence is capped at 96%. A photo is not a hardness test, a streak test, or a lab result.

The app is free to try. Five scans a day and 20 saved specimens do not require a purchase. StoreKit subscriptions raise those limits.

## What the app already did, and what changed for #BuildHybridAI

The camera, catalog, collection, correction queue, and StoreKit paywall already existed. Stage 2 used to call Apple's Foundation Models API directly.

For the Firebase Hybrid AI hackathon, Stage 2 was rebuilt on Firebase AI Logic:

- A hybrid session uses the on-device system model first and Gemini second.
- The on-device call is text only, because the hybrid on-device path does not accept images. The JPEG is uploaded only on the cloud-vision path.
- App Check is installed before Firebase starts. Debug builds use the App Check debug provider. Release builds use App Attest, or DeviceCheck when App Attest is unavailable.
- Remote Config sets `gemini_model_name` (default `gemini-3.5-flash-lite`) and `cloud_escalation_threshold` (default `0.55`).
- Opt-in corrections sign in with anonymous Authentication and write labels to Firestore. Photo bytes are not in that document.

The Firebase iOS SDK is pinned to **12.19.3**. That is the last 12.x release that still ships `hybridModel(primary:secondary:)`, which is the hybrid API in the hackathon docs. Firebase 13 removed that API.

## How a scan runs

1. The camera checks lighting, focus, and glare.
2. Stage 1 builds a color shortlist on the device. This step is not a language model.
3. If `GoogleService-Info.plist` is missing or still has placeholder values, the app shows that shortlist and explains that Firebase is not configured.
4. Otherwise Firebase AI Logic opens a hybrid session. The prompt tells the on-device model that no photograph is attached.
5. The response `modelVersion` is the route. An Apple on-device version at or above the escalation threshold is kept, and the photo never leaves the phone. On-device text confidence is capped at 70%.
6. Any other outcome sends the JPEG to Gemini through Firebase AI Logic and asks for one JSON object constrained to the catalog.
7. The coordinator merges the two stages. Agreement is `0.35 * stage1 + 0.65 * stage2`, capped at 0.96. Disagreement uses the lower score, capped at 0.78.

The result screen and the best-guesses screen both name the route that answered.

## Project layout

The app target is generated from [`project.yml`](project.yml) with XcodeGen. [`Package.swift`](Package.swift) builds the same sources as a library. Open the generated Xcode project to run the app.

```
GemIDScanner/Sources/Services/FirebaseBootstrap.swift        App Check, then Firebase
GemIDScanner/Sources/Services/HybridRuntimeConfig.swift      Remote Config
GemIDScanner/Sources/Services/HybridIdentificationService.swift  hybrid session + cloud image call
GemIDScanner/Sources/Services/AppleVisionService.swift       Stage 2 policy
GemIDScanner/Sources/Services/IdentificationCoordinator.swift  sequence and merge
GemIDScanner/Sources/Services/CorrectionCloudSync.swift      opt-in Firestore labels
../gem-id-scanner-backend/firebase/firestore.rules
GoogleService-Info.example.plist
../SUBMISSION.md                                             Devpost paste sheet
```

## Requirements

- Mac with Xcode 26 and the iOS 26.4 SDK
- An iPhone that can run the app (Apple Intelligence is required for the on-device route)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- A Firebase project, for the Gemini path

This repository does not include a Firebase project file. Without one, scans still return the on-device color shortlist.

## Run it

```bash
brew install xcodegen
# Copy GoogleService-Info.example.plist to GemIDScanner/Resources/GoogleService-Info.plist
# and replace every REPLACE_ value with the iOS app from your Firebase project.
# The real plist is gitignored.
xcodegen generate
open GemIDScanner.xcodeproj
```

In the Firebase console:

1. Create a project and add an iOS app with bundle id `com.gemidscanner.app`.
2. Enable the Gemini Developer API for Firebase AI Logic.
3. Turn on App Check. Enforce it for Firebase AI Logic. For a debug install, register the debug token that the debug provider prints on first launch. Do not commit that token.
4. Enable Anonymous Authentication.
5. Publish Remote Config parameters `gemini_model_name` = `gemini-3.5-flash-lite` and `cloud_escalation_threshold` = `0.55`.
6. Deploy the rules from `gem-id-scanner-backend`: `firebase deploy --only firestore:rules`, or paste [`firestore.rules`](../gem-id-scanner-backend/firebase/firestore.rules) into the console.

Debug builds set the Remote Config minimum fetch interval to 0 so a console change shows up on the next scan. Release builds wait 12 hours.

## Continuous integration

Pull requests and pushes to `main` compile an unsigned simulator build on a GitHub `macos-26` runner with Xcode 26.6. The workflow lives at [`.github/workflows/ios-build.yml`](../.github/workflows/ios-build.yml) and runs inside this directory. That job checks that the app compiles. It does not sign an IPA or run the camera. Tagged releases still use [`.github/workflows/testflight.yml`](../.github/workflows/testflight.yml), which uses the same runner and Xcode.

## Privacy

A confident on-device rank keeps the photograph on the iPhone. The photograph is sent to Gemini through Firebase AI Logic only when the on-device model is unavailable or its score is below the escalation threshold. Correction sync is off unless the user turns on Contribute to AI Improvement, and that upload contains labels only. The in-app privacy policy says the same thing.

## License

Apache License 2.0. See [LICENSE](../LICENSE). Copyright 2026 Gem ID Scanner contributors.
