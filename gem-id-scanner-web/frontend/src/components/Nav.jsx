import { NavLink } from "react-router-dom";
import { ScanLine, Gem, Images, BookMarked, Columns2, ShieldCheck } from "lucide-react";
import { cn } from "@/lib/utils";

export const NAV = [
  { to: "/identify", label: "Identify", Icon: ScanLine, key: "1" },
  { to: "/gemstones", label: "Gemstones", Icon: Gem, key: "2" },
  { to: "/gallery", label: "Gallery", Icon: Images, key: "3" },
  { to: "/records", label: "Records", Icon: BookMarked, key: "4" },
  { to: "/compare", label: "Compare", Icon: Columns2, key: "5" },
  { to: "/privacy", label: "Privacy", Icon: ShieldCheck, key: "6" },
];

export const SideRail = () => (
  <aside className="sticky top-0 hidden h-dvh w-[232px] shrink-0 flex-col border-r border-border bg-sidebar px-3 py-5 md:flex">
    <NavLink to="/identify" viewTransition className="mb-8 flex items-center gap-2.5 px-2" data-testid="brand-home-link">
      <img src="/favicon.png" alt="" aria-hidden="true" className="h-8 w-8 rounded-lg shadow-[0_0_24px_rgba(240,192,64,0.25)]" />
      <span className="font-display text-lg font-semibold tracking-tight">Field Bench</span>
    </NavLink>
    <nav className="flex flex-col gap-0.5" aria-label="Primary">
      {NAV.map(({ to, label, Icon, key }) => (
        <NavLink
          key={to}
          to={to}
          viewTransition
          data-testid={`rail-nav-${label.toLowerCase()}`}
          className={({ isActive }) =>
            cn(
              "group relative flex h-10 items-center gap-3 rounded-lg px-3 text-sm text-muted-foreground transition-colors hover:bg-ink/[0.04] hover:text-foreground",
              isActive && "bg-primary/10 text-primary hover:bg-primary/10 hover:text-primary",
            )
          }
        >
          {({ isActive }) => (
            <>
              {isActive && <span className="absolute -left-3 h-5 w-[3px] rounded-r bg-primary shadow-[0_0_12px_#f59e0b]" />}
              <Icon className="h-[18px] w-[18px]" strokeWidth={isActive ? 2.3 : 1.8} />
              <span className="flex-1">{label}</span>
              <kbd className="font-mono text-[10px] text-muted-foreground/50 opacity-0 transition-opacity group-hover:opacity-100">G {key}</kbd>
            </>
          )}
        </NavLink>
      ))}
    </nav>
    <div className="mt-auto space-y-1 px-2 font-mono text-[10px] uppercase leading-relaxed tracking-widest text-muted-foreground/60">
      <div>Companion · Web</div>
      <div>60 species catalog</div>
    </div>
  </aside>
);

export const TabBar = () => (
  <nav
    aria-label="Tabs"
    className="fixed inset-x-0 bottom-0 z-40 border-t border-border bg-sidebar/85 pb-[env(safe-area-inset-bottom)] backdrop-blur-xl md:hidden"
  >
    <div className="grid grid-cols-5">
      {NAV.slice(0, 5).map(({ to, label, Icon }) => (
        <NavLink
          key={to}
          to={to}
          viewTransition
          data-testid={`tab-nav-${label.toLowerCase()}`}
          className={({ isActive }) =>
            cn(
              "relative flex h-[58px] flex-col items-center justify-center gap-1 text-[10.5px] font-medium text-muted-foreground transition-colors active:scale-95",
              isActive && "text-primary",
            )
          }
        >
          {({ isActive }) => (
            <>
              {isActive && <span className="absolute top-0 h-[2px] w-8 rounded-b bg-primary shadow-[0_0_12px_#f59e0b]" />}
              <Icon className="h-[22px] w-[22px]" strokeWidth={isActive ? 2.3 : 1.7} />
              {label}
            </>
          )}
        </NavLink>
      ))}
    </div>
  </nav>
);
