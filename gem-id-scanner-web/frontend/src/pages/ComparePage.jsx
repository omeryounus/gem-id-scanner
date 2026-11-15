import { Link, useSearchParams } from "react-router-dom";
import { ArrowLeftRight } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Eyebrow, HardnessBar, PageHeader, Panel, Swatch } from "@/components/Bits";
import { MineralPicker } from "@/components/MineralPicker";
import { useMinerals } from "@/lib/queries";
import { hardnessLabel } from "@/lib/catalog";
import { cn } from "@/lib/utils";

const ROWS = [
  ["Formula", (m) => <span className="font-mono">{m.formula}</span>, (m) => m.formula],
  ["Category", (m) => m.category, (m) => m.category],
  ["Mohs hardness", (m) => <div className="space-y-1.5"><span className="font-mono">{hardnessLabel(m.hardness)}</span><HardnessBar range={m.hardness} /></div>, (m) => m.hardness.join()],
  ["Streak", (m) => m.streak, (m) => m.streak],
  ["Lustre", (m) => m.luster, (m) => m.luster],
  ["Specific gravity", (m) => <span className="font-mono">{m.specific_gravity}</span>, (m) => m.specific_gravity],
  ["Cleavage", (m) => m.cleavage, (m) => m.cleavage],
  ["Crystal system", (m) => m.crystal_system, (m) => m.crystal_system],
  ["Colours", (m) => <div className="flex flex-wrap gap-1">{m.colors.map((c) => <Swatch key={c} color={c} size={14} />)}</div>, (m) => m.colors.join()],
  ["Field tell", (m) => m.diagnostic, (m) => m.diagnostic],
];

export default function ComparePage() {
  const [sp, setSp] = useSearchParams();
  const { data: minerals = [] } = useMinerals();
  const a = minerals.find((m) => m.id === sp.get("a"));
  const b = minerals.find((m) => m.id === sp.get("b"));
  const set = (k) => (m) => {
    const n = new URLSearchParams(sp);
    m ? n.set(k, m.id) : n.delete(k);
    setSp(n, { replace: true });
  };
  const swap = () => setSp({ ...(b && { a: b.id }), ...(a && { b: a.id }) }, { replace: true });
  const diffs = a && b ? ROWS.filter(([, , key]) => key(a) !== key(b)).length : 0;

  return (
    <div className="rise">
      <PageHeader eyebrow="Station 05 · Compare" title="Side by side" testid="compare-header">
        {a && b && <span className="rounded-full border border-primary/40 bg-primary/10 px-3 py-1.5 font-mono text-xs text-primary" data-testid="compare-diff-count">{diffs} of {ROWS.length} properties differ</span>}
      </PageHeader>
      <div className="mb-6 grid grid-cols-[1fr_auto_1fr] items-end gap-2 sm:gap-4">
        <div className="space-y-1.5"><Eyebrow>Specimen A</Eyebrow><MineralPicker value={a?.id} onChange={set("a")} testid="compare-picker-a" /></div>
        <Button variant="outline" size="icon" onClick={swap} aria-label="Swap" data-testid="compare-swap"><ArrowLeftRight className="h-4 w-4" /></Button>
        <div className="space-y-1.5"><Eyebrow>Specimen B</Eyebrow><MineralPicker value={b?.id} onChange={set("b")} testid="compare-picker-b" /></div>
      </div>
      {a && b ? (
        <Panel className="overflow-hidden" data-testid="compare-table">
          <div className="grid grid-cols-[minmax(90px,160px)_1fr_1fr] border-b border-border bg-ink/[0.02]">
            <div />
            {[a, b].map((m) => (
              <Link key={m.id} to={`/gemstones/${m.id}`} viewTransition className="border-l border-border p-4 hover:bg-ink/[0.02]" data-testid={`compare-head-${m.id}`}>
                <div className="font-display text-xl font-medium sm:text-2xl">{m.name}</div>
              </Link>
            ))}
          </div>
          {ROWS.map(([label, render, key]) => {
            const diff = key(a) !== key(b);
            return (
              <div key={label} className={cn("grid grid-cols-[minmax(90px,160px)_1fr_1fr] border-b border-border text-sm last:border-0", diff && "bg-primary/[0.035]")} data-testid={`compare-row-${label.toLowerCase().replace(/ /g, "-")}`}>
                <div className="flex items-start gap-2 p-4">
                  {diff && <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-primary" />}
                  <Eyebrow>{label}</Eyebrow>
                </div>
                <div className="min-w-0 border-l border-border p-4">{render(a)}</div>
                <div className="min-w-0 border-l border-border p-4">{render(b)}</div>
              </div>
            );
          })}
        </Panel>
      ) : (
        <div className="grid-bench rounded-xl border border-dashed border-border p-10 text-muted-foreground" data-testid="compare-empty">
          Pick two species above, or add them from the <Link to="/gemstones" viewTransition className="text-primary hover:underline">catalog</Link> with the + button.
        </div>
      )}
    </div>
  );
}
