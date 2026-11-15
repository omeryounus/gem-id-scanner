import { useState } from "react";
import { Link, useParams } from "react-router-dom";
import { ArrowLeft, BookmarkPlus, Columns2, CloudUpload, Cpu, FlaskConical, ScanLine } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Eyebrow, Panel, SourceBadge, Swatch } from "@/components/Bits";
import { RecordDialog } from "@/components/RecordDialog";
import { BenchGuide } from "@/components/BenchGuide";
import { BenchHistory } from "@/components/BenchHistory";
import { useAnalysis } from "@/lib/queries";
import { fileUrl } from "@/lib/api";
import { ENGINES, engineSummary } from "@/lib/catalog";
import { useLocalPhoto } from "@/lib/localPhotos";
import { cn } from "@/lib/utils";

const pct = (x) => `${Math.round((x || 0) * 100)}%`;
const BANDS = ["Inconclusive", "Low", "Medium", "High"];

const ConfidenceGauge = ({ a }) => {
  const c = a.top?.confidence || 0;
  return (
    <div data-testid="analysis-confidence">
      <div className="flex items-end justify-between">
        <div className="font-display text-6xl font-semibold tabular-nums tracking-tight text-primary" data-testid="analysis-confidence-value">{pct(c)}</div>
        <div className="pb-2 text-right font-mono text-[11px] text-muted-foreground" data-testid="analysis-confidence-cap">
          cap {pct(a.confidence_cap)}{a.capped && <div className="text-primary">raw {pct(a.top.confidence_raw)} · capped</div>}
        </div>
      </div>
      <div className="relative mt-3 h-2.5 rounded-full bg-ink/[0.06]">
        <div className="h-full rounded-full bg-primary shadow-[0_0_16px_rgba(245,158,11,0.5)] transition-[width] duration-700" style={{ width: pct(c) }} />
        <div className="absolute -top-1.5 h-5 w-[2px] bg-foreground" style={{ left: pct(a.confidence_cap) }} title="96% confidence cap" />
        <span className="absolute top-4 -translate-x-1/2 font-mono text-[9px] text-muted-foreground" style={{ left: pct(a.confidence_cap) }}>{Math.round((a.confidence_cap || 0.96) * 100)}</span>
      </div>
      <div className="mt-7 grid grid-cols-4 gap-1" data-testid="analysis-band">
        {BANDS.map((b) => (
          <div key={b} className={cn("rounded-md border py-1.5 text-center font-mono text-[10px] uppercase tracking-wider", a.band === b ? "border-primary bg-primary/15 text-primary" : "border-border text-muted-foreground/60")} data-testid={a.band === b ? "analysis-band-active" : undefined}>
            {b}
          </div>
        ))}
      </div>
    </div>
  );
};

const EngineLine = ({ engine, model }) => (
  <div data-testid="analysis-engine-line">
    <Eyebrow className="mb-2">Engine line</Eyebrow>
    <div className="grid grid-cols-2 gap-1 sm:grid-cols-4">
      {ENGINES.map((e) => (
        <div key={e.id} title={e.note} data-testid={`analysis-engine-${e.id}`} data-active={engine === e.id} className={cn("rounded-md border px-2 py-2 font-mono text-[10.5px]", engine === e.id ? "border-primary bg-primary/15 text-primary" : "border-border text-muted-foreground/50 line-through decoration-ink/20")}>
          {e.id}
        </div>
      ))}
    </div>
    <p className="mt-2 text-xs text-muted-foreground" data-testid="analysis-engine-summary">{engineSummary(engine, model)}</p>
  </div>
);

