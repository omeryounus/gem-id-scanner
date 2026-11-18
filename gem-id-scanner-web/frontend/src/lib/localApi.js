// In-browser stand-in for the backend API. Used when REACT_APP_BACKEND_URL is
// not set, so a static Firebase Hosting build works on its own. It answers the
// same routes as gem-id-scanner-backend/server.py. Records and scans live in
// localStorage; photos live in IndexedDB and never leave this browser unless
// Firebase AI Logic sends one to Gemini for a cloud_vision rank.
import { AxiosError } from "axios";
import MINERALS from "@/data/minerals.json";
import { measureColors, shortlistMinerals } from "@/lib/colorShortlist";
import { readLocalPhoto, saveLocalPhoto } from "@/lib/localPhotos";

const SCAN_LIMIT = 5;
const SAVE_LIMIT = 20;
const CONFIDENCE_CAP = 0.96;
const MINERAL_INDEX = Object.fromEntries(MINERALS.map((m) => [m.id, m]));
const KEYS = { analyses: "fieldbench.local.analyses", records: "fieldbench.local.records", geocache: "fieldbench.local.geocache" };

// ---------- storage ----------
function load(name) {
  try {
    return JSON.parse(localStorage.getItem(KEYS[name]) || "[]");
  } catch {
    return [];
  }
}

function store(name, rows) {
  localStorage.setItem(KEYS[name], JSON.stringify(rows));
}

const loadMap = (name) => {
  try {
    return JSON.parse(localStorage.getItem(KEYS[name]) || "{}");
  } catch {
    return {};
  }
};

const nowIso = () => new Date().toISOString();
const today = () => nowIso().slice(0, 10);
const uuid = () => crypto.randomUUID();

// ---------- photos ----------
// Photo paths look like "local:<id>". fileUrl() resolves them through this map,
// which is filled before any response that mentions a photo is returned.
const objectUrls = new Map();
export const LOCAL_PREFIX = "local:";

export const localFileUrl = (path) => objectUrls.get(path.slice(LOCAL_PREFIX.length)) || null;

async function resolvePhoto(path) {
  if (!path || !path.startsWith(LOCAL_PREFIX)) return;
  const id = path.slice(LOCAL_PREFIX.length);
  if (objectUrls.has(id)) return;
  const blob = await readLocalPhoto(id).catch(() => null);
  if (blob) objectUrls.set(id, URL.createObjectURL(blob));
}

async function withPhotos(rows, field) {
  await Promise.all(rows.map((r) => resolvePhoto(r[field])));
  return rows;
}

// ---------- catalog logic (ported from server.py) ----------
const hmid = (m) => (m.hardness[0] + m.hardness[1]) / 2;
const fmtH = (m) => (m.hardness[0] === m.hardness[1] ? `${m.hardness[0]}` : `${m.hardness[0]}–${m.hardness[1]}`);

function separatingTests(a, b) {
  const tests = [];
  if (Math.abs(hmid(a) - hmid(b)) >= 1)
    tests.push({ test: "Mohs hardness", a: fmtH(a), b: fmtH(b), how: "Scratch against glass (5.5), a steel nail (6.5) or quartz (7)." });
  if (a.streak !== b.streak)
    tests.push({ test: "Streak", a: a.streak, b: b.streak, how: "Drag across unglazed porcelain and read the powder colour." });
  if (Math.abs(a.specific_gravity - b.specific_gravity) >= 0.4)
    tests.push({ test: "Specific gravity (heft)", a: `${a.specific_gravity}`, b: `${b.specific_gravity}`, how: "Compare weight against a same-size quartz pebble, or weigh in water." });
  if (a.cleavage !== b.cleavage)
    tests.push({ test: "Cleavage / fracture", a: a.cleavage, b: b.cleavage, how: "Inspect broken edges under a 10× loupe for flat planes." });
  if (a.luster !== b.luster)
    tests.push({ test: "Lustre", a: a.luster, b: b.luster, how: "Tilt under a single light source and judge the reflection." });
  if (a.category === "Carbonate" || b.category === "Carbonate")
    tests.push({
      test: "Acid reaction",
      a: a.category === "Carbonate" ? "fizzes" : "no fizz",
      b: b.category === "Carbonate" ? "fizzes" : "no fizz",
      how: "One drop of dilute HCl or vinegar on a fresh surface.",
    });
  return tests.slice(0, 4);
}

