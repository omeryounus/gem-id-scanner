# Agent prompt: build the Gem ID Scanner web app

The Chrome client in this directory is already built. iPhone scans send every photograph to Gemini and keep the on-device color rank only when Gemini does not answer. The route lines below still describe whichever route actually answered.

## Outcome

Build a web application for Gem ID Scanner in `gem-id-scanner-web/`. A person can look up the curated gemstone catalog, identify a photo, inspect the full analysis, save the specimen, and browse the photos and records that came from this site or from a phone once the phone posts them.

The iOS app already does this job on device. The web app is the shared desk for the same specimens. It is a field tool for rockhounds, not a shop, a metaphysical guide, or a social network.

## Read these before writing code

- `gem-id-scanner-ios/GemIDScanner/Sources/Models/Mineral.swift`
- `gem-id-scanner-ios/GemIDScanner/Sources/Models/Lookalike.swift`
- `gem-id-scanner-ios/GemIDScanner/Sources/Models/SpecimenRecord.swift`
- `gem-id-scanner-ios/GemIDScanner/Sources/Models/IdentificationResult.swift`
- `gem-id-scanner-ios/GemIDScanner/Sources/Models/ConfidenceBand.swift`
- `gem-id-scanner-ios/GemIDScanner/Sources/Database/MineralDatabase.swift`
- `gem-id-scanner-ios/README.md`
- `gem-id-scanner-backend/openapi.yaml`
- `gem-id-scanner-backend/README.md`

The catalog is the list built in `MineralDatabase.swift`. It is about 60 species. That file is the source of names, formulas, hardness, lookalikes, and tests. Do not invent species, photos of species, or a larger catalog. Do not write "300+", "500+", or "our AI is certain."

## Product rules you must not break

- Confidence is capped at 96% (`0.96`). Never show 100% or a score above 96.
- Bands, matching iOS:
  - Confirmed: 0.85 to 0.96. Title "High Match".
  - Likely: 0.55 up to but not including 0.85. Title "Likely Match".
  - Best Guesses: below 0.55. Title "Top Possibilities".
- A photo is not a hardness test, a streak test, or a lab result. Say that on the analysis page.
- Stage 1 is a color shortlist. It is not a language model. Label it that way.
- `inferenceRoute` is one of `on_device`, `cloud_text`, `cloud_vision`, `shortlist`. Show a plain-language engine line:
  - `on_device`: ranked on the phone with Apple Intelligence. The photo stayed on the device.
  - `cloud_text`: ranked from a measured color brief. The photo stayed on the device.
  - `cloud_vision`: a cloud model examined the photo. Name `modelVersion` when it is present.
  - `shortlist`: color shortlist only. No catalog rank came back from the model.
- `photoUploaded` is the web name for the iOS `photoLeftDevice` flag. Show it in the analysis header. Do not hide it in a tooltip only.
- Separating tests are the product. Every analysis and every gemstone page must show how to tell the top name from its lookalikes.
- Correction payloads are labels only: corrected name, form, basis, notes. Do not upload the photo again as part of a correction.
- Free use on iOS is 5 scans a day and 20 saved specimens. If the session payload includes `scansRemaining` and `recordsRemaining`, show them. Do not build a paywall or StoreKit.
- Do not put a Gemini, Firebase, or other model API key in the browser. The web app calls `gem-id-scanner-backend` only.
- Specimens saved only on an iPhone are not in this API today. The iOS app keeps them in SwiftData. The records page must say that phone-only saves appear here after the iOS app posts them. Do not fake a populated phone sync.

## Stack

Use Vite, React, and TypeScript in this directory. Use React Router. Call the API with `fetch` and `VITE_API_BASE_URL`, default `http://localhost:8080`. Send `Authorization: Bearer <token>` after `POST /v1/session`. Store the token in `sessionStorage`.

One global stylesheet is enough. No component library is required. The page must work at 390px wide and at 1200px wide.

If the API is not running, add a dev fixture mode behind `VITE_USE_FIXTURES=true` that serves a few minerals copied from `MineralDatabase.swift` and one sample analysis. The fixture data uses real catalog names only. The default path is the live API. Document both in `gem-id-scanner-web/README.md`.

## Visual language

Match the iOS app. Dark field bench, not a pastel crystal shop.

