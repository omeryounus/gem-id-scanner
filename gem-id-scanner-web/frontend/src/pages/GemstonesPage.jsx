import { useEffect, useMemo, useRef, useState } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { Search, SlidersHorizontal, X, Columns2, LayoutGrid, Rows3, Plus, Check } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Slider } from "@/components/ui/slider";
import { Sheet, SheetContent, SheetHeader, SheetTitle, SheetTrigger } from "@/components/ui/sheet";
import { Skeleton } from "@/components/ui/skeleton";
import { Eyebrow, HardnessBar, PageHeader, Swatch } from "@/components/Bits";
import { useMinerals } from "@/lib/queries";
import { CATEGORIES, COLORS, hardnessLabel } from "@/lib/catalog";
import { cn } from "@/lib/utils";

function useFilters() {
  const [sp, setSp] = useSearchParams();
  const f = {
    q: sp.get("q") || "",
    cat: sp.get("cat") || "",
    colors: (sp.get("colors") || "").split(",").filter(Boolean),
    h: (sp.get("h") || "1-10").split("-").map(Number),
    view: sp.get("view") || "grid",
  };
  const set = (patch) => {
    const next = new URLSearchParams(sp);
    Object.entries(patch).forEach(([k, v]) => {
      const val = Array.isArray(v) ? (k === "h" ? v.join("-") : v.join(",")) : v;
      if (!val || val === "1-10" || (k === "view" && val === "grid")) next.delete(k);
      else next.set(k, val);
    });
    setSp(next, { replace: true });
  };
  return [f, set];
}

const Chip = ({ active, children, ...p }) => (
  <button
    className={cn(
      "inline-flex h-8 items-center gap-1.5 rounded-full border px-3 text-xs transition-colors",
      active ? "border-primary bg-primary/15 text-primary" : "border-border text-muted-foreground hover:border-ink/25 hover:text-foreground",
    )}
    aria-pressed={active}
    {...p}
  >
    {children}
  </button>
);

function Filters({ f, set }) {
  return (
    <div className="space-y-8">
      <div>
        <Eyebrow className="mb-3">Category</Eyebrow>
        <div className="flex flex-wrap gap-1.5">
          <Chip active={!f.cat} onClick={() => set({ cat: "" })} data-testid="filter-category-all">All</Chip>
          {CATEGORIES.map((c) => (
            <Chip key={c} active={f.cat === c} onClick={() => set({ cat: f.cat === c ? "" : c })} data-testid={`filter-category-${c.toLowerCase().replace(" ", "-")}`}>
              {c}
            </Chip>
          ))}
        </div>
      </div>
      <div>
        <Eyebrow className="mb-3">Colour</Eyebrow>
        <div className="flex flex-wrap gap-2">
          {COLORS.map((c) => {
            const on = f.colors.includes(c);
            return (
              <button
                key={c}
                title={c}
                aria-pressed={on}
                aria-label={c}
                data-testid={`filter-color-${c}`}
                onClick={() => set({ colors: on ? f.colors.filter((x) => x !== c) : [...f.colors, c] })}
                className={cn("grid h-8 w-8 place-items-center rounded-full ring-offset-2 ring-offset-background transition-[box-shadow,transform] hover:scale-110", on && "ring-2 ring-primary")}
              >
                <Swatch color={c} size={24} />
              </button>
            );
          })}
        </div>
      </div>
      <div>
        <div className="mb-3 flex items-center justify-between">
          <Eyebrow>Mohs hardness</Eyebrow>
          <span className="font-mono text-xs text-primary" data-testid="filter-hardness-value">
            {f.h[0]} – {f.h[1]}
          </span>
        </div>
        <Slider
          min={1}
          max={10}
          step={0.5}
          minStepsBetweenThumbs={0}
          value={f.h}
          onValueChange={(v) => set({ h: v })}
          thumbLabels={["Minimum hardness", "Maximum hardness"]}
          data-testid="filter-hardness-slider"
        />
        <div className="mt-2 flex justify-between font-mono text-[10px] text-muted-foreground">
          {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10].map((n) => <span key={n}>{n}</span>)}
        </div>
      </div>
    </div>
  );
}