function bandFor(conf) {
  if (conf >= 0.85) return "High";
  if (conf >= 0.6) return "Medium";
  if (conf >= 0.35) return "Low";
  return "Inconclusive";
}

function shortlistCandidates(shortlist) {
  const topScore = shortlist[0]?.score || 1;
  return shortlist
    .filter((s) => MINERAL_INDEX[s.id])
    .slice(0, 5)
    .map((s) => ({ id: s.id, confidence: (0.45 * s.score) / topScore, why: "Colour match against catalog palette" }));
}

// ---------- errors ----------
function fail(config, status, detail) {
  const response = { status, statusText: detail, data: { detail }, headers: {}, config };
  throw new AxiosError(detail, String(status), config, null, response);
}

const scansToday = () => load("analyses").filter((a) => a.day === today()).length;

// ---------- routes ----------
async function saveAnalysis(config, { engine, model, summary, candidates: rawIn, colorShortlist, shortlist, file }) {
  if (scansToday() >= SCAN_LIMIT) fail(config, 429, `Daily limit reached: ${SCAN_LIMIT} scans per day`);
  const cap = engine === "on_device" ? 0.7 : CONFIDENCE_CAP;
  let raw = (rawIn || []).filter((c) => MINERAL_INDEX[c.id]).slice(0, 5);
  if (engine === "shortlist" && !raw.length) raw = shortlistCandidates(shortlist);
  const candidates = raw.map((c, i) => {
    const conf = Math.min(Math.max(Number(c.confidence) || 0, 0), 1);
    return {
      rank: i + 1,
      mineral_id: c.id,
      name: MINERAL_INDEX[c.id].name,
      confidence_raw: Math.round(conf * 1000) / 1000,
      confidence: Math.round(Math.min(conf, cap) * 1000) / 1000,
      why: c.why || "",
    };
  });
  const top = candidates[0] || null;
  const tests = [];
  if (candidates.length >= 2) {
    const a = MINERAL_INDEX[candidates[0].mineral_id];
    for (const c of candidates.slice(1, 3)) {
      const b = MINERAL_INDEX[c.mineral_id];
      tests.push({ a: a.id, a_name: a.name, b: b.id, b_name: b.name, tests: separatingTests(a, b) });
    }
  }
  const id = uuid();
  let photoPath = null;
  if (file) {
    await saveLocalPhoto(id, file);
    photoPath = `${LOCAL_PREFIX}${id}`;
  }
  const doc = {
    id,
    day: today(),
    created_at: nowIso(),
    photo_path: photoPath,
    photo_id: file ? id : null,
    photo_label: top?.name || null,
    photo_confidence: top?.confidence ?? null,
    photo_size: file?.size || 0,
    source: "web",
    engine,
    model: model || null,
    photo_left_device: engine === "cloud_vision",
    bytes_sent: engine === "cloud_vision" ? file?.size || 0 : 0,
    confidence_cap: cap,
    top,
    capped: Boolean(top && top.confidence_raw > cap),
    band: top ? bandFor(top.confidence) : "Inconclusive",
    candidates,
    color_shortlist: colorShortlist || [],
    shortlist: (shortlist || []).map(({ id: sid, score }) => ({ id: sid, score })),
    separating_tests: tests,
    summary: summary || "",
    observed: {},
    bench_runs: [],
  };
  store("analyses", [doc, ...load("analyses")].slice(0, 200));
  await resolvePhoto(photoPath);
  return doc;
}

function attachRuns(records) {
  const runs = Object.fromEntries(load("analyses").map((a) => [a.id, a.bench_runs || []]));
  return records.map((r) => ({ ...r, bench_runs: [...(runs[r.analysis_id] || [])].reverse() }));
}

