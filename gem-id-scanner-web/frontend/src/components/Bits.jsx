import { Smartphone, Globe, TabletSmartphone } from "lucide-react";
import { COLOR_HEX } from "@/lib/catalog";
import { cn } from "@/lib/utils";

export const Eyebrow = ({ children, className }) => (
  <div className={cn("font-mono text-[10.5px] uppercase tracking-[0.18em] text-muted-foreground", className)}>{children}</div>
);

export const Swatch = ({ color, size = 14, className, ...p }) => (
  <span
    title={color}
    className={cn("inline-block shrink-0 rounded-full ring-1 ring-ink/15", className)}
    style={{ width: size, height: size, background: COLOR_HEX[color] || color }}
    {...p}
  />
);

export const HardnessBar = ({ range, className }) => {
  const [a, b] = range;
  return (
    <div className={cn("relative h-1.5 w-full rounded-full bg-ink/[0.06]", className)} aria-label={`Mohs ${a} to ${b}`}>
      {[...Array(9)].map((_, i) => (
        <span key={i} className="absolute top-0 h-full w-px bg-ink/10" style={{ left: `${((i + 1) / 10) * 100}%` }} />
      ))}
      <span
        className="absolute top-0 h-full rounded-full bg-primary shadow-[0_0_10px_rgba(245,158,11,0.5)]"
        style={{ left: `${((a - 1) / 9) * 100}%`, width: `max(6px, ${((b - a) / 9) * 100}%)` }}
      />
    </div>
  );
};

const SOURCES = {
  iphone: { label: "iPhone", Icon: Smartphone, cls: "text-sky-300 border-sky-400/30 bg-sky-400/10" },
  android: { label: "Android", Icon: TabletSmartphone, cls: "text-emerald-300 border-emerald-400/30 bg-emerald-400/10" },
  web: { label: "Web", Icon: Globe, cls: "text-amber-300 border-amber-400/30 bg-amber-400/10" },
};

export const SourceBadge = ({ source = "web", className, ...p }) => {
  const s = SOURCES[source] || SOURCES.web;
  return (
    <span
      className={cn("inline-flex items-center gap-1 rounded-md border px-1.5 py-0.5 font-mono text-[10px] uppercase tracking-wider backdrop-blur-md", s.cls, className)}
      {...p}
    >
      <s.Icon className="h-3 w-3" /> {s.label}
    </span>
  );
};

export const Pips = ({ used, total, className }) => (
  <div className={cn("flex gap-1", className)}>
    {[...Array(total)].map((_, i) => (
      <span key={i} className={cn("h-1.5 w-4 rounded-full transition-colors", i < used ? "bg-primary" : "bg-ink/10")} />
    ))}
  </div>
);

export const PageHeader = ({ eyebrow, title, children, testid }) => (
  <header className="mb-8 flex flex-col gap-4 md:flex-row md:items-end md:justify-between" data-testid={testid}>
    <div className="space-y-2">
      {eyebrow && <Eyebrow>{eyebrow}</Eyebrow>}
      <h1 className="font-display text-4xl font-semibold tracking-tight sm:text-5xl">{title}</h1>
    </div>
    {children && <div className="flex flex-wrap items-center gap-2">{children}</div>}
  </header>
);

export const Panel = ({ className, children, ...p }) => (
  <section className={cn("rounded-xl border border-border bg-card/70", className)} {...p}>
    {children}
  </section>
);
