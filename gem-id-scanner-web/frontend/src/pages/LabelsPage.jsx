import { Link } from "react-router-dom";
import { ArrowLeft, Printer, Gem } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useMinerals, useRecords } from "@/lib/queries";
import { hardnessLabel } from "@/lib/catalog";
import { QRCodeSVG } from "qrcode.react";

export const specimenUrl = (r) => `${window.location.origin}/s/${r.share_token}`;

const Label = ({ r, m }) => (
  <article className="label-card flex flex-col rounded-md border border-neutral-400 bg-white p-4 text-neutral-900" data-testid={`label-${r.id}`}>
    <div className="flex items-start justify-between gap-2 border-b border-neutral-300 pb-2">
      <div className="min-w-0">
        <div className="font-display text-lg font-semibold leading-tight">{r.name}</div>
        {m && <div className="text-xs italic text-neutral-600">{m.name}</div>}
      </div>
      <Gem className="h-4 w-4 shrink-0 text-amber-600" />
    </div>
    <dl className="mt-2 grid grid-cols-[84px_1fr] gap-x-2 gap-y-0.5 text-[11px] leading-snug">
      {m && <><dt className="text-neutral-500">Formula</dt><dd className="font-mono">{m.formula}</dd></>}
      {m && <><dt className="text-neutral-500">Hardness</dt><dd className="font-mono">Mohs {hardnessLabel(m.hardness)}</dd></>}
      {r.weight != null && <><dt className="text-neutral-500">Weight</dt><dd className="font-mono">{r.weight} {r.weight_unit}</dd></>}
      <dt className="text-neutral-500">Form</dt><dd>{r.form}</dd>
      {r.location && <><dt className="text-neutral-500">Locality</dt><dd>{r.location}</dd></>}
      <dt className="text-neutral-500">Status</dt><dd className="min-w-0 break-words capitalize">{r.confirmed}</dd>
    </dl>
    <div className="mt-auto flex items-end justify-between gap-3 pt-2 font-mono text-[9px] text-neutral-500">
      <div className="min-w-0 space-y-0.5">
        <div className="break-words">{r.tags.map((t) => `#${t}`).join(" ")}</div>
        <div>FB-{r.id.slice(0, 6).toUpperCase()} · {new Date(r.created_at).toLocaleDateString()}</div>
        <div className="text-neutral-400">Scan to open record</div>
      </div>
      {r.share_token && (
        <QRCodeSVG value={specimenUrl(r)} size={64} level="M" marginSize={0} className="shrink-0" data-testid={`label-qr-${r.id}`} title={specimenUrl(r)} />
      )}
    </div>
  </article>
);

export default function LabelsPage() {
  const { data: records = [], isLoading } = useRecords();
  const { data: minerals = [] } = useMinerals();
  const byId = Object.fromEntries(minerals.map((m) => [m.id, m]));
  return (
    <div className="min-h-dvh bg-neutral-200 print:bg-white">
      <div className="sticky top-0 z-10 flex items-center gap-3 border-b border-neutral-300 bg-white/90 px-6 py-3 text-neutral-900 backdrop-blur print:hidden">
        <Link to="/records" viewTransition className="inline-flex items-center gap-1.5 text-sm hover:text-amber-700" data-testid="labels-back"><ArrowLeft className="h-4 w-4" /> Records</Link>
        <span className="font-mono text-xs text-neutral-500">{records.length} labels · A4 / Letter</span>
        <Button className="ml-auto" onClick={() => window.print()} disabled={!records.length} data-testid="labels-print"><Printer className="mr-1.5 h-4 w-4" /> Print labels</Button>
      </div>
      <div className="labels-sheet mx-auto my-8 grid max-w-[210mm] grid-cols-1 gap-3 sm:grid-cols-2 print:grid-cols-2 bg-white p-[10mm] shadow-xl print:my-0 print:shadow-none" data-testid="labels-sheet">
        {isLoading && <p className="text-sm text-neutral-500">Loading…</p>}
        {!isLoading && !records.length && <p className="col-span-2 text-sm text-neutral-500" data-testid="labels-empty">No saved records to print yet.</p>}
        {records.map((r) => <Label key={r.id} r={r} m={byId[r.mineral_id]} />)}
      </div>
    </div>
  );
}