const cleanTags = (tags = []) => [...new Set(tags.map((t) => t.trim().toLowerCase().slice(0, 24)).filter(Boolean))];

let geoQueue = Promise.resolve();
async function geocode(location) {
  const q = (location || "").trim().toLowerCase();
  const empty = { lat: null, lng: null, geo_label: null, geo_q: location };
  if (!q) return empty;
  const cache = loadMap("geocache");
  if (!(q in cache)) {
    // Nominatim policy: at most one request per second.
    const job = geoQueue.then(async () => {
      const url = `https://nominatim.openstreetmap.org/search?format=json&limit=5&q=${encodeURIComponent(q)}`;
      const hits = (await fetch(url).then((r) => (r.ok ? r.json() : []))).filter((h) =>
        ["place", "boundary", "natural", "landuse"].includes(h.class),
      );
      await new Promise((r) => setTimeout(r, 1000));
      return hits[0] ? { lat: Number(hits[0].lat), lng: Number(hits[0].lon), label: hits[0].display_name || q } : null;
    });
    geoQueue = job.catch(() => null);
    try {
      cache[q] = await job;
    } catch {
      return { ...empty, geo_q: null };
    }
    localStorage.setItem(KEYS.geocache, JSON.stringify({ ...loadMap("geocache"), [q]: cache[q] }));
  }
  const hit = cache[q];
  return hit ? { lat: hit.lat, lng: hit.lng, geo_label: hit.label, geo_q: location } : empty;
}

const parseBody = (data) => (typeof data === "string" ? JSON.parse(data || "{}") : data || {});

