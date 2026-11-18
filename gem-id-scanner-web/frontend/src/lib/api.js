import axios from "axios";
import { LOCAL_PREFIX, localAdapter, localFileUrl } from "@/lib/localApi";

const KEY = "fieldbench.session";
const BASE = (process.env.REACT_APP_BACKEND_URL || "").trim();

// No backend URL: the app answers its own API from browser storage.
export const localMode = !BASE;

function getSessionId() {
  let id = localStorage.getItem(KEY);
  if (!id) {
    id = crypto.randomUUID();
    localStorage.setItem(KEY, id);
  }
  return id;
}

export const sessionId = getSessionId();

export const api = axios.create({
  baseURL: `${BASE}/api`,
  headers: { "X-Session-Id": sessionId },
  ...(localMode ? { adapter: localAdapter } : {}),
});

export const fileUrl = (path) => {
  if (!path) return null;
  if (path.startsWith(LOCAL_PREFIX)) return localFileUrl(path);
  return `${BASE}/api/files/${path}?sid=${sessionId}`;
};

export const errMsg = (e, fallback = "Something went wrong") => {
  const d = e?.response?.data?.detail;
  if (typeof d === "string") return d;
  if (Array.isArray(d)) return d.map((x) => x.msg).join(", ");
  return fallback;
};
