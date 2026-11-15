import { getApps, initializeApp } from "firebase/app";
import { initializeAppCheck, ReCaptchaV3Provider } from "firebase/app-check";
import { GoogleAIBackend, getAI } from "firebase/ai";
import { fetchAndActivate, getRemoteConfig, getValue } from "firebase/remote-config";

const config = {
  apiKey: process.env.REACT_APP_FIREBASE_API_KEY,
  authDomain: process.env.REACT_APP_FIREBASE_AUTH_DOMAIN,
  projectId: process.env.REACT_APP_FIREBASE_PROJECT_ID,
  appId: process.env.REACT_APP_FIREBASE_APP_ID,
  messagingSenderId: process.env.REACT_APP_FIREBASE_MESSAGING_SENDER_ID,
};

const filled = (value) => Boolean(value) && !String(value).includes("REPLACE");

export const firebaseConfigured = filled(config.apiKey) && filled(config.appId) && filled(config.projectId) && filled(config.messagingSenderId);

const FALLBACK = { modelName: "gemini-3.5-flash-lite", threshold: 0.55 };

let app = null;
let ai = null;

export function firebaseAI() {
  if (!firebaseConfigured) return null;
  if (ai) return ai;
  const debug = process.env.REACT_APP_FIREBASE_APPCHECK_DEBUG_TOKEN;
  if (debug) {
    self.FIREBASE_APPCHECK_DEBUG_TOKEN = debug === "true" ? true : debug;
  }
  app = getApps()[0] || initializeApp(config);
  const siteKey = process.env.REACT_APP_FIREBASE_RECAPTCHA_SITE_KEY;
  if (siteKey || debug) {
    initializeAppCheck(app, {
      provider: new ReCaptchaV3Provider(siteKey || "debug"),
      isTokenAutoRefreshEnabled: true,
    });
  }
  ai = getAI(app, { backend: new GoogleAIBackend() });
  return ai;
}

export async function hybridSettings() {
  if (!firebaseConfigured) return FALLBACK;
  try {
    const remote = getRemoteConfig(firebaseAI() && app);
    remote.settings.minimumFetchIntervalMillis = 0;
    remote.defaultConfig = {
      gemini_model_name: FALLBACK.modelName,
      cloud_escalation_threshold: String(FALLBACK.threshold),
    };
    await fetchAndActivate(remote);
    const name = getValue(remote, "gemini_model_name").asString().trim();
    const threshold = Number(getValue(remote, "cloud_escalation_threshold").asString());
    return {
      modelName: name || FALLBACK.modelName,
      threshold: threshold > 0 ? Math.min(threshold, 0.96) : FALLBACK.threshold,
    };
  } catch {
    return FALLBACK;
  }
}