- Page background near `rgb(15, 18, 26)`.
- Accent near `rgb(242, 173, 46)` for the selected nav item, the confidence ring, and primary buttons.
- Body text off-white. Secondary text at about 65% white.
- Cards are slightly lighter than the page, with a 1px border at low contrast.
- Type is a plain system stack. Names are larger than metadata.
- Confidence is a ring or a clear percent, plus the band title. Color the ring amber, not a traffic-light red/green that implies laboratory certainty.
- Photos use `object-fit: cover` in the gallery and `object-fit: contain` on the analysis page so the specimen is not cropped away.
- Do not use stock photos of minerals. If a record has no image, show the mineral name as text.

## Information architecture

Persistent nav, same jobs on desktop and as a bottom or top bar on a phone:

1. Identify
2. Gemstones
3. Gallery
4. Records

The analysis detail and the gemstone detail are routes, not nav items. A small session line shows scans and saves remaining.

## Routes

| Route | Page |
| --- | --- |
| `/` | Identify |
| `/gemstones` | Catalog index |
| `/gemstones/:name` | Catalog detail. Encode the mineral name. |
| `/gallery` | Photo grid of saved specimens |
| `/records` | Specimen list |
| `/records/:id` | Specimen record |
| `/analyses/:id` | Analysis detail |
| `/privacy` | Short privacy note |

Suggested route, build it in the same pass: `/compare` for two catalog minerals side by side.

## Identify (`/`)

Purpose: start an analysis from this browser.

- The user drops a JPEG or PNG, or picks a file. A second control can use the webcam when the browser allows it. Show a live preview before submit.
- Explain the shot in one line: fill the frame, avoid glare, include a break or crystal face if there is one.
- Submit `POST /v1/analyses` as multipart with `source=web`.
- While the request runs, show a three-step status that matches the product, even if the backend returns in one response: checking the photo, building the color shortlist, asking for a catalog rank. Do not pretend a step finished if you have not received the response. One honest "Identifying…" state is better than a fake progress animation that advances on a timer.
- On success, go to `/analyses/:id`.
- On a limit error, say how many free scans are left. Do not offer a purchase.
- On a network error, keep the selected file and let the user retry.

## Gemstones (`/gemstones`)

Purpose: the encyclopedia of the curated catalog.

- Load `GET /v1/minerals`.
- Group by category, in this order: Quartz Family, Everyday Finds, Collector Staples, Shop Regulars, Color & Flash.
- Search filters name and `alternativeNames` on the client.
- Filters: category, a color chip from `colorRange`, and a hardness range using `minHardness` and `maxHardness`.
- Each row shows name, family, Mohs hardness, and up to three color words. Link to `/gemstones/:name`.
- Empty search says no catalog entry matched. Do not suggest species that are not in the list.

## Gemstone detail (`/gemstones/:name`)

Load `GET /v1/minerals/{name}`. Render the fields the iOS model already has:

- Name and alternative names
- Category, family, chemical formula, crystal system
- Mohs hardness, specific gravity, luster, streak, cleavage, fracture, transparency, refractive index when present
- Color range and common forms
- Summary, geological origin, rarity, safety and handling, care warnings
- Lookalikes: visual difference, separating test, hardness comparison, diagnostic reaction
- Rule-out tests

Actions: "Compare with a lookalike" pre-fills `/compare` when you build that page. Do not add a buy button.

## Gallery (`/gallery`)

Purpose: the person's own specimen photos, from the web and from phones that have synced.

- Load `GET /v1/gallery`.
- Masonry is unnecessary. Use a simple responsive grid.
- Each tile shows the photo or the name fallback, the mineral name, the band, the date, and a source label: iPhone, Android, or Web.
- Filters: source, favorite, mineral name.
- A tile with an `analysisId` links to `/analyses/:id`. Otherwise it links to `/records/:recordId`.
- Empty state: "No specimen photos yet. Identify one here, or save one in the iOS app after collection sync is on." Do not fill the grid with catalog art.

## Records (`/records`)

Purpose: the collection, which iOS calls the vault.

- Load `GET /v1/records`.
- Columns or stacked rows: photo, mineral name, band, confidence percent, date, source, favorite.
- Sort by date, name, or confidence.
- Search by name, notes, origin, and tags.
- The empty state distinguishes two cases in one short paragraph: nothing has been saved from the web yet, and saves that exist only on an iPhone are still on that iPhone.
- A control opens Identify.

## Record detail (`/records/:id`)

Load `GET /v1/records/{id}`. Show the saved fields and let the user edit:

- notes
- weight in grams
- origin (where they found or bought it). Label the field "Where you got it", stored as `originSource`
- form: Rough, Tumbled, Faceted / Cut, Cabochon, Geode / Cluster, Carved
- favorite
- "I confirmed this" (`userConfirmed`)
- tags

