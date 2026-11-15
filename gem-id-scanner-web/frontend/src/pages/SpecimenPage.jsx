import { Link, useParams } from "react-router-dom";
import { useQuery } from "@tanstack/react-query";
import { Gem, MapPin, Scale, ArrowRight, BadgeCheck, CircleAlert, CircleHelp } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { Eyebrow, Panel } from "@/components/Bits";
import { BenchHistory } from "@/components/BenchHistory";
import { api } from "@/lib/api";
import { useMineral, useRecords } from "@/lib/queries";
import { hardnessLabel } from "@/lib/catalog";
import { cn } from "@/lib/utils";

const STATUS = {
  confirmed: { Icon: BadgeCheck, cls: "text-emerald-300 border-emerald-400/30 bg-emerald-400/10" },
  disputed: { Icon: CircleAlert, cls: "text-red-300 border-red-400/30 bg-red-400/10" },
  unconfirmed: { Icon: CircleHelp, cls: "text-muted-foreground border-border" },
};

const Fact = ({ k, v, mono }) => (
  <div className="rounded-lg border border-border p-3">
    <Eyebrow>{k}</Eyebrow>
    <div className={cn("mt-1 text-sm", mono && "font-mono")}>{v}</div>
  </div>
);

export default function SpecimenPage() {
  const { token } = useParams();
  const { data: r, isLoading, isError } = useQuery({ queryKey: ["specimen", token], queryFn: () => api.get(`/specimens/${token}`).then((x) => x.data), retry: false });
  const { data: m } = useMineral(r?.mineral_id);
  const { data: mine = [] } = useRecords();
  const owned = r && mine.some((x) => x.id === r.id);
  const s = STATUS[r?.confirmed] || STATUS.unconfirmed;

  return (
    <div className="min-h-dvh px-5 py-8 sm:py-14">
      <div className="mx-auto max-w-2xl">
        <Link to="/identify" viewTransition className="mb-8 inline-flex items-center gap-2 font-display text-lg font-semibold" data-testid="specimen-brand">
          <span className="grid h-8 w-8 place-items-center rounded-lg bg-primary text-primary-foreground"><Gem className="h-4 w-4" /></span> Field Bench
        </Link>
        {isLoading && <Skeleton className="h-96 rounded-xl" />}
        {isError && (
          <Panel className="p-8" data-testid="specimen-not-found">
            <div className="font-display text-2xl">Specimen not found</div>
            <p className="mt-2 text-sm text-muted-foreground">This label may belong to a record that was deleted.</p>
          </Panel>
        )}
        {r && (
          <Panel className="rise overflow-hidden" data-testid="specimen-card">
            {r.has_photo && <img src={`${process.env.REACT_APP_BACKEND_URL}/api/specimens/${token}/photo`} alt={r.name} className="aspect-[16/10] w-full object-cover" data-testid="specimen-photo" />}
            <div className="space-y-6 p-6 sm:p-8">
              <div>
                <Eyebrow>Specimen · FB-{r.id.slice(0, 6).toUpperCase()}</Eyebrow>
                <h1 className="mt-1 font-display text-4xl font-semibold tracking-tight sm:text-5xl" data-testid="specimen-name">{r.name}</h1>
                <div className="mt-3 flex flex-wrap items-center gap-3 text-sm text-muted-foreground">
                  {m && <Link to={`/gemstones/${m.id}`} viewTransition className="text-primary hover:underline" data-testid="specimen-species-link">{m.name}</Link>}
                  <span className={cn("inline-flex items-center gap-1 rounded-md border px-1.5 py-0.5 font-mono text-[10px] uppercase", s.cls)} data-testid="specimen-status"><s.Icon className="h-3 w-3" />{r.confirmed}</span>
                  {r.location && <span className="inline-flex items-center gap-1"><MapPin className="h-3.5 w-3.5" />{r.location}</span>}
                </div>
              </div>
              <div className="grid grid-cols-2 gap-2 sm:grid-cols-4">
                {m && <Fact k="Formula" v={m.formula} mono />}
                {m && <Fact k="Mohs" v={hardnessLabel(m.hardness)} mono />}
                <Fact k="Form" v={r.form} />
                {r.weight != null && <Fact k="Weight" v={<span className="inline-flex items-center gap-1"><Scale className="h-3 w-3" />{r.weight} {r.weight_unit}</span>} mono />}
              </div>
              {r.tags.length > 0 && <div className="flex flex-wrap gap-1.5">{r.tags.map((t) => <span key={t} className="rounded-full bg-ink/[0.05] px-2 py-0.5 font-mono text-[11px] text-muted-foreground">#{t}</span>)}</div>}
              <BenchHistory runs={r.bench_runs} title="How it was confirmed" />
              {owned ? (
                <Button asChild data-testid="specimen-open-record">
                  <Link to={`/records?open=${r.id}`} viewTransition>Open in my records <ArrowRight className="ml-1.5 h-4 w-4" /></Link>
                </Button>
              ) : (
                <p className="text-xs text-muted-foreground" data-testid="specimen-readonly-note">Read-only label view. Notes and private details stay with the owner.</p>
              )}
            </div>
          </Panel>
        )}
      </div>
    </div>
  );
}
