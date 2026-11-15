# #BuildHybridAI 2026 — Devpost paste sheet

Contest: https://firebasehybridaihackathon.devpost.com/
Deadline: November 30, 2026, 3:00pm MST.
Platform: iOS. A single strong platform can place. This build does not add Android or Web.
Repository: https://github.com/omeryounus/gem-id-scanner
License: Apache-2.0 (`LICENSE`). Set that license in the GitHub About panel after the repo is public.
Try-it-out URL: none. Judges build the iOS app from the README. Five scans a day require no purchase.

No usage statistics are included. Do not add any unless they come from a real source.

## Tagline (87 characters)

Identify stones on iPhone with Apple Intelligence, and Gemini when that rank is unsure.

## Built with

Swift, SwiftUI, SwiftData, Firebase AI Logic, Firebase App Check, Firebase Remote Config, Cloud Firestore, Firebase Authentication, Apple Foundation Models, StoreKit 2

## Description

Gem ID Scanner helps a rockhound, field collector, or lapidary hobbyist name a stone from a photo and then shows the physical test that separates it from the lookalike. The catalog is about 60 species. Confidence never exceeds 96%, because a photograph cannot replace hardness, streak, or a lab result. The app is free to try: five scans a day and 20 saved specimens, with no purchase required.

Firebase AI Logic performs every Stage 2 identification when the app is configured.

The phone measures specimen color on device. Stage 1 is that color shortlist. It is not a language model. Stage 2 opens a Firebase AI Logic hybrid session whose primary model is Apple's on-device Foundation Model and whose secondary model is Gemini. The default cloud model is `gemini-3.5-flash-lite`. Remote Config key `gemini_model_name` can change it, including to another current Gemini model, without a new build.

The on-device hybrid path accepts text only. The session therefore receives a measured color brief and is told that no photograph is attached, so a confident on-device answer never uploads the JPEG. The response `modelVersion` is the route. If it identifies the Apple on-device model and the score is at or above `cloud_escalation_threshold` (default 0.55, also Remote Config), the app keeps that rank and caps it at 70%. Otherwise Gemini receives the photograph through Firebase AI Logic and must return one JSON object whose names come from the catalog. If both calls fail, the color shortlist remains and the screen says so. A missing or placeholder `GoogleService-Info.plist` does not crash the app. It degrades to that shortlist.

App Check is set before `FirebaseApp.configure()`. Debug builds use the App Check debug provider, which the hackathon accepts. Release builds use App Attest, or DeviceCheck when App Attest is unavailable. Opt-in corrections use anonymous Authentication and write labels to Cloud Firestore. The rules reject photo fields. The local dataset export can still contain JPEGs, and that file stays on the device unless the user shares it.

The result screen names which route answered: on-device Apple Intelligence, Gemini looking at the photo, Gemini ranking the color brief, or the color shortlist alone.

## What already existed, and what was built during the submission period

This is an existing app. Before this period it already captured a specimen, shortlisted it by color, identified it with a direct on-device Apple Intelligence call, saved a collection, offered lookalike tests, and sold a higher scan limit with StoreKit.

During the submission period Stage 2 was replaced with a runtime Firebase AI Logic hybrid call. Capable iPhones now answer from the on-device model through that SDK, and uncertain or unsupported devices fall through to Gemini vision. App Check, Remote Config, and opt-in Firestore label sync were added. The privacy copy, settings, and architecture notes were updated so they describe that hybrid path. The free tier was left in place so a judge can use the app without paying.

## Demo video

Record a public YouTube video, in English, at 3 minutes or under. This environment cannot record or upload it. Use a build that contains a real `GoogleService-Info.plist` and a registered App Check debug token, or the cloud path will not run.

1. Open the scanner and show the free scan meter. Do not purchase anything. (about 15 seconds)
2. Open Settings and show the Hybrid Identification status while Apple Intelligence is on. (about 15 seconds)
3. Scan a distinct stone. On the result, show the line that says Firebase AI Logic ran Apple Intelligence on the iPhone and the photo stayed on the device. Open the mineral page and one separating test. (about 45 seconds)
4. Force the cloud path. Either turn Apple Intelligence off, or set Remote Config `cloud_escalation_threshold` to `0.90` so the on-device cap of 0.70 escalates. Scan again and show the line that says Gemini examined the photo. (about 45 seconds)
5. Show a low-confidence result, the best-guesses list, and a physical test the user would actually do. (about 30 seconds)
6. Save the specimen, open the correction queue, and say that opt-in sync uploads the corrected name and not the photo. End on the value: a field identification with an honest confidence ceiling. (about 30 seconds)

Say in the video, in one sentence, that Stage 2 is Firebase AI Logic choosing on-device Apple Intelligence or cloud Gemini.

## Checklist before you submit

- [ ] Create the Firebase project and download `GoogleService-Info.plist` into `gem-id-scanner-ios/GemIDScanner/Resources/`. Confirm it is not committed.
- [ ] Enable the Gemini Developer API for Firebase AI Logic.
- [ ] Enforce App Check for Firebase AI Logic. Register the debug token from the first debug launch. Do not commit the token.
- [ ] Enable Anonymous Authentication.
- [ ] Deploy `gem-id-scanner-backend/firebase/firestore.rules`.
- [ ] Publish Remote Config: `gemini_model_name` = `gemini-3.5-flash-lite`, `cloud_escalation_threshold` = `0.55`.
- [ ] On a Mac, from `gem-id-scanner-ios`, run `xcodegen generate`, build with Xcode 26, and scan once on device for each route above.
- [ ] Make https://github.com/omeryounus/gem-id-scanner public.
- [ ] Set the GitHub About license to Apache-2.0 so it is visible without opening `LICENSE`.
- [ ] Publish the YouTube video and paste the URL into Devpost.
- [ ] Paste the tagline and description from this file. Mention that the project is free to try.
- [ ] Submit on Devpost before November 30, 2026, 3:00pm MST.

Nothing has been committed or pushed from the machine that prepared these files.
