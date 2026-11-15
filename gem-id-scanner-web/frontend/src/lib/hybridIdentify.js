import { InferenceMode, getGenerativeModel } from "firebase/ai";
import { firebaseAI, firebaseConfigured, hybridSettings } from "@/lib/firebaseApp";
import { measureColors, shortlistMinerals } from "@/lib/colorShortlist";

const JSON_SHAPE = '{"candidates":[{"id":"catalog id","confidence":0.0,"why":"one short sentence"}],"summary":"two sentences max"}';

const RANK_SCHEMA = {
  type: "object",
  properties: {
    candidates: {
      type: "array",
      items: {
        type: "object",
        properties: {
          id: { type: "string" },
          confidence: { type: "number" },
          why: { type: "string" },
        },
        required: ["id", "confidence", "why"],
      },
    },
    summary: { type: "string" },
  },
  required: ["candidates", "summary"],
};

let primed = null;

function cloudParams(modelName, instructions) {
  return {
    model: modelName,
    systemInstruction: instructions,
    generationConfig: { responseMimeType: "application/json" },
  };
}

function textModel(modelName, instructions) {
  return getGenerativeModel(firebaseAI(), {
    mode: InferenceMode.PREFER_ON_DEVICE,
    onDeviceParams: { promptOptions: { responseConstraint: RANK_SCHEMA } },
    inCloudParams: cloudParams(modelName, instructions),
  });
}

function visionModel(modelName, instructions) {
  return getGenerativeModel(firebaseAI(), {
    mode: InferenceMode.ONLY_IN_CLOUD,
    inCloudParams: cloudParams(modelName, instructions),
  });
}

/** Start the Gemini Nano download during the click that began the scan. */
export function primeDeviceModel() {
  if (!firebaseConfigured || primed) return;
  try {
    primed = textModel("gemini-3.5-flash-lite", "Rank minerals from a colour brief. Reply with one JSON object and no markdown.");
    primed.initializeDeviceModel(() => {});
  } catch {
    primed = null;
  }
}

function catalogList(minerals) {
  return minerals.map((mineral) => `${mineral.id} (${mineral.name})`).join(", ");
}

function notesFor(shortlist) {
  return shortlist
    .slice(0, 6)
    .map(({ mineral }) => {
      const twins = (mineral.lookalikes || []).slice(0, 2).join(", ") || "none listed";
      return `${mineral.id}: ${mineral.name}. Lookalikes: ${twins}. ${mineral.diagnostic || ""}`.trim();
    })
    .join("\n");
}

function onDeviceInstructions(minerals, shortlist, colors) {
  const measured = colors.map((color) => `${color.color} ${Math.round(color.share * 100)}%`).join(", ") || "unmeasured";
  const hint = shortlist.map((item) => `${item.id} ${item.score}`).join(", ") || "none";
  return `You are a field mineralogist. You cannot see a photograph. Rank the specimen using only this measured colour brief: ${measured}.
Stage 1 colour shortlist (hint only): ${hint}.
Choose ids only from this catalog: ${catalogList(minerals)}.
Catalog notes:
${notesFor(shortlist)}
Rules:
- Never invent an id that is not in the catalog.
- Do not claim crystal habit, lustre, fracture, or zoning. You were not shown the photo.
- Confidence must never exceed 0.70. A colour brief cannot prove the species.
- Reply with one JSON object and no markdown, shaped as ${JSON_SHAPE}. Give 3 candidates, best first.`;
}

function cloudInstructions(minerals, shortlist, colors) {
  const measured = colors.map((color) => `${color.color} ${Math.round(color.share * 100)}%`).join(", ") || "unmeasured";
  const hint = shortlist.map((item) => `${item.id} ${item.score}`).join(", ") || "none";
  return `You are a field mineralogist. Identify the specimen in the attached photograph.
Measured colour: ${measured}. Stage 1 colour shortlist (hint only): ${hint}.
Choose ids only from this catalog: ${catalogList(minerals)}.
Catalog notes:
${notesFor(shortlist)}
Rules:
- Never invent an id that is not in the catalog.
- Confidence must never exceed 0.96. A photograph cannot prove hardness or streak.
- Reply with one JSON object and no markdown, shaped as ${JSON_SHAPE}. Give 3 to 5 candidates, best first.`;
}

export function parseRank(text) {
  if (!text) return null;
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end <= start) return null;
  try {
    const parsed = JSON.parse(text.slice(start, end + 1));
    const candidates = Array.isArray(parsed.candidates) ? parsed.candidates : [];
    return { candidates, summary: typeof parsed.summary === "string" ? parsed.summary : "" };
  } catch {
    return null;
  }
}