async function route(config) {
  const method = (config.method || "get").toLowerCase();
  const [path] = (config.url || "/").split("?");
  const parts = path.replace(/^\/+|\/+$/g, "").split("/");
  const [head, id, sub] = parts;

  if (method === "get" && head === "minerals" && !id) return MINERALS;
  if (method === "get" && head === "minerals") {
    const m = MINERAL_INDEX[id];
    if (!m) fail(config, 404, "Mineral not found");
    return { ...m, lookalike_details: m.lookalikes.filter((x) => MINERAL_INDEX[x]).map((x) => ({ mineral: MINERAL_INDEX[x], tests: separatingTests(m, MINERAL_INDEX[x]) })) };
  }
  if (method === "get" && head === "usage") {
    return { scans_today: scansToday(), scan_limit: SCAN_LIMIT, saved: load("records").length, save_limit: SAVE_LIMIT };
  }

  if (method === "post" && head === "identify") {
    const file = config.data.get("file");
    const colors = await measureColors(file);
    const shortlist = shortlistMinerals(colors, MINERALS);
    return saveAnalysis(config, {
      engine: "shortlist",
      summary: "Ranked by measured colour only. Run the separating tests to confirm.",
      colorShortlist: colors,
      shortlist,
      file,
    });
  }
  if (method === "post" && head === "analyses" && !id) {
    let body;
    try {
      body = JSON.parse(config.data.get("result"));
    } catch {
      fail(config, 400, "Invalid hybrid result");
    }
    // Everything stays in this browser, so keep the photo for every route.
    const file = config.data.get("file") || null;
    return saveAnalysis(config, {
      engine: body.engine,
      model: body.model,
      summary: body.summary,
      candidates: body.candidates,
      colorShortlist: body.color_shortlist,
      shortlist: body.shortlist,
      file,
    });
  }
  if (method === "get" && head === "analyses" && !id) {
    const limit = Number(config.params?.limit || new URLSearchParams(config.url.split("?")[1]).get("limit") || 20);
    return withPhotos(load("analyses").slice(0, limit), "photo_path");
  }
  if (method === "get" && head === "analyses") {
    const doc = load("analyses").find((a) => a.id === id);
    if (!doc) fail(config, 404, "Analysis not found");
    return (await withPhotos([doc], "photo_path"))[0];
  }
  if (method === "post" && head === "analyses" && sub === "bench-runs") {
    const rows = load("analyses");
    const doc = rows.find((a) => a.id === id);
    if (!doc) fail(config, 404, "Analysis not found");
    const run = { ...parseBody(config.data), id: uuid(), created_at: nowIso() };
    doc.bench_runs = [...(doc.bench_runs || []), run].slice(-20);
    store("analyses", rows);
    return run;
  }

  if (method === "get" && head === "photos") {
    const photos = load("analyses")
      .filter((a) => a.photo_path)
      .map((a) => ({
        id: a.photo_id,
        storage_path: a.photo_path,
        source: "web",
        analysis_id: a.id,
        label: a.photo_label,
        confidence: a.photo_confidence,
        size: a.photo_size,
        created_at: a.created_at,
      }));
    return withPhotos(photos, "storage_path");
  }
  if (method === "delete" && head === "photos") {
    const rows = load("analyses");
    const doc = rows.find((a) => a.photo_id === id);
    if (!doc) fail(config, 404, "Photo not found");
    doc.photo_path = null;
    store("analyses", rows);
    return { ok: true };
  }

  if (method === "get" && head === "records") return withPhotos(attachRuns(load("records")), "photo_path");
  if (method === "post" && head === "records" && id === "geocode") {
    const rows = load("records");
    let updated = 0;
    for (const r of rows) {
      if (!r.location || r.lat != null || r.geo_q === r.location) continue;
      Object.assign(r, await geocode(r.location));
      updated += r.lat != null ? 1 : 0;
    }
    store("records", rows);
    return { updated };
  }
  if (method === "post" && head === "records") {
    const rows = load("records");
    if (rows.length >= SAVE_LIMIT) fail(config, 429, `Limit reached: ${SAVE_LIMIT} saved specimens`);
    const body = parseBody(config.data);
    if (body.mineral_id && !MINERAL_INDEX[body.mineral_id]) fail(config, 400, "Unknown mineral");
    const doc = {
      notes: "",
      weight: null,
      weight_unit: "g",
      location: "",
      form: "Raw",
      favorite: false,
      confirmed: "unconfirmed",
      analysis_id: null,
      photo_path: null,
      ...body,
      tags: cleanTags(body.tags),
      id: uuid(),
      source: "web",
      created_at: nowIso(),
      updated_at: nowIso(),
      ...(await geocode(body.location)),
    };
    store("records", [doc, ...rows]);
    return (await withPhotos(attachRuns([doc]), "photo_path"))[0];
  }
  if (method === "patch" && head === "records") {
    const rows = load("records");
    const doc = rows.find((r) => r.id === id);
    if (!doc) fail(config, 404, "Record not found");
    const body = parseBody(config.data);
    const changes = Object.fromEntries(Object.entries(body).filter(([k, v]) => v !== null || ["weight", "mineral_id"].includes(k)));
    if (changes.tags) changes.tags = cleanTags(changes.tags);
    if (changes.mineral_id && !MINERAL_INDEX[changes.mineral_id]) fail(config, 400, "Unknown mineral");
    if (("lat" in changes) !== ("lng" in changes)) fail(config, 400, "lat and lng must be sent together");
    if ("lat" in changes) Object.assign(changes, { geo_label: "Pinned by hand", geo_manual: true, geo_q: changes.location });
    else if ("location" in changes) {
      const geo = await geocode(changes.location);
      if (geo.lat != null || !doc.geo_manual) Object.assign(changes, geo, { geo_manual: false });
    }
    Object.assign(doc, changes, { updated_at: nowIso() });
    store("records", rows);
    return (await withPhotos(attachRuns([doc]), "photo_path"))[0];
  }
  if (method === "delete" && head === "records") {
    const rows = load("records");
    if (!rows.some((r) => r.id === id)) fail(config, 404, "Record not found");
    store("records", rows.filter((r) => r.id !== id));
    return { ok: true };
  }

  if (method === "get" && head === "specimens") fail(config, 404, "Shared specimen links need the hosted backend");
  if (method === "get" && !head) return { service: "field-bench", ok: true, local: true };
  return fail(config, 404, "Not found");
}

export async function localAdapter(config) {
  const data = await route(config);
  return { data, status: 200, statusText: "OK", headers: {}, config, request: null };
}
