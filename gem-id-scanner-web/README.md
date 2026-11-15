# Gem ID Scanner for web

Chrome client for the same catalog and the same hybrid decision as the iPhone.

A scan measures colour in the browser, then calls Firebase AI Logic. Gemini Nano ranks that colour brief when Chrome has the on-device model. The photograph stays in the browser when that rank is at or above `cloud_escalation_threshold` (default 0.55). Otherwise cloud Gemini sees the photo. The result names the route: `on_device`, `cloud_text`, `cloud_vision`, or `shortlist`. The page does not embed a Gemini API key.

## Run it

```bash
cd gem-id-scanner-web/frontend
npm install
npm start
```

The API defaults to `http://localhost:8000`. Set these in `frontend/.env` before a hybrid scan. Without them, scans use the colour shortlist.

```
REACT_APP_BACKEND_URL=http://localhost:8000
REACT_APP_FIREBASE_API_KEY=
REACT_APP_FIREBASE_AUTH_DOMAIN=
REACT_APP_FIREBASE_PROJECT_ID=
REACT_APP_FIREBASE_APP_ID=
REACT_APP_FIREBASE_MESSAGING_SENDER_ID=
REACT_APP_FIREBASE_RECAPTCHA_SITE_KEY=
REACT_APP_FIREBASE_APPCHECK_DEBUG_TOKEN=true
```

Use a Firebase web app in the same project as the iOS app. Enforce App Check for Firebase AI Logic, and register the debug token the first launch prints. Enable the Gemini Developer API. Publish Remote Config `gemini_model_name` = `gemini-3.5-flash-lite` and `cloud_escalation_threshold` = `0.55`.

Gemini Nano needs Chrome on desktop, version 139 or newer, with `chrome://flags/#prompt-api-for-gemini-nano-multimodal-input` set to Enabled. The first on-device scan calls `initializeDeviceModel()` from the click that started the scan.

The client also stores catalog records through [the backend API](../gem-id-scanner-backend/openapi.yaml). A cloud-vision photo is the only scan image that API stores.