function resolveMineral(raw, minerals) {
  const key = String(raw || "").trim().toLowerCase();
  if (!key) return null;
  return minerals.find((mineral) => mineral.id.toLowerCase() === key) || minerals.find((mineral) => mineral.name.toLowerCase() === key) || null;
}

function ranOnDevice(source) {
  return String(source || "").toUpperCase().includes("ON_DEVICE");
}

function toCandidates(parsed, minerals, cap) {
  const seen = new Set();
  const candidates = [];
  for (const candidate of parsed?.candidates || []) {
    const mineral = resolveMineral(candidate.id || candidate.mineral_id || candidate.name, minerals);
    if (!mineral || seen.has(mineral.id)) continue;
    seen.add(mineral.id);
    const confidence = Math.min(Math.max(Number(candidate.confidence) || 0, 0.05), cap);
    candidates.push({ id: mineral.id, confidence, why: String(candidate.why || "").slice(0, 300) });
    if (candidates.length === 5) break;
  }
  return candidates;
}

function fileToInlineData(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onloadend = () => resolve(String(reader.result).split(",")[1]);
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(file);
  });
}

async function generate(model, parts) {
  const result = await model.generateContent(parts);
  const response = result.response;
  return {
    text: response.text(),
    onDevice: ranOnDevice(response.inferenceSource),
  };
}

function shortlistDraft(colors, shortlist, summary) {
  const top = shortlist[0]?.score || 1;
  return {
    engine: "shortlist",
    model: "",
    summary: summary || "Firebase AI Logic did not return a catalog rank. This is the measured colour shortlist. Run the separating tests to confirm.",
    candidates: shortlist.slice(0, 5).map((item) => ({
      id: item.id,
      confidence: Math.round((0.45 * item.score / top) * 1000) / 1000,
      why: "Colour match against catalog palette",
    })),
    color_shortlist: colors,
    shortlist: shortlist.map(({ id, score }) => ({ id, score })),
  };
}

/**
 * Stage 2 through Firebase AI Logic, same decision as the iPhone.
 * Gemini Nano ranks the colour brief. The photo is sent to cloud Gemini
 * only when that on-device rank is missing or below the Remote Config threshold.
 */
export async function identifyHybrid(file, minerals) {
  const colors = await measureColors(file);
  const shortlist = shortlistMinerals(colors, minerals);
  if (!firebaseConfigured) return null;

  const settings = await hybridSettings();
  let textRank = null;
  let failure = "";
  try {
    const model = textModel(settings.modelName, onDeviceInstructions(minerals, shortlist, colors));
    model.initializeDeviceModel(() => {});
    const generated = await generate(model, `${onDeviceInstructions(minerals, shortlist, colors)}\nNo photograph is attached.`);
    const parsed = parseRank(generated.text);
    const cap = generated.onDevice ? 0.7 : 0.96;
    const candidates = toCandidates(parsed, minerals, cap);
    if (candidates.length) {
      textRank = {
        engine: generated.onDevice ? "on_device" : "cloud_text",
        model: generated.onDevice ? "Gemini Nano" : settings.modelName,
        summary: parsed.summary,
        candidates,
        confidence: candidates[0].confidence,
      };
    }
  } catch (error) {
    textRank = null;
    failure = error instanceof Error ? error.message : "The colour brief call failed.";
  }

  const keepOnDevice = textRank?.engine === "on_device" && textRank.confidence >= settings.threshold;
  if (!keepOnDevice) {
    try {
      const model = visionModel(settings.modelName, cloudInstructions(minerals, shortlist, colors));
      const data = await fileToInlineData(file);
      const generated = await generate(model, [
        "Identify the specimen in the attached photograph. Return the JSON object from your instructions.",
        { inlineData: { mimeType: file.type || "image/jpeg", data } },
      ]);
      const parsed = parseRank(generated.text);
      const candidates = toCandidates(parsed, minerals, 0.96);
      if (candidates.length) {
        return {
          engine: "cloud_vision",
          model: settings.modelName,
          summary: parsed?.summary || "Gemini examined the photograph through Firebase AI Logic.",
          candidates,
          color_shortlist: colors,
          shortlist: shortlist.map(({ id, score }) => ({ id, score })),
        };
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : "The photo call failed.";
      failure = failure ? `${failure} ${message}` : message;
    }
  }

  if (textRank) {
    return {
      engine: textRank.engine,
      model: textRank.model,
      summary: textRank.summary,
      candidates: textRank.candidates,
      color_shortlist: colors,
      shortlist: shortlist.map(({ id, score }) => ({ id, score })),
    };
  }
  const draft = shortlistDraft(colors, shortlist);
  if (failure) draft.summary = `${draft.summary} ${failure}`.slice(0, 800);
  return draft;
}
