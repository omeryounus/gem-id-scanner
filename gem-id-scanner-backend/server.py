import asyncio
import base64
import io
import json
import logging
import os
import re
import secrets
import uuid
from contextlib import suppress
from datetime import datetime, timezone
from pathlib import Path
from typing import List, Literal, Optional

import requests
from dotenv import load_dotenv
from fastapi import APIRouter, Depends, FastAPI, File, Form, Header, HTTPException, Query, UploadFile
from fastapi.responses import Response
from motor.motor_asyncio import AsyncIOMotorClient
from PIL import Image
from pydantic import BaseModel, Field
from pymongo import ASCENDING, DESCENDING, IndexModel
from starlette.middleware.cors import CORSMiddleware

from minerals_data import MINERAL_INDEX, MINERALS, PALETTE

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

client = AsyncIOMotorClient(os.environ['MONGO_URL'])
db = client[os.environ['DB_NAME']]
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')

SCAN_LIMIT = 5
SAVE_LIMIT = 20
CONFIDENCE_CAP = 0.96
GEMINI_MODEL = "gemini-3-flash-preview"
APP_NAME = "field-bench"

INDEXES: dict[str, list[IndexModel]] = {
    "analyses": [
        IndexModel([("id", ASCENDING)], name="id", unique=True),
        IndexModel([("session_id", ASCENDING), ("created_at", DESCENDING)], name="session_created"),
        IndexModel([("session_id", ASCENDING), ("day", ASCENDING)], name="session_day"),
    ],
    "photos": [
        IndexModel([("id", ASCENDING)], name="id", unique=True),
        IndexModel([("session_id", ASCENDING), ("created_at", DESCENDING)], name="session_created"),
        IndexModel([("storage_path", ASCENDING)], name="storage_path"),
    ],
    "records": [
        IndexModel([("id", ASCENDING)], name="id", unique=True),
        IndexModel([("session_id", ASCENDING), ("created_at", DESCENDING)], name="session_created"),
        IndexModel([("share_token", ASCENDING)], name="share_token", unique=True, sparse=True),
    ],
    "geocache": [
        IndexModel([("q", ASCENDING)], name="q", unique=True),
    ],
}


async def ensure_indexes() -> None:
    for collection, models in INDEXES.items():
        for model in models:
            try:
                await db[collection].create_indexes([model])
            except Exception as exc:
                logger.error("ensure_indexes(%s.%s): %s", collection, model.document["name"], exc)


# ---------- Object storage ----------
STORAGE_BASE = (os.environ.get("INTEGRATION_PROXY_URL") or "").strip() or "https://integrations.emergentagent.com"
STORAGE_URL = STORAGE_BASE.rstrip("/") + "/objstore/api/v1/storage"
LOCAL_UPLOADS = ROOT_DIR / "uploads"
_storage_key: Optional[str] = None


def storage_is_local() -> bool:
    return not (os.environ.get("EMERGENT_LLM_KEY") or "").strip()


def local_file(path: str) -> Path:
    root = LOCAL_UPLOADS.resolve()
    dest = (root / path).resolve()
    if dest != root and root not in dest.parents:
        raise ValueError("invalid storage path")
    return dest


def init_storage(force: bool = False) -> str:
    global _storage_key
    if storage_is_local():
        LOCAL_UPLOADS.mkdir(parents=True, exist_ok=True)
        _storage_key = "local"
        return _storage_key
    if _storage_key and not force:
        return _storage_key
    resp = requests.post(f"{STORAGE_URL}/init", json={"emergent_key": os.environ.get("EMERGENT_LLM_KEY")}, timeout=30)
    resp.raise_for_status()
    _storage_key = resp.json()["storage_key"]
    return _storage_key