const MineralCard = ({ m, i, selected, onToggle, list }) => (
  <div
    className={cn("card-cq rise group relative rounded-xl border bg-card/70 transition-[border-color,transform] duration-200 hover:-translate-y-0.5 hover:border-primary/40", selected ? "border-primary/60" : "border-border")}
    style={{ animationDelay: `${Math.min(i, 20) * 18}ms` }}
  >
    <Link to={`/gemstones/${m.id}`} viewTransition data-testid={`gemstone-card-${m.id}`} className={cn("block p-4", list && "flex items-center gap-4 py-3")}>
      <div className={cn("flex gap-1", list ? "w-20 shrink-0" : "mb-4")}>
        {m.colors.slice(0, 5).map((c) => <Swatch key={c} color={c} size={list ? 12 : 16} />)}
      </div>
      <div className={cn("min-w-0", list && "flex flex-1 items-center gap-4")}>
        <div className={cn("min-w-0", list && "w-48 shrink-0")}>
          <div className="truncate font-display text-lg font-medium leading-tight">{m.name}</div>
          <div className="truncate font-mono text-xs text-muted-foreground">{m.formula}</div>
        </div>
        <div className={cn(list ? "hidden flex-1 sm:block" : "mt-4")}>
          <div className="mb-1.5 flex items-center justify-between font-mono text-[10.5px] text-muted-foreground">
            <span>H {hardnessLabel(m.hardness)}</span>
            <span className="cq-hide">{m.category}</span>
          </div>
          <HardnessBar range={m.hardness} />
        </div>
      </div>
    </Link>
    <button
      onClick={() => onToggle(m.id)}
      aria-pressed={selected}
      aria-label={`Add ${m.name} to compare`}
      data-testid={`gemstone-compare-toggle-${m.id}`}
      className={cn(
        "absolute right-3 top-3 grid h-7 w-7 place-items-center rounded-full border transition-[opacity,background-color]",
        selected ? "border-primary bg-primary text-primary-foreground" : "border-border bg-background/70 text-muted-foreground opacity-100 hover:text-primary md:opacity-0 md:group-hover:opacity-100",
      )}
    >
      {selected ? <Check className="h-3.5 w-3.5" /> : <Plus className="h-3.5 w-3.5" />}
    </button>
  </div>
);

