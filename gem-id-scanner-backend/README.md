# Gem ID Scanner backend

HTTP API shared by the web app, Android, and later by the iOS app when it syncs a collection.

The iOS app does not call this API yet. It identifies on device with Firebase AI Logic and keeps specimens in SwiftData. The only cloud write today is opt-in correction labels in Firestore. Those rules are in [`firebase/firestore.rules`](firebase/firestore.rules). Deploy them from this directory:

```bash
firebase deploy --only firestore:rules
```

`GoogleService-Info.plist` and debug tokens stay out of git.

## What to build

A small authenticated JSON API. The contract is [`openapi.yaml`](openapi.yaml). The web prompt in [`../gem-id-scanner-web/AGENT_PROMPT.md`](../gem-id-scanner-web/AGENT_PROMPT.md) is the product spec for the responses.

Rules for every analysis response:

- Names come from the catalog of about 60 species in `gem-id-scanner-ios/GemIDScanner/Sources/Database/MineralDatabase.swift`. Do not add species to make the list look larger.
- `mergedConfidence` is at most `0.96`.
- Bands: Confirmed at 0.85 to 0.96, Likely at 0.55 up to but not including 0.85, Best Guesses below 0.55.
- `inferenceRoute` is `on_device`, `cloud_text`, `cloud_vision`, or `shortlist`.
- `photoUploaded` is true only when the image bytes were sent to a model. A shortlist or an on-device rank keeps it false.
- Agreement across the two stages is `min(0.35 * stage1 + 0.65 * stage2, 0.96)`. Disagreement uses the lower score, capped at `0.78`.
- Store the photo for the user's gallery and record. Do not put photo bytes on a correction document.

Suggested shape: one service the web can run locally, with the catalog loaded from a JSON export of `MineralDatabase`. Anonymous sessions are enough for the first version, matching the iOS anonymous Auth path. Do not put a model API key in a mobile or web client.