const Network = ({ a }) => {
  const left = a.photo_left_device;
  const vision = a.engine === "cloud_vision";
  return (
    <div className={cn("flex items-start gap-3 rounded-lg border p-4", left ? "border-sky-400/30 bg-sky-400/[0.06]" : "border-emerald-400/30 bg-emerald-400/[0.06]")} data-testid="analysis-network-indicator" data-left-device={left}>
      {left ? <CloudUpload className="mt-0.5 h-5 w-5 text-sky-300" /> : <Cpu className="mt-0.5 h-5 w-5 text-emerald-300" />}
      <div>
        <div className="text-sm font-medium">{vision ? "Photo was sent to Gemini" : left ? "Photo was stored on the Field Bench server" : "Photo stayed on this computer"}</div>
        <div className="font-mono text-[11px] text-muted-foreground">
          {vision ? `${((a.bytes_sent || 0) / 1024).toFixed(0)} KB sent through Firebase AI Logic` : left ? `${((a.bytes_sent || 0) / 1024).toFixed(0)} KB uploaded. No model saw the photo.` : "0 bytes sent to a model"}
        </div>
      </div>
    </div>
  );
};

const Ranks = ({ a }) => (
  <Panel className="overflow-hidden" data-testid="analysis-rank-list">
    <div className="border-b border-border px-5 py-3"><Eyebrow>Rank</Eyebrow></div>
    <ol>
      {a.candidates.map((c) => (
        <li key={c.rank} className="flex items-center gap-4 border-b border-border px-5 py-3 last:border-0" data-testid={`analysis-rank-${c.rank}`}>
          <span className={cn("font-mono text-sm tabular-nums", c.rank === 1 ? "text-primary" : "text-muted-foreground")}>#{c.rank}</span>
          <div className="min-w-0 flex-1">
            <Link to={`/gemstones/${c.mineral_id}`} viewTransition className="font-medium hover:text-primary">{c.name}</Link>
            {c.why && <div className="truncate text-xs text-muted-foreground">{c.why}</div>}
          </div>
          <div className="w-24 text-right">
            <div className="font-mono text-sm tabular-nums">{pct(c.confidence)}</div>
            <div className="mt-1 h-1 rounded-full bg-ink/[0.06]"><div className="h-full rounded-full bg-primary/70" style={{ width: pct(c.confidence) }} /></div>
          </div>
        </li>
      ))}
      {!a.candidates.length && <li className="px-5 py-4 text-sm text-muted-foreground">No candidates.</li>}
    </ol>
  </Panel>
);

const Tests = ({ a }) => (
  <div className="space-y-3" data-testid="analysis-separating-tests">
    <Eyebrow className="flex items-center gap-1.5"><FlaskConical className="h-3 w-3" /> Separating tests</Eyebrow>
    {a.separating_tests.map((g) => (
      <Panel key={g.b} className="p-4">
        <div className="mb-3 text-sm"><span className="text-primary">{g.a_name}</span> <span className="text-muted-foreground">vs</span> {g.b_name}</div>
        <div className="grid gap-2 sm:grid-cols-2">
          {g.tests.map((t) => (
            <div key={t.test} className="rounded-lg bg-ink/[0.03] p-3">
              <div className="flex items-baseline justify-between gap-2 text-sm font-medium">{t.test}</div>
              <div className="mt-1 font-mono text-[11px]"><span className="text-primary">{t.a}</span> · {t.b}</div>
              <div className="mt-1 text-xs text-muted-foreground">{t.how}</div>
            </div>
          ))}
        </div>
      </Panel>
    ))}
    {!a.separating_tests.length && <p className="text-sm text-muted-foreground">Not enough candidates to separate.</p>}
  </div>
);

