import { useEffect, useMemo, useState } from "react";
import { ChevronLeft, ChevronRight, FlaskConical, RotateCcw, ShieldAlert, Wrench, BookmarkPlus, CircleCheck, CircleAlert, CircleHelp } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Eyebrow, Panel } from "@/components/Bits";
import { useQueryClient } from "@tanstack/react-query";
import { GUIDE, verdict } from "@/lib/benchGuide";
import { api } from "@/lib/api";
import { cn } from "@/lib/utils";

const buildSteps = (a) =>
  a.separating_tests.flatMap((g) =>
    g.tests.map((t) => ({ key: `${g.b}:${t.test}`, test: t.test, aId: g.a, bId: g.b, aName: g.a_name, bName: g.b_name, aVal: t.a, bVal: t.b, how: t.how })),
  );

function useGuideState(id) {
  const k = `fieldbench.guide.${id}`;
  const [state, setState] = useState(() => JSON.parse(localStorage.getItem(k) || '{"idx":0,"answers":{}}'));
  useEffect(() => localStorage.setItem(k, JSON.stringify(state)), [k, state]);
  return [state, setState];
}

const Choice = ({ active, onClick, label, sub, hotkey, testid }) => (
  <button
    onClick={onClick}
    role="radio"
    aria-checked={active}
    data-testid={testid}
    className={cn(
      "flex flex-1 items-start gap-3 rounded-lg border p-3 text-left transition-[border-color,background-color]",
      active ? "border-primary bg-primary/10" : "border-border hover:border-primary/40",
    )}
  >
    <kbd className={cn("mt-0.5 grid h-5 w-5 shrink-0 place-items-center rounded border font-mono text-[10px]", active ? "border-primary text-primary" : "border-border text-muted-foreground")}>{hotkey}</kbd>
    <span className="min-w-0">
      <span className="block text-sm font-medium">{label}</span>
      {sub && <span className="block font-mono text-[11px] text-muted-foreground">{sub}</span>}
    </span>
  </button>
);

const Step = ({ s, answer, onAnswer }) => {
  const g = GUIDE[s.test] || { tools: [], steps: [s.how] };
  return (
    <div className="rise space-y-5" key={s.key} data-testid="bench-guide-step">
      <div>
        <div className="font-display text-2xl font-medium" data-testid="bench-guide-step-title">{s.test}</div>
        <div className="text-sm text-muted-foreground"><span className="text-primary">{s.aName}</span> vs {s.bName}</div>
      </div>
      {g.tools.length > 0 && (
        <div className="flex flex-wrap items-center gap-1.5">
          <Wrench className="h-3.5 w-3.5 text-muted-foreground" />
          {g.tools.map((t) => <span key={t} className="rounded-full border border-border px-2 py-0.5 text-xs text-muted-foreground">{t}</span>)}
        </div>
      )}
      <ol className="space-y-2">
        {g.steps.map((txt, i) => (
          <li key={i} className="flex gap-3 text-sm">
            <span className="grid h-5 w-5 shrink-0 place-items-center rounded-full bg-ink/[0.06] font-mono text-[10px]">{i + 1}</span>
            <span className="leading-relaxed">{txt}</span>
          </li>
        ))}
      </ol>
      {g.safety && <div className="flex gap-2 rounded-lg border border-red-400/30 bg-red-400/[0.06] p-3 text-xs text-red-300"><ShieldAlert className="h-4 w-4 shrink-0" />{g.safety}</div>}
      <div>
        <Eyebrow className="mb-2">What did you observe?</Eyebrow>
        <div className="flex flex-col gap-2 sm:flex-row" role="radiogroup" aria-label="Observation">
          <Choice active={answer === "a"} onClick={() => onAnswer("a")} hotkey="1" label={`Like ${s.aName}`} sub={s.aVal} testid="bench-guide-answer-a" />
          <Choice active={answer === "b"} onClick={() => onAnswer("b")} hotkey="2" label={`Like ${s.bName}`} sub={s.bVal} testid="bench-guide-answer-b" />
          <Choice active={answer === "unsure"} onClick={() => onAnswer("unsure")} hotkey="3" label="Can't tell" sub="skip this test" testid="bench-guide-answer-unsure" />
        </div>
      </div>
    </div>
  );
};

const VERDICT_UI = {
  confirmed: { Icon: CircleCheck, cls: "border-emerald-400/30 bg-emerald-400/[0.06] text-emerald-300" },
  disputed: { Icon: CircleAlert, cls: "border-red-400/30 bg-red-400/[0.06] text-red-300" },
  unconfirmed: { Icon: CircleHelp, cls: "border-border text-muted-foreground" },
};

const summarize = (a, steps, answers) => {
  const v = verdict(steps, answers);
  const name = (id) => a.candidates.find((c) => c.mineral_id === id)?.name || id;
  const text =
    v.status === "confirmed" ? `Your tests support ${name(v.winner)}.` :
    v.status === "disputed" ? `Your tests point to ${name(v.winner)} instead of ${a.top.name}.` :
    v.winner ? `Leaning ${name(v.winner)} — run another test to confirm.` : "Not enough evidence yet.";
  return { v, text };
};