export default function GemstonesPage() {
  const { data: minerals, isLoading } = useMinerals();
  const [f, set] = useFilters();
  const [pick, setPick] = useState([]);
  const navigate = useNavigate();
  const searchRef = useRef(null);

  useEffect(() => {
    const k = (e) => {
      if (e.key === "/" && document.activeElement.tagName !== "INPUT") {
        e.preventDefault();
        searchRef.current?.focus();
      }
    };
    window.addEventListener("keydown", k);
    return () => window.removeEventListener("keydown", k);
  }, []);

  const results = useMemo(() => {
    const q = f.q.trim().toLowerCase();
    return (minerals || []).filter(
      (m) =>
        (!q || `${m.name} ${m.formula} ${m.category} ${m.streak}`.toLowerCase().includes(q)) &&
        (!f.cat || m.category === f.cat) &&
        (!f.colors.length || f.colors.some((c) => m.colors.includes(c))) &&
        m.hardness[1] >= f.h[0] &&
        m.hardness[0] <= f.h[1],
    );
  }, [minerals, f.q, f.cat, f.colors, f.h]);

  const active = (f.cat ? 1 : 0) + f.colors.length + (f.h[0] !== 1 || f.h[1] !== 10 ? 1 : 0);
  const toggle = (id) => setPick((p) => (p.includes(id) ? p.filter((x) => x !== id) : [...p, id].slice(-2)));
  const list = f.view === "list";

  return (
    <div className="rise">
      <PageHeader eyebrow={`Station 02 · Catalog · ${minerals?.length || 60} species`} title="Gemstones & minerals" testid="gemstones-header" />
      <div className="grid gap-8 lg:grid-cols-[260px_1fr]">
        <aside className="hidden lg:block">
          <div className="sticky top-24"><Filters f={f} set={set} /></div>
        </aside>
        <div className="min-w-0">
          <div className="mb-5 flex flex-wrap items-center gap-2">
            <div className="relative min-w-[200px] flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                ref={searchRef}
                value={f.q}
                onChange={(e) => set({ q: e.target.value })}
                placeholder="Search name, formula, streak…"
                className="h-10 bg-card pl-9 pr-9"
                data-testid="gemstone-search-input"
                type="search"
              />
              <kbd className="absolute right-3 top-1/2 hidden -translate-y-1/2 rounded border border-border px-1.5 font-mono text-[10px] text-muted-foreground md:block">/</kbd>
            </div>
            <Sheet>
              <SheetTrigger asChild>
                <Button variant="outline" className="h-10 lg:hidden" data-testid="gemstone-filters-open">
                  <SlidersHorizontal className="mr-1.5 h-4 w-4" /> Filters {active > 0 && <span className="ml-1 rounded-full bg-primary px-1.5 text-[10px] text-primary-foreground">{active}</span>}
                </Button>
              </SheetTrigger>
              <SheetContent side="bottom" className="max-h-[85dvh] overflow-y-auto rounded-t-2xl">
                <SheetHeader className="mb-6"><SheetTitle>Filters</SheetTitle></SheetHeader>
                <Filters f={f} set={set} />
              </SheetContent>
            </Sheet>
            <div className="flex h-10 rounded-md border border-border p-1" role="group" aria-label="View">
              {[["grid", LayoutGrid], ["list", Rows3]].map(([v, I]) => (
                <button key={v} onClick={() => set({ view: v })} aria-pressed={f.view === v} aria-label={`${v} view`} data-testid={`gemstone-view-${v}`} className={cn("grid w-8 place-items-center rounded transition-colors", f.view === v ? "bg-primary/15 text-primary" : "text-muted-foreground hover:text-foreground")}>
                  <I className="h-4 w-4" />
                </button>
              ))}
            </div>
          </div>
          <div className="mb-4 flex items-center gap-3 font-mono text-xs text-muted-foreground">
            <span data-testid="gemstone-results-count">{results.length} results</span>
            {active > 0 && (
              <button onClick={() => set({ cat: "", colors: [], h: [1, 10] })} className="inline-flex items-center gap-1 text-primary hover:underline" data-testid="gemstone-clear-filters">
                <X className="h-3 w-3" /> Clear {active} filter{active > 1 && "s"}
              </button>
            )}
          </div>
          {isLoading ? (
            <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-4">{[...Array(12)].map((_, i) => <Skeleton key={i} className="h-36 rounded-xl" />)}</div>
          ) : results.length ? (
            <div className={cn("grid gap-3", list ? "grid-cols-1" : "grid-cols-2 md:grid-cols-3 xl:grid-cols-4")} data-testid="gemstone-results">
              {results.map((m, i) => <MineralCard key={m.id} m={m} i={i} list={list} selected={pick.includes(m.id)} onToggle={toggle} />)}
            </div>
          ) : (
            <div className="rounded-xl border border-dashed border-border p-12 text-center text-muted-foreground" data-testid="gemstone-empty">
              No species match these filters.
            </div>
          )}
        </div>
      </div>
      {pick.length > 0 && (
        <div className="rise fixed inset-x-4 bottom-[76px] z-40 mx-auto flex max-w-md items-center gap-3 rounded-full border border-primary/40 bg-popover/95 p-2 pl-5 shadow-2xl backdrop-blur-xl md:bottom-6" data-testid="compare-tray">
          <Columns2 className="h-4 w-4 text-primary" />
          <span className="flex-1 truncate text-sm">
            {pick.map((id) => minerals.find((m) => m.id === id)?.name).join(" vs ")}
            {pick.length === 1 && <span className="text-muted-foreground"> · pick one more</span>}
          </span>
          <button onClick={() => setPick([])} className="text-muted-foreground hover:text-foreground" aria-label="Clear compare" data-testid="compare-tray-clear"><X className="h-4 w-4" /></button>
          <Button size="sm" className="rounded-full" disabled={pick.length < 2} onClick={() => navigate(`/compare?a=${pick[0]}&b=${pick[1]}`, { viewTransition: true })} data-testid="compare-tray-go">
            Compare
          </Button>
        </div>
      )}
    </div>
  );
}