export default function AnalysisPage() {
  const { id } = useParams();
  const { data: a, isLoading, isError } = useAnalysis(id);
  const localPhoto = useLocalPhoto(id);
  const [save, setSave] = useState(null);

  if (isLoading) return <div className="grid gap-6 lg:grid-cols-2"><Skeleton className="aspect-square rounded-xl" /><Skeleton className="h-96 rounded-xl" /></div>;
  if (isError || !a) return <p className="text-muted-foreground" data-testid="analysis-not-found">Analysis not found in this browser. <Link to="/identify" className="text-primary">Run a scan</Link></p>;

  const second = a.candidates[1];
  return (
    <div className="rise" data-testid="analysis-detail">
      <Link to="/identify" viewTransition className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-primary"><ArrowLeft className="h-4 w-4" /> Identify</Link>
      <div className="grid grid-cols-[minmax(0,1fr)] gap-8 lg:grid-cols-[minmax(0,5fr)_minmax(0,6fr)]">
        <div className="space-y-4 lg:sticky lg:top-24 lg:self-start">
          <div className="relative overflow-hidden rounded-xl border border-border">
            <img src={a.photo_path ? fileUrl(a.photo_path) : localPhoto || ""} alt="Specimen" className="aspect-square w-full object-cover" data-testid="analysis-photo" />
            <SourceBadge source={a.source} className="absolute left-3 top-3 bg-black/50" />
            <div className="absolute bottom-3 left-3 rounded-md bg-black/60 px-2 py-1 font-mono text-[10px] text-white/70 backdrop-blur">run {a.id.slice(0, 8)} · {new Date(a.created_at).toLocaleString()}</div>
          </div>
          <Network a={a} />
          <div data-testid="analysis-color-shortlist">
            <Eyebrow className="mb-2">Colour shortlist</Eyebrow>
            <div className="flex h-3 overflow-hidden rounded-full">
              {a.color_shortlist.map((c) => <span key={c.color} style={{ width: pct(c.share), background: c.hex }} title={c.color} />)}
            </div>
            <div className="mt-2 flex flex-wrap gap-3">
              {a.color_shortlist.map((c) => <span key={c.color} className="inline-flex items-center gap-1.5 text-xs capitalize"><Swatch color={c.color} size={10} />{c.color}<span className="font-mono text-muted-foreground">{pct(c.share)}</span></span>)}
            </div>
          </div>
        </div>
        <div className="space-y-8">
          <div>
            <Eyebrow className="mb-2">Best match</Eyebrow>
            <h1 className="font-display text-4xl font-semibold tracking-tight sm:text-5xl" data-testid="analysis-top-name">{a.top?.name || "Inconclusive"}</h1>
            {a.summary && <p className="mt-3 max-w-xl text-sm leading-relaxed text-muted-foreground" data-testid="analysis-summary">{a.summary}</p>}
            <div className="mt-5 flex flex-wrap gap-2">
              <Button onClick={() => setSave({})} disabled={!a.top} data-testid="analysis-save-record"><BookmarkPlus className="mr-1.5 h-4 w-4" /> Save to records</Button>
              {second && <Button asChild variant="outline"><Link to={`/compare?a=${a.top.mineral_id}&b=${second.mineral_id}`} viewTransition data-testid="analysis-compare-top"><Columns2 className="mr-1.5 h-4 w-4" /> Compare top 2</Link></Button>}
              <Button asChild variant="ghost"><Link to="/identify" viewTransition data-testid="analysis-scan-again"><ScanLine className="mr-1.5 h-4 w-4" /> Scan another</Link></Button>
            </div>
          </div>
          <Panel className="p-5"><ConfidenceGauge a={a} /></Panel>
          <EngineLine engine={a.engine} model={a.model} />
          <Ranks a={a} />
          <Tests a={a} />
          <BenchGuide a={a} onSave={(r) => setSave(r)} />
          {a.bench_runs?.length > 0 && (
            <Panel className="p-5" data-testid="analysis-bench-history">
              <BenchHistory runs={[...a.bench_runs].reverse()} title="Past bench runs" />
            </Panel>
          )}
        </div>
      </div>
      {a.top && (
        <RecordDialog
          open={!!save}
          onOpenChange={(o) => !o && setSave(null)}
          initial={save && (() => {
            const winner = save.winner && a.candidates.find((c) => c.mineral_id === save.winner);
            return {
              mineral_id: winner?.mineral_id || a.top.mineral_id,
              name: winner?.name || a.top.name,
              analysis_id: a.id,
              photo_path: a.photo_path,
              notes: save.notes || a.summary || "",
              ...(save.confirmed && { confirmed: save.confirmed }),
            };
          })()}
        />
      )}
    </div>
  );
}