const Summary = ({ a, steps, answers, onSave, onRestart }) => {
  const { v, text } = summarize(a, steps, answers);
  const ui = VERDICT_UI[v.status];
  return (
    <div className="rise space-y-4" data-testid="bench-guide-summary">
      <div className={cn("flex items-start gap-3 rounded-lg border p-4", ui.cls)} data-testid="bench-guide-verdict" data-status={v.status}>
        <ui.Icon className="mt-0.5 h-5 w-5 shrink-0" />
        <div className="font-display text-lg text-foreground">{text}</div>
      </div>
      <ul className="divide-y divide-border rounded-lg border border-border text-sm">
        {steps.map((s) => (
          <li key={s.key} className="flex items-center justify-between gap-3 px-3 py-2">
            <span className="truncate">{s.test} <span className="text-muted-foreground">· vs {s.bName}</span></span>
            <span className="shrink-0 font-mono text-xs text-primary">{answers[s.key] === "a" ? s.aName : answers[s.key] === "b" ? s.bName : "—"}</span>
          </li>
        ))}
      </ul>
      <div className="flex flex-wrap gap-2">
        <Button onClick={() => onSave(v, text)} data-testid="bench-guide-save"><BookmarkPlus className="mr-1.5 h-4 w-4" /> Save results to records</Button>
        <Button variant="ghost" onClick={onRestart} data-testid="bench-guide-restart"><RotateCcw className="mr-1.5 h-4 w-4" /> Restart</Button>
      </div>
    </div>
  );
};

export function BenchGuide({ a, onSave }) {
  const steps = useMemo(() => buildSteps(a), [a]);
  const [{ idx, answers, posted }, setState] = useGuideState(a.id);
  const done = idx >= steps.length;
  const go = (i) => setState((s) => ({ ...s, idx: Math.max(0, Math.min(steps.length, i)) }));
  const answer = (val) => setState((s) => ({ idx: s.idx + 1, posted: false, answers: { ...s.answers, [steps[s.idx].key]: val } }));
  const qc = useQueryClient();

  useEffect(() => {
    if (!done || posted || !Object.keys(answers).length) return;
    const { v, text } = summarize(a, steps, answers);
    setState((s) => ({ ...s, posted: true }));
    api
      .post(`/analyses/${a.id}/bench-runs`, {
        status: v.status,
        winner: v.winner,
        text,
        steps: steps.map((s) => ({ test: s.test, a_name: s.aName, b_name: s.bName, answer: answers[s.key] || "none" })),
      })
      .then(() => ["analysis", "records"].forEach((k) => qc.invalidateQueries({ queryKey: [k] })));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [done, posted]);

  useEffect(() => {
    const onKey = (e) => {
      if (["INPUT", "TEXTAREA"].includes(e.target.tagName) || document.querySelector("[role=dialog]")) return;
      if (!done && ["1", "2", "3"].includes(e.key)) answer({ 1: "a", 2: "b", 3: "unsure" }[e.key]);
      if (e.key === "ArrowRight" && e.altKey) go(idx + 1);
      if (e.key === "ArrowLeft" && e.altKey) go(idx - 1);
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  });

  if (!steps.length) return null;
  const save = (v, text) => {
    const log = steps.map((s) => `• ${s.test} vs ${s.bName}: ${answers[s.key] === "a" ? s.aName : answers[s.key] === "b" ? s.bName : "inconclusive"}`).join("\n");
    onSave({ confirmed: v.status, notes: `Bench guide — ${text}\n${log}`, winner: v.winner });
  };

  return (
    <Panel className="overflow-hidden" data-testid="bench-guide">
      <div className="flex items-center gap-3 border-b border-border px-5 py-3">
        <FlaskConical className="h-4 w-4 text-primary" />
        <Eyebrow className="flex-1">Streak & bench test guide</Eyebrow>
        <span className="font-mono text-xs tabular-nums text-muted-foreground" data-testid="bench-guide-progress">{Math.min(idx + 1, steps.length)}/{steps.length}</span>
      </div>
      <div className="flex gap-1 px-5 pt-4" role="tablist" aria-label="Steps">
        {steps.map((s, i) => (
          <button
            key={s.key}
            role="tab"
            aria-selected={i === idx}
            aria-label={`Step ${i + 1}: ${s.test}`}
            onClick={() => go(i)}
            data-testid={`bench-guide-dot-${i}`}
            className={cn("h-1.5 flex-1 rounded-full transition-colors", i === idx ? "bg-primary" : answers[s.key] ? "bg-primary/40" : "bg-ink/10 hover:bg-ink/20")}
          />
        ))}
      </div>
      <div className="p-5">
        {done ? (
          <Summary a={a} steps={steps} answers={answers} onSave={save} onRestart={() => setState({ idx: 0, answers: {} })} />
        ) : (
          <Step s={steps[idx]} answer={answers[steps[idx].key]} onAnswer={answer} />
        )}
      </div>
      {!done && (
        <div className="flex items-center justify-between border-t border-border px-5 py-3">
          <Button variant="ghost" size="sm" disabled={idx === 0} onClick={() => go(idx - 1)} data-testid="bench-guide-prev"><ChevronLeft className="mr-1 h-4 w-4" /> Back</Button>
          <span className="hidden font-mono text-[10px] text-muted-foreground sm:block">Press 1 · 2 · 3 to answer</span>
          <Button variant="ghost" size="sm" onClick={() => go(idx + 1)} data-testid="bench-guide-next">{idx === steps.length - 1 ? "Results" : "Skip"} <ChevronRight className="ml-1 h-4 w-4" /></Button>
        </div>
      )}
    </Panel>
  );
}
