# #BuildHybridAI 2026 — Devpost paste sheet

Contest: https://firebasehybridaihackathon.devpost.com/
Rules: https://firebasehybridaihackathon.devpost.com/rules
Deadline: November 30, 2026, 3:00pm MST (2:00pm PST).
Platforms: iOS and Web (Chrome). Android is not part of this submission.
Repository: https://github.com/omeryounus/gem-id-scanner
License: Apache-2.0 (`LICENSE`). The GitHub About panel shows it.
Try-it-out URL: https://field-bench-gem.web.app (Chrome; runs without a backend). iPhone: public TestFlight link once build 2026111701 is processed. Five scans a day and 20 saved specimens require no purchase.

No usage statistics are included. Do not add any unless they come from a real source.

## Why the repository has to be public

Yes. A public repository is mandatory for this contest, not a preference.

The official rules say the submission must include a GitHub or GitLab URL, and: "The repository must be public and open source by including an open source license file. This license should be detectable and visible at the top of the repository page (in the About section)." Apache is preferred. Any OSI license is allowed.

Judges have to open the code and see Firebase AI Logic imported and called at runtime. A private repo fails that requirement even if the video and description are complete. `LICENSE` is already Apache-2.0. The repo is public and the About panel shows Apache-2.0.

Do not make it public until you are sure no `.env`, `GoogleService-Info.plist`, or App Check debug token is in the tree. Those files are gitignored and were not in the commit on `main`.

## Tagline (85 characters)

Identify a stone on iPhone and in Chrome, on-device first and Gemini for the photo.

## Built with

Swift, SwiftUI, SwiftData, React, Firebase AI Logic, Firebase App Check, Firebase Remote Config, Cloud Firestore, Firebase Authentication, Apple Foundation Models, Chrome Gemini Nano, StoreKit 2

## Description

Gem ID Scanner helps a rockhound, field collector, or lapidary hobbyist name a stone from a photo and then shows the physical test that separates it from the lookalike. The catalog is about 60 species. Confidence never exceeds 96%, because a photograph cannot replace hardness, streak, or a lab result. The app is free to try: five scans a day and 20 saved specimens, with no purchase required.

Firebase AI Logic performs every Stage 2 identification. The browser and the iPhone do not hold a Gemini API key. The default cloud model is `gemini-3.5-flash-lite`. Remote Config key `gemini_model_name` can change it without a new build.

Stage 1 is the same on both clients. The device measures specimen color and builds a shortlist. That step is not a language model.

On iPhone, Stage 2 calls Firebase AI Logic at runtime. A capable phone first ranks a measured color brief with Apple's on-device Foundation Model. That call is text only, so the photo is not attached to it. The app then sends the photograph to Gemini through the same Firebase client on every scan. If Gemini does not return a catalog rank, the on-device color rank is kept and capped at 70%. If both calls fail, the screen stays on the color shortlist and says so. A missing or placeholder `GoogleService-Info.plist` does not crash the app. It degrades to that shortlist.

In Chrome, Stage 2 also calls Firebase AI Logic at runtime. Gemini Nano ranks the color brief when desktop Chrome can run it, and that photograph stays in the browser. The photo is sent to cloud Gemini only when Nano is unavailable or the on-device rank is below `cloud_escalation_threshold` (default 0.55, also Remote Config). The result names the route: `on_device`, `cloud_text`, `cloud_vision`, or `shortlist`.

App Check is required by Firebase AI Logic. Debug builds use the App Check debug provider, which the hackathon accepts. Release iOS builds use App Attest, or DeviceCheck when App Attest is unavailable. Opt-in corrections use anonymous Authentication and write labels to Cloud Firestore. The rules reject photo fields. The local dataset export can still contain JPEGs, and that file stays on the device unless the user shares it.

The result screen names which route answered: on-device Apple Intelligence, Gemini looking at the photo, Gemini ranking the color brief, or the color shortlist alone.

## What already existed, and what was built during the submission period

This is an existing iOS app. Before this period it already captured a specimen, shortlisted it by color, identified it with a direct on-device Apple Intelligence call, saved a collection, offered lookalike tests, and sold a higher scan limit with StoreKit.

During the submission period Stage 2 was replaced with a runtime Firebase AI Logic call on iPhone, and a Chrome client was added for the same catalog. iPhone scans now send the photograph to Gemini after the on-device color rank, because a color-only rank was finishing the scan before Gemini saw the stone. Chrome keeps the hybrid threshold: a confident Nano rank stays in the browser, and an uncertain or unavailable on-device rank sends the photo to Gemini. App Check, Remote Config, anonymous Authentication, and Firestore rules for label-only corrections were added. The free tier was left in place so a judge can use the app without paying.

## Demo video

Record a public YouTube video, in English, at 3 minutes or under. Show both platforms, because the submission claims iOS and Chrome. Open with who it is for and the problem, then show Firebase AI Logic working. Judges may score from the video alone.

1. Say who it is for: a collector names a stone and gets the physical test that separates it from the lookalike. Show the free scan meter. Do not purchase anything. (about 25 seconds)
2. On iPhone, scan a distinct stone. On the result, show the line that says Gemini examined the photograph through Firebase AI Logic. Open one separating test. (about 45 seconds)
3. In Chrome, scan a stone and show the route. If Gemini Nano is available and confident, show that the photo stayed in the browser. Otherwise show that the photo went to Gemini. (about 45 seconds)
4. Show a low-confidence result, the other candidates, and one physical test. (about 25 seconds)
5. Save the specimen. Say that opt-in correction sync uploads the corrected name and not the photo. End on the value: a field identification with an honest confidence ceiling. (about 30 seconds)

Say in the video, in one sentence, that Stage 2 is a Firebase AI Logic call: Apple Intelligence or Gemini Nano on device, and Gemini in the cloud when the photo is needed.

## Checklist before you submit

- [x] Firebase project `field-bench-gem` exists. `GoogleService-Info.plist` is on this machine and is gitignored. It is not in the commit on `main`.
- [x] Gemini Developer API is enabled for Firebase AI Logic.
- [x] Anonymous Authentication is on.
- [x] `gem-id-scanner-backend/firebase/firestore.rules` is deployed. Authenticated users can write only their own label corrections. Photo fields are rejected.
- [x] Remote Config is published: `gemini_model_name` = `gemini-3.5-flash-lite`, `cloud_escalation_threshold` = `0.55`.
- [x] Code is committed and pushed to `main`.
- [x] Confirm one scan on the installed iPhone build. The result must say Gemini examined the photograph.
- [x] App Check debug tokens are registered for local web and iOS testing. Enforcement is still off. The hackathon accepts debug tokens. Do not commit a token. Turn enforcement on only after a production attestation provider exists, or a public site will block visitors.
- [x] Make https://github.com/omeryounus/gem-id-scanner public. This is required. See the section above.
- [x] Set the GitHub About license to Apache-2.0 so it is visible without opening `LICENSE`.
- [ ] Publish the YouTube video and paste the URL into Devpost.
- [ ] Paste the tagline and description from this file. Mention that the project is free to try, and that it runs on iPhone and in Chrome.
- [ ] Submit on Devpost before November 30, 2026, 3:00pm MST.