def put_object(path: str, data: bytes, content_type: str) -> dict:
    if storage_is_local():
        dest = local_file(path)
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
        return {"path": path}
    resp = requests.put(f"{STORAGE_URL}/objects/{path}", headers={"X-Storage-Key": init_storage(), "Content-Type": content_type}, data=data, timeout=120)
    if resp.status_code == 404:
        resp = requests.put(f"{STORAGE_URL}/objects/{path}", headers={"X-Storage-Key": init_storage(True), "Content-Type": content_type}, data=data, timeout=120)
    resp.raise_for_status()
    return resp.json()


def get_object(path: str) -> tuple[bytes, str]:
    if storage_is_local():
        return local_file(path).read_bytes(), "application/octet-stream"
    resp = requests.get(f"{STORAGE_URL}/objects/{path}", headers={"X-Storage-Key": init_storage()}, timeout=60)
    resp.raise_for_status()
    return resp.content, resp.headers.get("Content-Type", "application/octet-stream")


# ---------- Helpers ----------
def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def today() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d")


UUID_RE = re.compile(r"^[0-9a-fA-F-]{32,36}$")


async def session_id(x_session_id: str = Header(...)) -> str:
    if not UUID_RE.match(x_session_id):
        raise HTTPException(400, "Invalid session id")
    return x_session_id


def hmid(m):
    return sum(m["hardness"]) / 2


def fmt_h(m):
    a, b = m["hardness"]
    return f"{a:g}" if a == b else f"{a:g}–{b:g}"


def separating_tests(a: dict, b: dict) -> list[dict]:
    tests = []
    if abs(hmid(a) - hmid(b)) >= 1:
        tests.append({"test": "Mohs hardness", "a": fmt_h(a), "b": fmt_h(b),
                      "how": "Scratch against glass (5.5), a steel nail (6.5) or quartz (7)."})
    if a["streak"] != b["streak"]:
        tests.append({"test": "Streak", "a": a["streak"], "b": b["streak"],
                      "how": "Drag across unglazed porcelain and read the powder colour."})
    if abs(a["specific_gravity"] - b["specific_gravity"]) >= 0.4:
        tests.append({"test": "Specific gravity (heft)", "a": f"{a['specific_gravity']:g}", "b": f"{b['specific_gravity']:g}",
                      "how": "Compare weight against a same-size quartz pebble, or weigh in water."})
    if a["cleavage"] != b["cleavage"]:
        tests.append({"test": "Cleavage / fracture", "a": a["cleavage"], "b": b["cleavage"],
                      "how": "Inspect broken edges under a 10× loupe for flat planes."})
    if a["luster"] != b["luster"]:
        tests.append({"test": "Lustre", "a": a["luster"], "b": b["luster"],
                      "how": "Tilt under a single light source and judge the reflection."})
    if a["category"] == "Carbonate" or b["category"] == "Carbonate":
        tests.append({"test": "Acid reaction", "a": "fizzes" if a["category"] == "Carbonate" else "no fizz",
                      "b": "fizzes" if b["category"] == "Carbonate" else "no fizz",
                      "how": "One drop of dilute HCl or vinegar on a fresh surface."})
    return tests[:4]


def band_for(conf: float) -> str:
    if conf >= 0.85:
        return "High"
    if conf >= 0.6:
        return "Medium"
    if conf >= 0.35:
        return "Low"
    return "Inconclusive"


