# Gem ID Scanner

Gem ID Scanner names a mineral from a photo and names the physical test that separates it from the lookalike. The catalog is about 60 species. A photo is not a hardness test, a streak test, or a lab result, and confidence is capped at 96%.

This repository holds the clients and the API as separate packages:

| Package | What it is |
| --- | --- |
| [gem-id-scanner-ios](gem-id-scanner-ios/) | The shipping iOS app. Camera, on-device color shortlist, Firebase AI Logic hybrid identification, collection, and StoreKit. |
| [gem-id-scanner-android](gem-id-scanner-android/) | Android client. Not started. |
| [gem-id-scanner-web](gem-id-scanner-web/) | Chrome client. Gemini Nano can rank a color brief in the browser. Cloud Gemini sees the photo when that rank is missing or below the escalation threshold. |
| [gem-id-scanner-backend](gem-id-scanner-backend/) | HTTP API for catalog, gallery, records, and analyses shared by the web app and the phones. Firestore correction rules live here today. |

The iOS app identifies through Firebase AI Logic and sends each scan photo to Gemini. Saved specimens stay on the iPhone until a client posts them to the backend. Chrome keeps a confident Gemini Nano rank in the browser and sends the photo only when that rank is missing or below the threshold. Opt-in correction sync writes labels only, with no photo bytes, under the rules in `gem-id-scanner-backend/firebase/`.

## Build the iOS app

```bash
cd gem-id-scanner-ios
brew install xcodegen
xcodegen generate
open GemIDScanner.xcodeproj
```

Setup, Firebase, and the unsigned GitHub Actions compile are documented in [gem-id-scanner-ios/README.md](gem-id-scanner-ios/README.md). Pushes to `main` compile that package on a `macos-26` runner with Xcode 26.6.

## License

Apache License 2.0. See [LICENSE](LICENSE). Copyright 2026 Gem ID Scanner contributors.
