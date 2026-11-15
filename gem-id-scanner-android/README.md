# Gem ID Scanner for Android

This package is the Android client. It is not started.

Build it against [the backend API](../gem-id-scanner-backend/README.md), not against a Gemini key in the app. The product rules match iOS and the web prompt:

- The catalog is the same set of about 60 species. Do not advertise a larger catalog.
- Stage 1 can be an on-device color shortlist. Stage 2 ranks through the backend analysis endpoint.
- Confidence is capped at 96%. Show the route that answered and whether the photo was uploaded.
- A saved specimen uses the same record fields as iOS: name, confidence, band, photo, notes, weight, origin, form, favorite, confirmed, and tags.
- Free use on iOS is 5 scans a day and 20 saved specimens. Do not add a store until that policy is decided for Android.
- Correction uploads are labels only.

Read [the web prompt](../gem-id-scanner-web/AGENT_PROMPT.md) for the screens and the analysis detail. The Android app should cover the same jobs: scan, gemstone catalog, gallery, records, and analysis detail.