Save with `PATCH /v1/records/{id}`. Delete asks for confirmation, then `DELETE`. If `analysisId` is present, link "View analysis". Link the mineral name to the catalog page.

This page is the place for the person's notes. The analysis page is the place for what the model said. Do not merge them into one scrolling dump.

## Analysis detail (`/analyses/:id`)

This is the most important screen. Load `GET /v1/analyses/{id}`. Also load the catalog entry for `topCandidate.mineralName` when that request succeeds, so lookalikes come from the catalog even if the analysis payload is short.

Layout, top to bottom:

1. Photo, or the no-photo fallback. Under it, `imageQualityNotice` when present.
2. Mineral name, band title, confidence percent capped at 96, and the engine line from `engineSummary`. If `engineSummary` is missing, build it from `inferenceRoute` using the sentences in the product rules.
3. A single sentence for the photo: "The photo stayed on the device" when `photoUploaded` is false, and "The photo was sent for a cloud rank" when it is true. Include the source (iPhone, Android, Web) and the time.
4. Stage 1. Heading "Color shortlist". Not a model. Show `topMineralName`, score, and the top few `allProbabilities` as a short list.
5. Stage 2, when present. Heading depends on the route. Show reasoning, visual cues, and up to three candidates with scores. Scores at or above the cap display as 96%.
6. Separating tests from `separatingTests`, `stage2.suggestedTests`, and the catalog lookalikes. Each lookalike shows the test a person can do, not a paragraph of geology.
7. Other candidates. If the band is Best Guesses, lead with this list instead of a single winner. The heading is "Top possibilities".
8. Actions: Save to records (hidden or switched to "Open record" when `recordId` is set), Correct this, Open catalog entry.

Correct this opens a form: corrected mineral (a select limited to catalog names, plus the typed name only if they choose "Not in the catalog"), form, what they checked (streak, hardness, acid, locality, other), and notes. Submit `POST /v1/analyses/{id}/corrections`. Tell them the photo is not part of that upload.

A web analysis will usually have `inferenceRoute` of `cloud_vision` or `shortlist`, because this browser does not run Apple Intelligence. Still render `on_device` and `cloud_text` correctly. Those records arrive from iOS.

## Compare (suggested, build it)

`/compare?a=Quartz&b=Calcite`

Two columns from the catalog: hardness, streak, luster, cleavage, and the lookalike note if one names the other. This is the desk version of the separating-test card. If either name is missing, show two catalog pickers.

## Privacy page

One screen, plain language:

- The catalog pages do not need an account.
- Identify sends the selected photo to the Gem ID Scanner API.
- A rank that started on an iPhone may never have uploaded the photo. The analysis page says which happened.
- Corrections store the corrected label and notes, not a new copy of the photo.
- The session token is an anonymous browser session.

Do not invent a company address, a GDPR representative, or usage statistics.

## States to handle on every data page

- Loading
- Empty, with a sentence that says what would fill it
- API down, with retry
- Unknown id, with a link back to the list
- Session expired: call `POST /v1/session` again and retry the read once

## Acceptance checks

Run the app and walk these paths. A screenshot of the catalog is not enough.

1. Open `/gemstones`, search a name you saw in `MineralDatabase.swift`, and open its detail. Lookalikes and a separating test are visible.
2. Search for a famous gem that is not in the catalog. The page says there is no entry. It does not invent one.
3. With fixtures or a live API, open an analysis whose confidence is above 0.96 in the raw payload only if you are testing the clamp. The UI shows at most 96%.
4. Open one analysis for each route string, or fixture all four. Each shows a different engine line and the correct photo sentence.
5. Save a record from an analysis, see it on Records and, when it has a photo, on Gallery. Edit notes and favorite. Refresh and see the edit.
6. Submit a correction and confirm the request body has no image field.
7. Narrow the window to 390px. Nav, identify, gallery grid, and analysis actions are usable without horizontal scrolling.
8. Stop the API with fixtures off. The catalog page shows the error and a retry control, not a blank page.

## Out of scope

- Rewriting the iOS app, Fastlane, or the Firebase hybrid session
- A model key in client code
- Accounts with passwords, followers, or comments
- Payments
- Map tracking of find sites
- Admin tools for editing the catalog
- New minerals

## When you finish

Update `gem-id-scanner-web/README.md` with the install command, `VITE_API_BASE_URL`, `VITE_USE_FIXTURES`, and the routes. Leave the iOS package and the backend contract as you found them unless an endpoint is missing for a screen above. If you need a field that `openapi.yaml` does not have, add it there and in the README rather than inventing a second client-only shape.
