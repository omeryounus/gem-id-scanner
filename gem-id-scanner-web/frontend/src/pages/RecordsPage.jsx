import { useEffect, useMemo, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { BenchHistory, LatestRunChip } from "@/components/BenchHistory";
import { Plus, Star, MapPin, Scale, Pencil, Trash2, Search, BadgeCheck, CircleHelp, CircleAlert, Smartphone, Download, FileSpreadsheet, Printer, List, Map as MapIcon } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu";
import { RecordsMap } from "@/components/RecordsMap";
import { downloadCSV } from "@/lib/exportRecords";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from "@/components/ui/alert-dialog";
import { PageHeader, Panel, Eyebrow, SourceBadge } from "@/components/Bits";
import { RecordDialog } from "@/components/RecordDialog";
import { useDeleteRecord, useMinerals, useRecords, useSaveRecord, useUsage } from "@/lib/queries";
import { fileUrl } from "@/lib/api";
import { cn } from "@/lib/utils";

export const EMPTY_COPY = "Saves that exist only on an iPhone stay on that iPhone until the iOS app posts them.";

const STATUS = {
  confirmed: { label: "Confirmed", Icon: BadgeCheck, cls: "text-emerald-300 border-emerald-400/30 bg-emerald-400/10" },
  unconfirmed: { label: "Unconfirmed", Icon: CircleHelp, cls: "text-muted-foreground border-border" },
  disputed: { label: "Disputed", Icon: CircleAlert, cls: "text-red-300 border-red-400/30 bg-red-400/10" },
};

const RecordCard = ({ r, onEdit, onDelete, onFav, highlight }) => {
  const s = STATUS[r.confirmed] || STATUS.unconfirmed;
  const [history, setHistory] = useState(false);
  const { data: minerals = [] } = useMinerals();
  const species = minerals.find((m) => m.id === r.mineral_id)?.name;
  return (
    <Panel id={`record-${r.id}`} className={cn("rise group flex scroll-mt-24 gap-4 p-4 transition-colors hover:border-ink/20", highlight && "border-primary ring-2 ring-primary/30")} data-testid={`record-card-${r.id}`}>
      {r.photo_path ? (
        <img src={fileUrl(r.photo_path)} alt="" className="h-20 w-20 shrink-0 rounded-lg object-cover" />
      ) : (
        <div className="grid-bench grid h-20 w-20 shrink-0 place-items-center rounded-lg border border-border font-display text-2xl text-primary">{r.name[0]}</div>
      )}
      <div className="min-w-0 flex-1">
        <div className="flex items-start gap-2">
          <div className="min-w-0 flex-1">
            <div className="truncate font-display text-lg font-medium" data-testid={`record-name-${r.id}`}>{r.name}</div>
            {r.mineral_id && <Link to={`/gemstones/${r.mineral_id}`} viewTransition className="font-mono text-[11px] text-muted-foreground hover:text-primary">{species || r.mineral_id}</Link>}
          </div>
          <button onClick={() => onFav(r)} aria-pressed={r.favorite} aria-label="Toggle favorite" data-testid={`record-favorite-${r.id}`} className="grid h-8 w-8 place-items-center rounded-full transition-transform hover:scale-110 active:scale-90">
            <Star className={cn("h-4 w-4", r.favorite ? "fill-primary text-primary" : "text-muted-foreground")} />
          </button>
        </div>
        <div className="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-muted-foreground">
          <span className={cn("inline-flex items-center gap-1 rounded-md border px-1.5 py-0.5 font-mono text-[10px] uppercase", s.cls)} data-testid={`record-status-${r.id}`}><s.Icon className="h-3 w-3" />{s.label}</span>
          <span>{r.form}</span>
          {r.weight != null && <span className="inline-flex items-center gap-1 font-mono"><Scale className="h-3 w-3" />{r.weight} {r.weight_unit}</span>}
          {r.location && <span className="inline-flex items-center gap-1"><MapPin className="h-3 w-3" />{r.location}</span>}
          <SourceBadge source={r.source} />
          <LatestRunChip runs={r.bench_runs} expanded={history} onClick={() => setHistory(!history)} testid={`record-bench-chip-${r.id}`} />
        </div>
        {history && <BenchHistory runs={r.bench_runs} className="rise mt-3 rounded-lg border border-border p-3" />}
        {r.notes && <p className="mt-2 line-clamp-2 text-sm text-muted-foreground">{r.notes}</p>}
        <div className="mt-2 flex flex-wrap items-center gap-1.5">
          {r.tags.map((t) => <span key={t} className="rounded-full bg-ink/[0.05] px-2 py-0.5 font-mono text-[10.5px] text-muted-foreground">#{t}</span>)}
          <div className="ml-auto flex gap-1 opacity-100 transition-opacity md:opacity-0 md:group-hover:opacity-100 md:group-focus-within:opacity-100">
            <Button size="icon" variant="ghost" className="h-8 w-8" onClick={() => onEdit(r)} aria-label="Edit" data-testid={`record-edit-${r.id}`}><Pencil className="h-3.5 w-3.5" /></Button>
            <Button size="icon" variant="ghost" className="h-8 w-8 hover:text-red-400" onClick={() => onDelete(r)} aria-label="Delete" data-testid={`record-delete-${r.id}`}><Trash2 className="h-3.5 w-3.5" /></Button>
          </div>
        </div>
      </div>
    </Panel>
  );
};

const Empty = ({ onNew }) => (
  <div className="grid-bench flex flex-col items-start gap-5 rounded-xl border border-dashed border-border p-10 md:p-14" data-testid="records-empty-state">
    <Smartphone className="h-8 w-8 text-primary" />
    <p className="max-w-xl font-display text-xl leading-snug sm:text-2xl" data-testid="records-empty-copy">{EMPTY_COPY}</p>
    <Button onClick={onNew} data-testid="records-empty-new"><Plus className="mr-1.5 h-4 w-4" /> Save your first specimen</Button>
  </div>
);

export default function RecordsPage() {
  const { data = [], isLoading } = useRecords();
  const { data: u } = useUsage();
  const save = useSaveRecord();
  const del = useDeleteRecord();
  const [edit, setEdit] = useState(null);
  const [toDelete, setToDelete] = useState(null);
  const [q, setQ] = useState("");
  const [view, setView] = useState("all");
  const [tag, setTag] = useState(null);

  const tags = useMemo(() => [...new Set(data.flatMap((r) => r.tags))], [data]);
  const shown = data.filter(
    (r) =>
      (view === "all" || (view === "favorites" ? r.favorite : r.confirmed === "confirmed")) &&
      (!tag || r.tags.includes(tag)) &&
      (!q || `${r.name} ${r.notes} ${r.location}`.toLowerCase().includes(q.toLowerCase())),
  );
  const full = u && u.saved >= u.save_limit;
  const fav = (r) => save.mutate({ id: r.id, favorite: !r.favorite });
  const { data: minerals = [] } = useMinerals();
  const navigate = useNavigate();
  const [mode, setMode] = useState("list");
  const [params] = useSearchParams();
  const focus = params.get("open");
  useEffect(() => {
    if (focus && data.some((r) => r.id === focus)) document.getElementById(`record-${focus}`)?.scrollIntoView({ behavior: "smooth", block: "center" });
  }, [focus, data]);

  return (
    <div className="rise">
      <PageHeader eyebrow="Station 04 · Records" title="Your collection" testid="records-header">
        {u && (
          <div className="flex items-center gap-3 rounded-full border border-border bg-card px-4 py-2" data-testid="records-limit-indicator">
            <div className="h-1.5 w-24 overflow-hidden rounded-full bg-ink/10"><div className="h-full bg-primary transition-[width]" style={{ width: `${(u.saved / u.save_limit) * 100}%` }} /></div>
            <span className="font-mono text-xs tabular-nums text-muted-foreground">{u.saved} / {u.save_limit} saved</span>
          </div>
        )}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="outline" disabled={!data.length} data-testid="records-export-button"><Download className="mr-1.5 h-4 w-4" /> Export</Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-56">
            <DropdownMenuItem onSelect={() => { downloadCSV(data, minerals); toast.success(`Exported ${data.length} records`); }} data-testid="records-export-csv">
              <FileSpreadsheet className="mr-2 h-4 w-4 text-primary" /> Spreadsheet (CSV)
            </DropdownMenuItem>
            <DropdownMenuItem onSelect={() => navigate("/records/labels", { viewTransition: true })} data-testid="records-export-labels">
              <Printer className="mr-2 h-4 w-4 text-primary" /> Printable specimen labels
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
        <Button onClick={() => setEdit({})} disabled={full} data-testid="records-new-button"><Plus className="mr-1.5 h-4 w-4" /> New record</Button>
      </PageHeader>
      {full && <Panel className="mb-6 border-primary/40 bg-primary/[0.06] p-4 text-sm text-primary" data-testid="records-limit-reached">All 20 save slots are used — the same cap as the phone. Delete a record to free a slot.</Panel>}
      {isLoading ? (
        <div className="grid gap-3 md:grid-cols-2">{[...Array(4)].map((_, i) => <Skeleton key={i} className="h-28 rounded-xl" />)}</div>
      ) : !data.length ? (
        <Empty onNew={() => setEdit({})} />
      ) : (
        <>
          <div className="mb-5 flex flex-wrap items-center gap-2">
            <div className="relative min-w-[200px] flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search notes, labels, places…" className="h-10 bg-card pl-9" type="search" data-testid="records-search-input" />
            </div>
            <div className="flex rounded-full border border-border bg-card p-1" role="group" aria-label="Layout">
              {[["list", List], ["map", MapIcon]].map(([v, I]) => (
                <button key={v} onClick={() => setMode(v)} aria-pressed={mode === v} data-testid={`records-mode-${v}`} className={cn("inline-flex items-center gap-1 rounded-full px-3 py-1 text-xs capitalize transition-colors", mode === v ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:text-foreground")}><I className="h-3.5 w-3.5" />{v}</button>
              ))}
            </div>
            <div className="flex rounded-full border border-border bg-card p-1" role="group">
              {["all", "favorites", "confirmed"].map((v) => (
                <button key={v} onClick={() => setView(v)} aria-pressed={view === v} data-testid={`records-filter-${v}`} className={cn("rounded-full px-3 py-1 text-xs capitalize transition-colors", view === v ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:text-foreground")}>{v}</button>
              ))}
            </div>
          </div>
          {tags.length > 0 && (
            <div className="mb-5 flex flex-wrap items-center gap-1.5">
              <Eyebrow className="mr-1">Tags</Eyebrow>
              {tags.map((t) => (
                <button key={t} onClick={() => setTag(tag === t ? null : t)} aria-pressed={tag === t} data-testid={`records-tag-${t}`} className={cn("rounded-full border px-2.5 py-0.5 font-mono text-[11px] transition-colors", tag === t ? "border-primary bg-primary/15 text-primary" : "border-border text-muted-foreground hover:text-foreground")}>#{t}</button>
              ))}
            </div>
          )}
          {mode === "map" ? (
            <RecordsMap records={shown} />
          ) : (
            <div className="grid gap-3 md:grid-cols-2" data-testid="records-list">
              {shown.map((r) => <RecordCard key={r.id} r={r} onEdit={setEdit} onDelete={setToDelete} onFav={fav} highlight={r.id === focus} />)}
            </div>
          )}
          {!shown.length && <p className="py-10 text-center text-sm text-muted-foreground">No records match.</p>}
        </>
      )}
      <RecordDialog open={!!edit} onOpenChange={(o) => !o && setEdit(null)} initial={edit} />
      <AlertDialog open={!!toDelete} onOpenChange={(o) => !o && setToDelete(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Delete “{toDelete?.name}”?</AlertDialogTitle>
            <AlertDialogDescription>This frees one of your 20 save slots. The photo stays in your gallery.</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel data-testid="record-delete-cancel">Keep</AlertDialogCancel>
            <AlertDialogAction
              data-testid="record-delete-confirm"
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              onClick={() => del.mutate(toDelete.id, { onSuccess: () => toast.success("Record deleted") })}
            >
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