def color_shortlist(img: Image.Image) -> list[dict]:
    small = img.convert("RGB").resize((48, 48))
    w, h = small.size
    small = small.crop((w // 6, h // 6, w - w // 6, h - h // 6))
    counts: dict[str, int] = {}
    pixels = list(small.getdata())
    for r, g, b in pixels:
        mx, mn = max(r, g, b), min(r, g, b)
        if mx - mn < 22:
            name = "white" if mx > 215 else "black" if mx < 45 else "gray"
        else:
            name = min((k for k in PALETTE if k not in ("white", "black", "gray", "colorless", "metallic")),
                       key=lambda k: sum((x - y) ** 2 for x, y in zip(PALETTE[k], (r, g, b))))
        counts[name] = counts.get(name, 0) + 1
    total = len(pixels)
    ranked = sorted(counts.items(), key=lambda kv: -kv[1])[:4]
    return [{"color": c, "hex": "#%02x%02x%02x" % PALETTE[c], "share": round(n / total, 3)} for c, n in ranked if n / total >= 0.05]


def shortlist_minerals(colors: list[dict]) -> list[dict]:
    scored = []
    for m in MINERALS:
        s = sum(c["share"] for c in colors if c["color"] in m["colors"])
        if s > 0:
            scored.append((s / len(m["colors"]) ** 0.3, m))
    scored.sort(key=lambda x: -x[0])
    return [{"id": m["id"], "score": round(s, 3)} for s, m in scored[:8]]


SYSTEM_PROMPT = (
    "You are a field mineralogist. Identify the specimen in the photo using ONLY these catalog ids: "
    + ", ".join(f"{m['id']} ({m['name']})" for m in MINERALS)
    + ". Reply with strict JSON only, no prose, shaped as "
    '{"candidates":[{"id":"catalog id","confidence":0.0-1.0,"why":"one short sentence"}],'
    '"observed":{"colors":["..."],"luster":"...","habit":"..."},"summary":"two sentences max"}. '
    "Give 3-5 candidates ranked best first. Be conservative: photos cannot confirm hardness or streak. "
    "If the photo is not a mineral, return low confidences."
)


async def gemini_identify(image_b64: str, colors: list[dict], aid: str) -> dict:
    from emergentintegrations.llm.chat import ImageContent, LlmChat, UserMessage
    chat = LlmChat(api_key=os.environ["GEMINI_API_KEY"], session_id=f"scan-{aid}", system_message=SYSTEM_PROMPT).with_model("gemini", GEMINI_MODEL)
    hint = ", ".join(f"{c['color']} {int(c['share'] * 100)}%" for c in colors)
    text = await chat.send_message(UserMessage(text=f"Identify this specimen. Measured colour shortlist: {hint}.", file_contents=[ImageContent(image_base64=image_b64)]))
    match = re.search(r"\{.*\}", text, re.S)
    return json.loads(match.group(0))


# ---------- Models ----------
class RecordIn(BaseModel):
    mineral_id: Optional[str] = None
    name: str = Field(min_length=1, max_length=120)
    notes: str = Field("", max_length=4000)
    weight: Optional[float] = Field(None, ge=0)
    weight_unit: Literal["g", "ct"] = "g"
    location: str = Field("", max_length=200)
    form: str = Field("Raw", max_length=40)
    favorite: bool = False
    confirmed: Literal["unconfirmed", "confirmed", "disputed"] = "unconfirmed"
    tags: List[str] = Field(default_factory=list, max_length=20)
    analysis_id: Optional[str] = None
    photo_path: Optional[str] = None


class RecordPatch(BaseModel):
    name: Optional[str] = Field(None, min_length=1, max_length=120)
    mineral_id: Optional[str] = None
    notes: Optional[str] = Field(None, max_length=4000)
    weight: Optional[float] = Field(None, ge=0)
    weight_unit: Optional[Literal["g", "ct"]] = None
    location: Optional[str] = Field(None, max_length=200)
    form: Optional[str] = Field(None, max_length=40)
    favorite: Optional[bool] = None
    confirmed: Optional[Literal["unconfirmed", "confirmed", "disputed"]] = None
    tags: Optional[List[str]] = Field(None, max_length=20)
    lat: Optional[float] = Field(None, ge=-90, le=90)
    lng: Optional[float] = Field(None, ge=-180, le=180)


class BenchStep(BaseModel):
    test: str = Field(max_length=60)
    a_name: str = Field(max_length=80)
    b_name: str = Field(max_length=80)
    answer: Literal["a", "b", "unsure", "none"]


class BenchRunIn(BaseModel):
    status: Literal["unconfirmed", "confirmed", "disputed"]
    winner: Optional[str] = None
    text: str = Field(max_length=300)
    steps: List[BenchStep] = Field(max_length=40)


class HybridCandidate(BaseModel):
    id: str = Field(max_length=80)
    confidence: float = 0
    why: str = Field("", max_length=300)


class ColorBit(BaseModel):
    color: str = Field(max_length=24)
    hex: str = Field("", max_length=16)
    share: float = 0


class ShortBit(BaseModel):
    id: str = Field(max_length=80)
    score: float = 0


class HybridIn(BaseModel):
    """A rank already produced in the browser by Firebase AI Logic."""
    engine: Literal["on_device", "cloud_text", "cloud_vision", "shortlist"]
    model: str = Field("", max_length=120)
    summary: str = Field("", max_length=800)
    candidates: List[HybridCandidate] = Field(default_factory=list, max_length=5)
    color_shortlist: List[ColorBit] = Field(default_factory=list, max_length=6)
    shortlist: List[ShortBit] = Field(default_factory=list, max_length=8)


# ---------- App ----------
app = FastAPI()
api = APIRouter(prefix="/api")


@api.get("/")
async def root():
    return {"service": "field-bench", "ok": True}


@api.get("/minerals")
async def list_minerals():
    return MINERALS


@api.get("/minerals/{mid}")
async def get_mineral(mid: str):
    m = MINERAL_INDEX.get(mid)
    if not m:
        raise HTTPException(404, "Mineral not found")
    looks = [{"mineral": MINERAL_INDEX[x], "tests": separating_tests(m, MINERAL_INDEX[x])} for x in m["lookalikes"]]
    return {**m, "lookalike_details": looks}


@api.get("/usage")
async def usage(sid: str = Depends(session_id)):
    scans = await db.analyses.count_documents({"session_id": sid, "day": today()})
    saved = await db.records.count_documents({"session_id": sid})
    return {"scans_today": scans, "scan_limit": SCAN_LIMIT, "saved": saved, "save_limit": SAVE_LIMIT,
            "vision_ready": bool(os.environ.get("GEMINI_API_KEY"))}


MAX_UPLOAD = 12 * 1024 * 1024
ALLOWED = {"image/jpeg": "jpg", "image/png": "png", "image/webp": "webp"}


async def store_photo(sid: str, data: bytes, content_type: str, source: str, analysis_id=None, label=None, confidence=None) -> dict:
    path = f"{APP_NAME}/uploads/{sid}/{uuid.uuid4()}.{ALLOWED[content_type]}"
    result = await asyncio.to_thread(put_object, path, data, content_type)
    photo = {"id": str(uuid.uuid4()), "session_id": sid, "storage_path": result["path"], "content_type": content_type,
             "source": source, "analysis_id": analysis_id, "label": label, "confidence": confidence,
             "size": len(data), "is_deleted": False, "created_at": now_iso()}
    await db.photos.insert_one(dict(photo))
    return photo


async def read_image(file: UploadFile) -> bytes:
    if file.content_type not in ALLOWED:
        raise HTTPException(415, "Use a JPEG, PNG or WEBP photo")
    data = await file.read()
    if len(data) > MAX_UPLOAD:
        raise HTTPException(413, "Photo is larger than 12 MB")
    return data


@api.post("/identify")
async def identify(file: UploadFile = File(...), sid: str = Depends(session_id)):
    if await db.analyses.count_documents({"session_id": sid, "day": today()}) >= SCAN_LIMIT:
        raise HTTPException(429, f"Daily limit reached: {SCAN_LIMIT} scans per day")
    data = await read_image(file)
    try:
        img = Image.open(io.BytesIO(data))
        img.load()
    except Exception:
        raise HTTPException(400, "That file isn't a readable image")
    aid = str(uuid.uuid4())
    colors = color_shortlist(img)
    short = shortlist_minerals(colors)

    engine, model, summary, observed, raw = "shortlist", None, "", {}, []
    if os.environ.get("GEMINI_API_KEY"):
        try:
            out = await gemini_identify(base64.b64encode(data).decode(), colors, aid)
            raw = [c for c in out.get("candidates", []) if c.get("id") in MINERAL_INDEX]
            summary, observed = out.get("summary", ""), out.get("observed", {})
            if raw:
                engine, model = "cloud_vision", GEMINI_MODEL
        except Exception as exc:
            logger.error("gemini identify failed: %s", exc)
    if engine == "shortlist":
        top_score = short[0]["score"] if short else 1
        raw = [{"id": s["id"], "confidence": 0.45 * s["score"] / top_score, "why": "Colour match against catalog palette"} for s in short[:5]]
        summary = summary or "Vision engine unavailable — ranked by measured colour only. Run the separating tests to confirm."

    candidates = []
    for i, c in enumerate(raw[:5]):
        conf = float(c.get("confidence") or 0)
        candidates.append({"rank": i + 1, "mineral_id": c["id"], "name": MINERAL_INDEX[c["id"]]["name"],
                           "confidence_raw": round(conf, 3), "confidence": round(min(conf, CONFIDENCE_CAP), 3), "why": c.get("why", "")})
    top = candidates[0] if candidates else None
    tests = []
    if len(candidates) >= 2:
        a = MINERAL_INDEX[candidates[0]["mineral_id"]]
        for c in candidates[1:3]:
            b = MINERAL_INDEX[c["mineral_id"]]
            tests.append({"a": a["id"], "a_name": a["name"], "b": b["id"], "b_name": b["name"], "tests": separating_tests(a, b)})

    photo = await store_photo(sid, data, file.content_type, "web", aid, top["name"] if top else None, top["confidence"] if top else None)
    doc = {
        "id": aid, "session_id": sid, "day": today(), "created_at": now_iso(),
        "photo_path": photo["storage_path"], "photo_id": photo["id"], "source": "web",
        "engine": engine, "model": model, "photo_left_device": True, "bytes_sent": len(data),
        "confidence_cap": CONFIDENCE_CAP, "top": top,
        "capped": bool(top and top["confidence_raw"] > CONFIDENCE_CAP),
        "band": band_for(top["confidence"]) if top else "Inconclusive",
        "candidates": candidates, "color_shortlist": colors, "shortlist": short,
        "separating_tests": tests, "summary": summary, "observed": observed,
    }
    await db.analyses.insert_one(dict(doc))
    doc.pop("session_id")
    return doc


@api.post("/analyses")
async def record_hybrid_analysis(
    result: str = Form(...),
    file: Optional[UploadFile] = File(None),
    sid: str = Depends(session_id),
):
    """Store a scan whose model call already happened in the browser.

    The photo is stored only for cloud_vision. On-device and cloud-text ranks
    keep the JPEG in the browser, matching the iOS hybrid path.
    """
    if await db.analyses.count_documents({"session_id": sid, "day": today()}) >= SCAN_LIMIT:
        raise HTTPException(429, f"Daily limit reached: {SCAN_LIMIT} scans per day")
    try:
        body = HybridIn.model_validate_json(result)
    except Exception:
        raise HTTPException(400, "Invalid hybrid result")

    cap = 0.70 if body.engine == "on_device" else CONFIDENCE_CAP
    raw = [c for c in body.candidates if c.id in MINERAL_INDEX][:5]
    if body.engine == "shortlist" and not raw:
        top_score = body.shortlist[0].score if body.shortlist else 1
        raw = [
            HybridCandidate(id=s.id, confidence=0.45 * s.score / (top_score or 1), why="Colour match against catalog palette")
            for s in body.shortlist[:5]
            if s.id in MINERAL_INDEX
        ]
    candidates = []
    for i, c in enumerate(raw):
        conf = min(max(float(c.confidence or 0), 0), 1)
        candidates.append({
            "rank": i + 1,
            "mineral_id": c.id,
            "name": MINERAL_INDEX[c.id]["name"],
            "confidence_raw": round(conf, 3),
            "confidence": round(min(conf, cap), 3),
            "why": c.why,
        })
    top = candidates[0] if candidates else None
    tests = []
    if len(candidates) >= 2:
        a = MINERAL_INDEX[candidates[0]["mineral_id"]]
        for c in candidates[1:3]:
            b = MINERAL_INDEX[c["mineral_id"]]
            tests.append({"a": a["id"], "a_name": a["name"], "b": b["id"], "b_name": b["name"], "tests": separating_tests(a, b)})

    photo_left = body.engine == "cloud_vision"
    aid = str(uuid.uuid4())
    photo_path, photo_id, bytes_sent = None, None, 0
    if photo_left and file is not None:
        data = await read_image(file)
        photo = await store_photo(sid, data, file.content_type, "web", aid, top["name"] if top else None, top["confidence"] if top else None)
        photo_path, photo_id, bytes_sent = photo["storage_path"], photo["id"], len(data)

    doc = {
        "id": aid, "session_id": sid, "day": today(), "created_at": now_iso(),
        "photo_path": photo_path, "photo_id": photo_id, "source": "web",
        "engine": body.engine, "model": body.model or None, "photo_left_device": photo_left, "bytes_sent": bytes_sent,
        "confidence_cap": cap, "top": top,
        "capped": bool(top and top["confidence_raw"] > cap),
        "band": band_for(top["confidence"]) if top else "Inconclusive",
        "candidates": candidates,
        "color_shortlist": [c.model_dump() for c in body.color_shortlist],
        "shortlist": [s.model_dump() for s in body.shortlist],
        "separating_tests": tests,
        "summary": body.summary,
        "observed": {},
    }
    await db.analyses.insert_one(dict(doc))
    doc.pop("session_id")
    return doc


@api.get("/analyses")
async def list_analyses(limit: int = Query(20, ge=1, le=100), sid: str = Depends(session_id)):
    return await db.analyses.find({"session_id": sid}, {"_id": 0, "session_id": 0}).sort("created_at", -1).to_list(limit)


@api.get("/analyses/{aid}")
async def get_analysis(aid: str, sid: str = Depends(session_id)):
    doc = await db.analyses.find_one({"id": aid, "session_id": sid}, {"_id": 0, "session_id": 0})
    if not doc:
        raise HTTPException(404, "Analysis not found")
    return doc


@api.post("/analyses/{aid}/bench-runs")
async def add_bench_run(aid: str, body: BenchRunIn, sid: str = Depends(session_id)):
    run = {**body.model_dump(), "id": str(uuid.uuid4()), "created_at": now_iso()}
    res = await db.analyses.update_one({"id": aid, "session_id": sid}, {"$push": {"bench_runs": {"$each": [run], "$slice": -20}}})
    if not res.matched_count:
        raise HTTPException(404, "Analysis not found")
    return run


async def attach_runs(records: list[dict], session: Optional[str] = None) -> list[dict]:
    ids = list({r["analysis_id"] for r in records if r.get("analysis_id")})
    q = {"id": {"$in": ids}} if session is None else {"id": {"$in": ids}, "session_id": session}
    runs = {a["id"]: a.get("bench_runs", []) async for a in db.analyses.find(q, {"_id": 0, "id": 1, "bench_runs": 1})}
    for r in records:
        r["bench_runs"] = list(reversed(runs.get(r.get("analysis_id"), [])))
    return records


@api.get("/photos")
async def list_photos(source: Optional[Literal["iphone", "android", "web"]] = None, sid: str = Depends(session_id)):
    q = {"session_id": sid, "is_deleted": False}
    if source:
        q["source"] = source
    return await db.photos.find(q, {"_id": 0, "session_id": 0}).sort("created_at", -1).to_list(500)


@api.post("/photos")
async def ingest_photo(file: UploadFile = File(...), source: Literal["iphone", "android", "web"] = Form("web"),
                       label: Optional[str] = Form(None), sid: str = Depends(session_id)):
    data = await read_image(file)
    if await db.photos.count_documents({"session_id": sid, "is_deleted": False}) >= 200:
        raise HTTPException(429, "Gallery limit reached: 200 photos")
    photo = await store_photo(sid, data, file.content_type, source, label=label)
    photo.pop("session_id")
    return photo


@api.delete("/photos/{pid}")
async def delete_photo(pid: str, sid: str = Depends(session_id)):
    res = await db.photos.update_one({"id": pid, "session_id": sid}, {"$set": {"is_deleted": True}})
    if not res.matched_count:
        raise HTTPException(404, "Photo not found")
    return {"ok": True}


@api.get("/files/{path:path}")
async def get_file(path: str, sid: str = Query(...)):
    rec = await db.photos.find_one({"storage_path": path, "session_id": sid, "is_deleted": False})
    if not rec:
        raise HTTPException(404, "File not found")
    data, ctype = await asyncio.to_thread(get_object, path)
    return Response(content=data, media_type=rec.get("content_type", ctype), headers={"Cache-Control": "private, max-age=86400"})


@api.get("/records")
async def list_records(sid: str = Depends(session_id)):
    records = await db.records.find({"session_id": sid}, {"_id": 0, "session_id": 0}).sort("created_at", -1).to_list(SAVE_LIMIT)
    for r in records:
        if not r.get("share_token"):
            r["share_token"] = secrets.token_urlsafe(9)
            await db.records.update_one({"id": r["id"], "session_id": sid}, {"$set": {"share_token": r["share_token"]}})
    return await attach_runs(records, sid)


PUBLIC_FIELDS = ("id", "name", "mineral_id", "weight", "weight_unit", "form", "location", "confirmed", "tags", "created_at", "analysis_id", "photo_path")


@api.get("/specimens/{token}")
async def public_specimen(token: str):
    doc = await db.records.find_one({"share_token": token}, {"_id": 0})
    if not doc:
        raise HTTPException(404, "Specimen not found")
    out = {k: doc.get(k) for k in PUBLIC_FIELDS}
    out["has_photo"] = bool(doc.get("photo_path"))
    out.pop("photo_path")
    return (await attach_runs([out]))[0]


@api.get("/specimens/{token}/photo")
async def public_specimen_photo(token: str):
    doc = await db.records.find_one({"share_token": token}, {"_id": 0, "photo_path": 1})
    if not doc or not doc.get("photo_path"):
        raise HTTPException(404, "Photo not found")
    data, ctype = await asyncio.to_thread(get_object, doc["photo_path"])
    return Response(content=data, media_type=ctype, headers={"Cache-Control": "public, max-age=86400"})


def clean_tags(tags):
    return list(dict.fromkeys(t.strip().lower()[:24] for t in tags if t.strip()))


_geo_lock = asyncio.Lock()


def _nominatim(q: str):
    resp = requests.get("https://nominatim.openstreetmap.org/search", params={"q": q, "format": "json", "limit": 5},
                        headers={"User-Agent": "FieldBench/1.0 (mineral collection companion)"}, timeout=10)
    resp.raise_for_status()
    hits = [h for h in resp.json() if h.get("class") in ("place", "boundary", "natural", "landuse")]
    return {"lat": float(hits[0]["lat"]), "lng": float(hits[0]["lon"]), "label": hits[0].get("display_name", q)} if hits else None


async def geocode(location: str) -> dict:
    q = (location or "").strip().lower()
    empty = {"lat": None, "lng": None, "geo_label": None, "geo_q": location}
    if not q:
        return empty
    cached = await db.geocache.find_one({"q": q}, {"_id": 0})
    if cached is None:
        async with _geo_lock:  # Nominatim policy: max 1 request per second
            try:
                hit = await asyncio.to_thread(_nominatim, q)
            except Exception as exc:
                logger.error("geocode failed: %s", exc)
                return {**empty, "geo_q": None}
            await asyncio.sleep(1)
        cached = {"q": q, "hit": hit}
        await db.geocache.update_one({"q": q}, {"$set": cached}, upsert=True)
    hit = cached["hit"]
    return {"lat": hit["lat"], "lng": hit["lng"], "geo_label": hit["label"], "geo_q": location} if hit else empty


@api.post("/records/geocode")
async def geocode_records(sid: str = Depends(session_id)):
    todo = await db.records.find({"session_id": sid, "location": {"$nin": ["", None]}, "lat": None,
                                  "$expr": {"$ne": [{"$ifNull": ["$geo_q", None]}, "$location"]}},
                                 {"_id": 0, "id": 1, "location": 1}).to_list(SAVE_LIMIT)
    updated = 0
    for r in todo:
        geo = await geocode(r["location"])
        await db.records.update_one({"id": r["id"], "session_id": sid}, {"$set": geo})
        updated += geo["lat"] is not None
    return {"updated": updated}


@api.post("/records")
async def create_record(body: RecordIn, sid: str = Depends(session_id)):
    if await db.records.count_documents({"session_id": sid}) >= SAVE_LIMIT:
        raise HTTPException(429, f"Limit reached: {SAVE_LIMIT} saved specimens")
    if body.mineral_id and body.mineral_id not in MINERAL_INDEX:
        raise HTTPException(400, "Unknown mineral")
    doc = {**body.model_dump(), "tags": clean_tags(body.tags), "id": str(uuid.uuid4()), "session_id": sid,
           "source": "web", "created_at": now_iso(), "updated_at": now_iso(), "share_token": secrets.token_urlsafe(9),
           **(await geocode(body.location))}
    await db.records.insert_one(dict(doc))
    doc.pop("session_id")
    return (await attach_runs([doc], sid))[0]


@api.patch("/records/{rid}")
async def update_record(rid: str, body: RecordPatch, sid: str = Depends(session_id)):
    changes = body.model_dump(exclude_unset=True)
    changes = {k: v for k, v in changes.items() if v is not None or k in ("weight", "mineral_id")}
    if "tags" in changes and changes["tags"] is not None:
        changes["tags"] = clean_tags(changes["tags"])
    if changes.get("mineral_id") and changes["mineral_id"] not in MINERAL_INDEX:
        raise HTTPException(400, "Unknown mineral")
    changes["updated_at"] = now_iso()
    if ("lat" in changes) != ("lng" in changes):
        raise HTTPException(400, "lat and lng must be sent together")
    if "lat" in changes:
        changes.update(geo_label="Pinned by hand", geo_manual=True, geo_q=changes.get("location"))
    elif "location" in changes:
        geo = await geocode(changes["location"])
        current = await db.records.find_one({"id": rid, "session_id": sid}, {"_id": 0, "geo_manual": 1})
        if geo["lat"] is not None or not (current or {}).get("geo_manual"):
            changes.update(geo, geo_manual=False)
    doc = await db.records.find_one_and_update({"id": rid, "session_id": sid}, {"$set": changes},
                                               projection={"_id": 0, "session_id": 0}, return_document=True)
    if not doc:
        raise HTTPException(404, "Record not found")
    return (await attach_runs([doc], sid))[0]


@api.delete("/records/{rid}")
async def delete_record(rid: str, sid: str = Depends(session_id)):
    res = await db.records.delete_one({"id": rid, "session_id": sid})
    if not res.deleted_count:
        raise HTTPException(404, "Record not found")
    return {"ok": True}


app.include_router(api)
app.add_middleware(CORSMiddleware, allow_credentials=True, allow_origins=os.environ.get('CORS_ORIGINS', '*').split(','),
                   allow_methods=["*"], allow_headers=["*"])


@app.on_event("startup")
async def startup():
    app.state.index_task = asyncio.create_task(ensure_indexes())
    try:
        await asyncio.to_thread(init_storage)
        logger.info("Storage initialized")
    except Exception as e:
        logger.error(f"Storage init failed: {e}")


@app.on_event("shutdown")
async def shutdown_db_client():
    app.state.index_task.cancel()
    with suppress(asyncio.CancelledError):
        await app.state.index_task
    client.close()
