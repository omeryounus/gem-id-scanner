import { useParams, Link } from "react-router-dom";
import { ArrowLeft, Columns2, BookmarkPlus, FlaskConical } from "lucide-react";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Eyebrow, HardnessBar, Panel, Swatch } from "@/components/Bits";
import { RecordDialog } from "@/components/RecordDialog";
import { useMineral } from "@/lib/queries";
import { hardnessLabel } from "@/lib/catalog";

const Spec = ({ label, children, testid }) => (
  <div className="border-b border-border py-3.5 last:border-0 sm:grid sm:grid-cols-[160px_1fr] sm:gap-4">
    <Eyebrow className="mb-1 sm:mb-0 sm:pt-0.5">{label}</Eyebrow>
    <div className="text-sm" data-testid={testid}>{children}</div>
  </div>
);

const Lookalike = ({ base, item }) => (
  <Panel className="p-5" data-testid={`lookalike-${item.mineral.id}`}>
    <div className="mb-4 flex items-start justify-between gap-3">
      <Link to={`/gemstones/${item.mineral.id}`} viewTransition className="group">
        <div className="flex gap-1 pb-2">{item.mineral.colors.slice(0, 4).map((c) => <Swatch key={c} color={c} size={12} />)}</div>
        <div className="font-display text-lg font-medium group-hover:text-primary">{item.mineral.name}</div>
        <div className="font-mono text-xs text-muted-foreground">{item.mineral.formula}</div>
      </Link>
      <Button asChild size="sm" variant="outline" className="shrink-0">
        <Link to={`/compare?a=${base.id}&b=${item.mineral.id}`} viewTransition data-testid={`lookalike-compare-${item.mineral.id}`}>
          <Columns2 className="mr-1.5 h-3.5 w-3.5" /> Compare
        </Link>
      </Button>
    </div>
    <Eyebrow className="mb-2 flex items-center gap-1.5"><FlaskConical className="h-3 w-3" /> Separating tests</Eyebrow>
    <ul className="space-y-2">
      {item.tests.map((t) => (
        <li key={t.test} className="rounded-lg bg-ink/[0.03] p-3 text-sm">
          <div className="flex flex-wrap items-baseline justify-between gap-x-3">
            <span className="font-medium">{t.test}</span>
            <span className="font-mono text-xs"><span className="text-primary">{t.a}</span> <span className="text-muted-foreground">vs</span> {t.b}</span>
          </div>
          <div className="mt-1 text-xs text-muted-foreground">{t.how}</div>
        </li>
      ))}
      {!item.tests.length && <li className="text-sm text-muted-foreground">Properties overlap — rely on locality and lab tests.</li>}
    </ul>
  </Panel>
);

export default function GemstoneDetailPage() {
  const { id } = useParams();
  const { data: m, isLoading, isError } = useMineral(id);
  const [saveOpen, setSaveOpen] = useState(false);

  if (isLoading) return <Skeleton className="h-96 rounded-xl" />;
  if (isError || !m) return <p className="text-muted-foreground" data-testid="gemstone-not-found">Mineral not found. <Link to="/gemstones" className="text-primary">Back to catalog</Link></p>;

  return (
    <div className="rise" data-testid="gemstone-detail">
      <Link to="/gemstones" viewTransition className="mb-6 inline-flex items-center gap-1.5 text-sm text-muted-foreground hover:text-primary" data-testid="gemstone-back-link">
        <ArrowLeft className="h-4 w-4" /> Catalog
      </Link>
      <div className="mb-10 grid gap-8 lg:grid-cols-[1.2fr_1fr] lg:items-end">
        <div>
          <Eyebrow className="mb-3">{m.category} · {m.crystal_system}</Eyebrow>
          <h1 className="font-display text-4xl font-semibold tracking-tight sm:text-5xl lg:text-6xl" data-testid="gemstone-detail-name">{m.name}</h1>
          <div className="mt-4 font-mono text-2xl text-primary sm:text-3xl" data-testid="gemstone-detail-formula">{m.formula}</div>
        </div>
        <div className="flex flex-wrap gap-2 lg:justify-end">
          <Button onClick={() => setSaveOpen(true)} data-testid="gemstone-save-record"><BookmarkPlus className="mr-1.5 h-4 w-4" /> Save to records</Button>
          {m.lookalikes[0] && (
            <Button asChild variant="outline">
              <Link to={`/compare?a=${m.id}&b=${m.lookalikes[0]}`} viewTransition data-testid="gemstone-compare-button"><Columns2 className="mr-1.5 h-4 w-4" /> Compare</Link>
            </Button>
          )}
        </div>
      </div>
      <div className="grid gap-8 lg:grid-cols-[1fr_1fr]">
        <Panel className="px-5 py-2">
          <Spec label="Mohs hardness" testid="gemstone-detail-hardness">
            <div className="mb-2 font-mono text-lg">{hardnessLabel(m.hardness)}</div>
            <HardnessBar range={m.hardness} className="max-w-xs" />
          </Spec>
          <Spec label="Streak" testid="gemstone-detail-streak">{m.streak}</Spec>
          <Spec label="Lustre">{m.luster}</Spec>
          <Spec label="Specific gravity"><span className="font-mono">{m.specific_gravity}</span></Spec>
          <Spec label="Cleavage">{m.cleavage}</Spec>
          <Spec label="Crystal system">{m.crystal_system}</Spec>
          <Spec label="Colours">
            <div className="flex flex-wrap gap-2">
              {m.colors.map((c) => <span key={c} className="inline-flex items-center gap-1.5 rounded-full border border-border px-2 py-0.5 text-xs capitalize"><Swatch color={c} size={10} />{c}</span>)}
            </div>
          </Spec>
          <Spec label="Field tell">{m.diagnostic}</Spec>
        </Panel>
        <div className="space-y-4" data-testid="gemstone-lookalikes">
          <Eyebrow>Known lookalikes · {m.lookalike_details.length}</Eyebrow>
          {m.lookalike_details.map((l) => <Lookalike key={l.mineral.id} base={m} item={l} />)}
        </div>
      </div>
      <RecordDialog open={saveOpen} onOpenChange={setSaveOpen} initial={{ mineral_id: m.id, name: m.name }} />
    </div>
  );
}
