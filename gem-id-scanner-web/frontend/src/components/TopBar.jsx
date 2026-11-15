import { Link } from "react-router-dom";
import { Search, ShieldCheck, ScanLine, Archive, Sun, Moon } from "lucide-react";
import { useUsage } from "@/lib/queries";
import { toggleTheme, useTheme } from "@/lib/theme";
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip";
import { cn } from "@/lib/utils";

const ThemeToggle = () => {
  const theme = useTheme();
  const night = theme === "dark";
  return (
    <Tooltip>
      <TooltipTrigger asChild>
        <button
          onClick={toggleTheme}
          aria-label={night ? "Switch to daytime view" : "Switch to night view"}
          data-testid="theme-toggle"
          data-theme={theme}
          className="relative grid h-8 w-8 place-items-center overflow-hidden rounded-full border border-border text-muted-foreground transition-colors hover:border-primary/50 hover:text-primary"
        >
          <Sun className={cn("absolute h-4 w-4 transition-[transform,opacity] duration-300", night ? "translate-y-0 rotate-0 opacity-100" : "translate-y-5 rotate-90 opacity-0")} />
          <Moon className={cn("absolute h-4 w-4 transition-[transform,opacity] duration-300", night ? "-translate-y-5 -rotate-90 opacity-0" : "translate-y-0 rotate-0 opacity-100")} />
        </button>
      </TooltipTrigger>
      <TooltipContent>{night ? "Daytime view" : "Night view"}</TooltipContent>
    </Tooltip>
  );
};

const Meter = ({ Icon, label, used, limit, testid, tip }) => {
  const full = used >= limit;
  return (
    <Tooltip>
      <TooltipTrigger asChild>
        <div
          data-testid={testid}
          className={cn(
            "flex h-8 items-center gap-2 rounded-full border border-border bg-card px-3 font-mono text-[11px] tabular-nums",
            full && "border-primary/50 text-primary",
          )}
        >
          <Icon className="h-3.5 w-3.5 text-primary" />
          <span className="hidden text-muted-foreground lg:inline">{label}</span>
          <span>
            {used}/{limit}
          </span>
        </div>
      </TooltipTrigger>
      <TooltipContent>{tip}</TooltipContent>
    </Tooltip>
  );
};

export const TopBar = ({ onOpenPalette }) => {
  const { data: u } = useUsage();
  return (
    <div className="sticky top-0 z-30 flex h-14 items-center gap-2 border-b border-border bg-background/80 px-4 backdrop-blur-xl md:px-8">
      <Link to="/identify" viewTransition className="whitespace-nowrap font-display text-base font-semibold md:hidden" data-testid="topbar-brand">
        Field Bench
      </Link>
      <button
        onClick={onOpenPalette}
        data-testid="command-palette-trigger"
        className="ml-auto flex h-8 items-center gap-2 rounded-full border border-border bg-card px-3 text-xs text-muted-foreground transition-colors hover:border-primary/40 hover:text-foreground md:ml-0 md:w-72"
      >
        <Search className="h-3.5 w-3.5" />
        <span className="hidden md:inline">Search minerals, pages…</span>
        <kbd className="ml-auto hidden rounded border border-border px-1.5 font-mono text-[10px] md:inline">⌘K</kbd>
      </button>
      <div className="flex items-center gap-2 md:ml-auto">
        {u && (
          <>
            <Meter Icon={ScanLine} label="Scans today" used={u.scans_today} limit={u.scan_limit} testid="topbar-scan-quota" tip="5 scans per day, same as the phone app" />
            <Meter Icon={Archive} label="Saved" used={u.saved} limit={u.save_limit} testid="topbar-save-quota" tip="Up to 20 saved specimens per browser" />
          </>
        )}
        <Link to="/privacy" viewTransition data-testid="topbar-privacy-link" className="hidden h-8 w-8 place-items-center rounded-full border border-border text-muted-foreground hover:text-primary max-md:min-[420px]:grid" aria-label="Privacy">
          <ShieldCheck className="h-4 w-4" />
        </Link>
        <ThemeToggle />
      </div>
    </div>
  );
};
