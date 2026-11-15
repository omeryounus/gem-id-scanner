import { useState } from "react";
import { Link } from "react-router-dom";
import { ImageOff, ArrowUpRight, ScanLine } from "lucide-react";
import { Dialog, DialogContent, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Skeleton } from "@/components/ui/skeleton";
import { PageHeader, SourceBadge, Eyebrow } from "@/components/Bits";
import { usePhotos } from "@/lib/queries";
import { fileUrl } from "@/lib/api";
import { cn } from "@/lib/utils";

const FILTERS = [["all", "All"], ["iphone", "iPhone"], ["android", "Android"], ["web", "Web"]];
const fmt = (iso) => new Date(iso).toLocaleDateString(undefined, { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });

const PhotoCard = ({ p, i, onOpen }) => (
  <button
    onClick={() => onOpen(p)}
    data-testid={`gallery-photo-${p.id}`}
    className="rise group relative overflow-hidden rounded-xl border border-border bg-card text-left transition-[border-color] hover:border-primary/40"
    style={{ animationDelay: `${Math.min(i, 16) * 25}ms` }}
  >
    <img src={fileUrl(p.storage_path)} alt={p.label || "Specimen"} loading="lazy" className="aspect-[4/5] w-full object-cover transition-transform duration-500 group-hover:scale-[1.04]" />
    <SourceBadge source={p.source} className="absolute left-2.5 top-2.5 bg-black/50" data-testid={`gallery-source-badge-${p.id}`} />
    <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/90 via-black/50 to-transparent p-3 pt-10 text-white">
      <div className="truncate text-sm font-medium">{p.label || "Unlabelled"}</div>
      <div className="font-mono text-[10px] text-white/60">
        {fmt(p.created_at)}{p.confidence != null && ` · ${Math.round(p.confidence * 100)}%`}
      </div>
    </div>
  </button>
);

export default function GalleryPage() {
  const { data = [], isLoading } = usePhotos();
  const [src, setSrc] = useState("all");
  const [open, setOpen] = useState(null);
  const shown = src === "all" ? data : data.filter((p) => p.source === src);
  const count = (s) => (s === "all" ? data.length : data.filter((p) => p.source === s).length);

  return (
    <div className="rise">
      <PageHeader eyebrow="Station 03 · Gallery" title="Specimen photos" testid="gallery-header">
        <div className="flex rounded-full border border-border bg-card p-1" role="group" aria-label="Source">
          {FILTERS.map(([v, l]) => (
            <button key={v} onClick={() => setSrc(v)} aria-pressed={src === v} data-testid={`gallery-filter-${v}`} className={cn("rounded-full px-3 py-1 text-xs transition-colors", src === v ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:text-foreground")}>
              {l} <span className="font-mono opacity-60">{count(v)}</span>
            </button>
          ))}
        </div>
      </PageHeader>
      {isLoading ? (
        <div className="grid grid-cols-2 gap-3 md:grid-cols-4">{[...Array(8)].map((_, i) => <Skeleton key={i} className="aspect-[4/5] rounded-xl" />)}</div>
      ) : shown.length ? (
        <div className="grid grid-cols-2 gap-3 md:grid-cols-3 xl:grid-cols-5" data-testid="gallery-grid">
          {shown.map((p, i) => <PhotoCard key={p.id} p={p} i={i} onOpen={setOpen} />)}
        </div>
      ) : (
        <div className="grid-bench flex flex-col items-start gap-4 rounded-xl border border-dashed border-border p-10" data-testid="gallery-empty">
          <ImageOff className="h-8 w-8 text-primary" />
          <div>
            <p className="font-display text-xl">No photos{src !== "all" && ` from ${FILTERS.find((f) => f[0] === src)[1]}`} yet</p>
            <p className="mt-1 max-w-md text-sm text-muted-foreground">Web scans land here automatically. Phone photos appear once the iOS or Android app posts them.</p>
          </div>
          <Button asChild size="sm"><Link to="/identify" viewTransition data-testid="gallery-empty-identify"><ScanLine className="mr-1.5 h-4 w-4" /> Scan a specimen</Link></Button>
        </div>
      )}
      <Dialog open={!!open} onOpenChange={(o) => !o && setOpen(null)}>
        <DialogContent className="max-w-3xl p-0" data-testid="gallery-lightbox">
          {open && (
            <div className="grid md:grid-cols-[1.4fr_1fr]">
              <img src={fileUrl(open.storage_path)} alt={open.label || "Specimen"} className="max-h-[70dvh] w-full object-contain bg-black md:rounded-l-lg" />
              <div className="space-y-4 p-6">
                <SourceBadge source={open.source} data-testid="gallery-lightbox-source" />
                <DialogTitle className="font-display text-2xl">{open.label || "Unlabelled specimen"}</DialogTitle>
                <div className="space-y-1 font-mono text-xs text-muted-foreground">
                  <div>{fmt(open.created_at)}</div>
                  <div>{(open.size / 1024).toFixed(0)} KB · {open.content_type}</div>
                </div>
                {open.analysis_id && (
                  <div>
                    <Eyebrow className="mb-2">Identification run</Eyebrow>
                    <Button asChild size="sm"><Link to={`/analysis/${open.analysis_id}`} viewTransition data-testid="gallery-lightbox-analysis">Open analysis <ArrowUpRight className="ml-1 h-3.5 w-3.5" /></Link></Button>
                  </div>
                )}
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
