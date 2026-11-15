export const COLOR_HEX = {
  colorless: "#e6ecef",
  white: "#f5f5f4",
  gray: "#8a8f98",
  black: "#1c1d20",
  red: "#c0283a",
  pink: "#ec82aa",
  orange: "#eb781e",
  yellow: "#f0c828",
  green: "#2a9654",
  blue: "#2f62d4",
  purple: "#7c3ca8",
  brown: "#7a4b28",
  metallic: "linear-gradient(135deg,#d9d4c7,#8d887c 55%,#efe9da)",
};

export const COLORS = Object.keys(COLOR_HEX);

export const CATEGORIES = [
  "Silicate",
  "Oxide",
  "Carbonate",
  "Sulfide",
  "Native Element",
  "Halide",
  "Sulfate",
  "Phosphate",
  "Organic",
];

export const ENGINES = [
  { id: "on_device", label: "On-device", note: "Firebase AI Logic · Gemini Nano in this browser. The photo stayed on this computer." },
  { id: "cloud_text", label: "Cloud text", note: "Firebase AI Logic · Gemini ranked the on-device colour brief. The photo stayed on this computer." },
  { id: "cloud_vision", label: "Cloud vision", note: "Firebase AI Logic · Gemini examined the photo." },
  { id: "shortlist", label: "Shortlist", note: "Colour shortlist only. No model returned a catalog rank." },
];

export const engineSummary = (engine, model) => {
  const note = ENGINES.find((item) => item.id === engine)?.note || ENGINES[3].note;
  if (engine === "cloud_vision" && model) return `${note.slice(0, -1)} (${model}).`;
  return note;
};

export const FORMS = ["Raw", "Crystal", "Cluster", "Tumbled", "Cabochon", "Faceted", "Slab", "Other"];

export const hardnessLabel = ([a, b]) => (a === b ? `${a}` : `${a}–${b}`);
