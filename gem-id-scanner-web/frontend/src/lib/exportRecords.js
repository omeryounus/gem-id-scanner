import { hardnessLabel } from "@/lib/catalog";

const COLUMNS = [
  ["Label", (r) => r.name],
  ["Species", (r, m) => m?.name || ""],
  ["Formula", (r, m) => m?.formula || ""],
  ["Mohs hardness", (r, m) => (m ? hardnessLabel(m.hardness) : "")],
  ["Weight", (r) => r.weight ?? ""],
  ["Unit", (r) => (r.weight != null ? r.weight_unit : "")],
  ["Form", (r) => r.form],
  ["Where acquired", (r) => r.location],
  ["Latitude", (r) => r.lat ?? ""],
  ["Longitude", (r) => r.lng ?? ""],
  ["Confirmation", (r) => r.confirmed],
  ["Favorite", (r) => (r.favorite ? "yes" : "no")],
  ["Tags", (r) => r.tags.join(", ")],
  ["Notes", (r) => r.notes],
  ["Source", (r) => r.source],
  ["Saved at", (r) => r.created_at],
];

const cell = (v) => {
  const s = String(v ?? "");
  return /[",\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};

export function downloadCSV(records, minerals) {
  const byId = Object.fromEntries(minerals.map((m) => [m.id, m]));
  const rows = [COLUMNS.map(([h]) => h), ...records.map((r) => COLUMNS.map(([, f]) => f(r, byId[r.mineral_id])))];
  const csv = "\uFEFF" + rows.map((row) => row.map(cell).join(",")).join("\r\n");
  const url = URL.createObjectURL(new Blob([csv], { type: "text/csv;charset=utf-8" }));
  const a = Object.assign(document.createElement("a"), { href: url, download: `field-bench-records-${new Date().toISOString().slice(0, 10)}.csv` });
  document.body.appendChild(a);
  a.click();
  a.remove();
  URL.revokeObjectURL(url);
}
