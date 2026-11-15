import { useState } from "react";
import { ChevronDown, CircleCheck, CircleAlert, CircleHelp, FlaskConical } from "lucide-react";
import { cn } from "@/lib/utils";

export const RUN_UI = {
  confirmed: { Icon: CircleCheck, label: "Confirmed", cls: "text-emerald-300 border-emerald-400/30 bg-emerald-400/10" },
  disputed: { Icon: CircleAlert, label: "Disputed", cls: "text-red-300 border-red-400/30 bg-red-400/10" },
  unconfirmed: { Icon: CircleHelp, label: "Inconclusive", cls: "text-muted-foreground border-border" },
};

const ANSWER = (s) => (s.answer === "a" ? s.a_name : s.answer === "b" ? s.b_name : s.answer === "unsure" ? "can't tell" : "skipped");

const Run = ({ run, open, onToggle }) => {
  const ui = RUN_UI[run.status] || RUN_UI.unconfirmed;
  return (
    <li className="relative pl-6" data-testid={`bench-run-${run.id}`}>
      <span className={cn("absolute left-0 top-1 grid h-4 w-4 place-items-center rounded-full border bg-card", ui.cls)}><ui.Icon className="h-2.5 w-2.5" /></span>
      <button onClick={onToggle} aria-expanded={open} className="flex w-full items-start gap-2 text-left" data-testid={`bench-run-toggle-${run.id}`}>
        <span className="min-w-0 flex-1">
          <span className="block text-sm">{run.text}</span>
          <span className="font-mono text-[10.5px] text-muted-foreground">{new Date(run.created_at).toLocaleString([], { dateStyle: "medium", timeStyle: "short" })} · {run.steps.length} tests</span>
        </span>
        <ChevronDown className={cn("mt-0.5 h-4 w-4 shrink-0 text-muted-foreground transition-transform", open && "rotate-180")} />
      </button>
      {open && (
        <ul className="rise mt-2 space-y-1 rounded-lg border border-border p-2 text-xs">
          {run.steps.map((s, i) => (
            <li key={i} className="flex justify-between gap-3">
              <span className="truncate text-muted-foreground">{s.test} · {s.a_name} vs {s.b_name}</span>
              <span className={cn("shrink-0 font-mono", s.answer === "a" || s.answer === "b" ? "text-primary" : "text-muted-foreground")}>{ANSWER(s)}</span>
            </li>
          ))}
        </ul>
      )}
    </li>
  );
};

export function BenchHistory({ runs = [], className, title = "Bench history" }) {
  const [open, setOpen] = useState(null);
  if (!runs.length) return null;
  return (
    <div className={className} data-testid="bench-history">
      <div className="mb-2 flex items-center gap-1.5 font-mono text-[10.5px] uppercase tracking-[0.18em] text-muted-foreground">
        <FlaskConical className="h-3 w-3 text-primary" /> {title} · {runs.length}
      </div>
      <ol className="relative space-y-3 before:absolute before:bottom-1 before:left-[7.5px] before:top-1 before:w-px before:bg-border">
        {runs.map((r) => <Run key={r.id} run={r} open={open === r.id} onToggle={() => setOpen(open === r.id ? null : r.id)} />)}
      </ol>
    </div>
  );
}

export const LatestRunChip = ({ runs = [], onClick, expanded, testid }) => {
  if (!runs.length) return null;
  const ui = RUN_UI[runs[0].status] || RUN_UI.unconfirmed;
  return (
    <button onClick={onClick} aria-expanded={expanded} data-testid={testid} className={cn("inline-flex items-center gap-1 rounded-md border px-1.5 py-0.5 font-mono text-[10px] uppercase transition-colors hover:border-primary/50", ui.cls)}>
      <FlaskConical className="h-3 w-3" /> {runs.length} bench {runs.length === 1 ? "run" : "runs"}
      <ChevronDown className={cn("h-3 w-3 transition-transform", expanded && "rotate-180")} />
    </button>
  );
};
