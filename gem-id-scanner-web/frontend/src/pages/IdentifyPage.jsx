import { useCallback, useEffect, useRef, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { Camera, ImageUp, ClipboardPaste, Loader2, ArrowUpRight, CloudOff } from "lucide-react";
import { toast } from "sonner";
import { Button } from "@/components/ui/button";
import { Eyebrow, PageHeader, Panel, Pips } from "@/components/Bits";
import { useAnalyses, useIdentify, useUsage } from "@/lib/queries";
import { prepareImage } from "@/lib/image";
import { errMsg, fileUrl } from "@/lib/api";
import { firebaseConfigured } from "@/lib/firebaseApp";
import { primeDeviceModel } from "@/lib/hybridIdentify";
import { useLocalPhoto } from "@/lib/localPhotos";
import { cn } from "@/lib/utils";

const STEPS = firebaseConfigured
  ? ["Reading pixels", "Measuring colour", "Firebase AI Logic · Gemini Nano first", "Cloud Gemini if that rank is unsure"]
  : ["Reading pixels", "Measuring colour shortlist", "Colour shortlist only", "Ranking candidates"];

const Scanning = ({ preview }) => {
  const [step, setStep] = useState(0);
  useEffect(() => {
    const t = setInterval(() => setStep((s) => Math.min(s + 1, STEPS.length - 1)), 1400);
    return () => clearInterval(t);
  }, []);
  return (
    <div className="relative h-full w-full overflow-hidden rounded-xl" data-testid="identify-scanning">
      <img src={preview} alt="Specimen being scanned" className="h-full w-full object-cover opacity-70" />
      <div className="scanline" />
      <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-black/90 to-transparent p-5">
        <div className="flex items-center gap-2 font-mono text-xs text-primary">
          <Loader2 className="h-3.5 w-3.5 animate-spin" /> {STEPS[step]}…
        </div>
      </div>
    </div>
  );
};

function Dropzone({ disabled, onFile }) {
  const [over, setOver] = useState(false);
  const input = useRef(null);
  const camera = useRef(null);
  const pick = (f) => f && onFile(f);
  return (
    <div
      role="button"
      tabIndex={0}
      aria-disabled={disabled}
      data-testid="identify-upload-dropzone"
      onKeyDown={(e) => (e.key === "Enter" || e.key === " ") && !disabled && input.current.click()}
      onClick={() => !disabled && input.current.click()}
      onDragOver={(e) => {
        e.preventDefault();
        !disabled && setOver(true);
      }}
      onDragLeave={() => setOver(false)}
      onDrop={(e) => {
        e.preventDefault();
        setOver(false);
        !disabled && pick(e.dataTransfer.files?.[0]);
      }}
      className={cn(
        "grid-bench group relative flex h-full w-full cursor-pointer flex-col items-center justify-center gap-5 rounded-xl border-2 border-dashed border-border p-8 text-center transition-[border-color,background-color] duration-200",
        over ? "border-primary bg-primary/[0.06]" : "hover:border-primary/50",
        disabled && "cursor-not-allowed opacity-50",
      )}
    >
      <span className="grid h-16 w-16 place-items-center rounded-2xl border border-primary/30 bg-primary/10 text-primary transition-transform duration-300 group-hover:-translate-y-1">
        <ImageUp className="h-7 w-7" />
      </span>
      <div className="space-y-1.5">
        <p className="font-display text-xl font-medium">{over ? "Release to scan" : "Drop a specimen photo"}</p>
        <p className="text-sm text-muted-foreground">or click to browse · paste with ⌘V · JPEG, PNG, WEBP up to 12 MB</p>
      </div>
      <div className="flex gap-2" onClick={(e) => e.stopPropagation()}>
        <Button size="sm" disabled={disabled} onClick={() => input.current.click()} data-testid="identify-browse-button">
          <ImageUp className="mr-1.5 h-4 w-4" /> Choose photo
        </Button>
        <Button size="sm" variant="outline" disabled={disabled} onClick={() => camera.current.click()} className="md:hidden" data-testid="identify-camera-button">
          <Camera className="mr-1.5 h-4 w-4" /> Camera
        </Button>
      </div>
      <input ref={input} type="file" accept="image/jpeg,image/png,image/webp" hidden data-testid="identify-file-input" onChange={(e) => pick(e.target.files?.[0])} />
      <input ref={camera} type="file" accept="image/*" capture="environment" hidden onChange={(e) => pick(e.target.files?.[0])} />
    </div>
  );
}

const Tips = () => (
  <Panel className="p-5">
    <Eyebrow className="mb-3">Bench tips</Eyebrow>
    <ul className="space-y-2.5 text-sm text-muted-foreground">
      <li>Shoot on a neutral grey or white card in daylight — colour drives the shortlist.</li>
      <li>Fill the frame; keep a fresh, unweathered face toward the lens.</li>
      <li>Results are capped at 96%. A photo can never prove hardness or streak.</li>
    </ul>
  </Panel>
);

const RecentPhoto = ({ analysis }) => {
  const local = useLocalPhoto(analysis.photo_path ? null : analysis.id);
  const src = analysis.photo_path ? fileUrl(analysis.photo_path) : local;
  if (!src) return <div className="grid-bench aspect-square w-full" />;
  return <img src={src} alt="" loading="lazy" className="aspect-square w-full object-cover transition-transform duration-500 group-hover:scale-105" />;
};

const Recent = () => {
  const { data = [] } = useAnalyses();
  if (!data.length) return null;
  return (
    <section className="mt-12">
      <Eyebrow className="mb-4">Recent runs</Eyebrow>
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
        {data.map((a) => (
          <Link key={a.id} to={`/analysis/${a.id}`} viewTransition data-testid={`recent-analysis-${a.id}`} className="group overflow-hidden rounded-lg border border-border bg-card transition-colors hover:border-primary/40">
            <RecentPhoto analysis={a} />
            <div className="p-2.5">
              <div className="truncate text-sm font-medium">{a.top?.name || "Inconclusive"}</div>
              <div className="font-mono text-[10px] uppercase text-muted-foreground">{a.band} · {a.engine}</div>
            </div>
          </Link>
        ))}
      </div>
    </section>
  );
};

export default function IdentifyPage() {
  const navigate = useNavigate();
  const { data: u } = useUsage();
  const identify = useIdentify();
  const [preview, setPreview] = useState(null);
  const out = u && u.scans_today >= u.scan_limit;
  const busy = identify.isPending;

  const run = useCallback(
    async (file) => {
      if (busy || out) return;
      primeDeviceModel();
      try {
        const img = await prepareImage(file);
        setPreview(URL.createObjectURL(img));
        const a = await identify.mutateAsync(img);
        navigate(`/analysis/${a.id}`, { viewTransition: true });
      } catch (e) {
        setPreview(null);
        toast.error(e.message && !e.response ? e.message : errMsg(e, "Scan failed"));
      }
    },
    [busy, out, identify, navigate],
  );

  useEffect(() => {
    const onPaste = (e) => {
      const f = [...(e.clipboardData?.files || [])].find((x) => x.type.startsWith("image/"));
      if (f) run(f);
    };
    window.addEventListener("paste", onPaste);
    return () => window.removeEventListener("paste", onPaste);
  }, [run]);

  return (
    <div className="rise">
      <PageHeader eyebrow="Station 01 · Identify" title="What's on the bench?" testid="identify-header">
        {u && (
          <div className="flex items-center gap-3 rounded-full border border-border bg-card px-4 py-2" data-testid="identify-quota-meter">
            <Pips used={u.scans_today} total={u.scan_limit} />
            <span className="font-mono text-xs tabular-nums text-muted-foreground">{u.scan_limit - u.scans_today} scans left today</span>
          </div>
        )}
      </PageHeader>
      <div className="grid gap-6 lg:grid-cols-[1fr_320px]">
        <div className="aspect-[4/3] max-h-[560px] w-full lg:aspect-auto lg:h-[520px]">
          {busy && preview ? <Scanning preview={preview} /> : <Dropzone disabled={out || busy} onFile={run} />}
        </div>
        <div className="space-y-4">
          {out && (
            <Panel className="border-primary/40 bg-primary/[0.06] p-5" data-testid="identify-limit-reached">
              <p className="font-display text-lg font-medium text-primary">Daily scans used</p>
              <p className="mt-1 text-sm text-muted-foreground">You've run all 5 scans for today, same as the phone. The counter resets at midnight UTC. The catalog stays open.</p>
              <Button asChild variant="outline" size="sm" className="mt-4">
                <Link to="/gemstones" viewTransition>Browse catalog <ArrowUpRight className="ml-1 h-3.5 w-3.5" /></Link>
              </Button>
            </Panel>
          )}
          {!firebaseConfigured && (
            <Panel className="p-5" data-testid="identify-vision-offline">
              <div className="flex items-center gap-2 text-sm font-medium"><CloudOff className="h-4 w-4 text-primary" /> Firebase AI Logic is not configured</div>
              <p className="mt-1 text-sm text-muted-foreground">Scans use the colour shortlist until this browser has the Firebase web config. A configured Chrome scan asks Gemini Nano first and sends the photo to Gemini only when that rank is unsure.</p>
            </Panel>
          )}
          {firebaseConfigured && (
            <Panel className="p-5" data-testid="identify-hybrid-status">
              <div className="text-sm font-medium">Hybrid identification</div>
              <p className="mt-1 text-sm text-muted-foreground">Chrome asks Gemini Nano to rank the colour brief. The photo goes to Gemini only when that rank is missing or below the Remote Config threshold.</p>
            </Panel>
          )}
          <Tips />
          <Panel className="p-5">
            <Eyebrow className="mb-2">Privacy</Eyebrow>
            <p className="text-sm text-muted-foreground">
              {firebaseConfigured
                ? "A confident Gemini Nano rank stays in this browser. The photo is sent to Gemini through Firebase AI Logic only when that rank is unsure or Nano is unavailable. This page never holds a model API key."
                : "Firebase is not configured, so this scan uploads the photo to the Field Bench server and ranks it by colour only. No model sees it, and this page never holds a model API key."}{" "}
              <Link to="/privacy" viewTransition className="text-primary underline-offset-4 hover:underline">Details</Link>
            </p>
          </Panel>
          <div className="hidden items-center gap-2 font-mono text-[11px] text-muted-foreground lg:flex">
            <ClipboardPaste className="h-3.5 w-3.5" /> Tip: paste a screenshot anywhere on this page
          </div>
        </div>
      </div>
      <Recent />
    </div>
  );
}
