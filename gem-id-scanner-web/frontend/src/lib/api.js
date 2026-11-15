import axios from "axios";

const KEY = "fieldbench.session";
const BASE = process.env.REACT_APP_BACKEND_URL;

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
});

export const fileUrl = (path) => (path ? `${BASE}/api/files/${path}?sid=${sessionId}` : null);

export const errMsg = (e, fallback = "Something went wrong") => {
  const d = e?.response?.data?.detail;
  if (typeof d === "string") return d;
  if (Array.isArray(d)) return d.map((x) => x.msg).join(", ");
  return fallback;
};
