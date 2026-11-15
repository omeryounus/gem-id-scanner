import { useNavigate } from "react-router-dom";
import { SunMoon } from "lucide-react";
import { toggleTheme } from "@/lib/theme";
import { CommandDialog, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList, CommandSeparator } from "@/components/ui/command";
import { useMinerals } from "@/lib/queries";
import { NAV } from "@/components/Nav";
import { Swatch } from "@/components/Bits";
import { hardnessLabel } from "@/lib/catalog";

export const CommandPalette = ({ open, onOpenChange }) => {
  const navigate = useNavigate();
  const { data: minerals = [] } = useMinerals();
  const go = (to) => {
    onOpenChange(false);
    if (document.startViewTransition) document.startViewTransition(() => navigate(to));
    else navigate(to);
  };
  return (
    <CommandDialog open={open} onOpenChange={onOpenChange}>
      <CommandInput placeholder="Jump to a mineral or page…" data-testid="command-palette-input" />
      <CommandList className="max-h-[420px]">
        <CommandEmpty>No match. Try a formula like “SiO₂”.</CommandEmpty>
        <CommandGroup heading="Go to">
          {NAV.map(({ to, label, Icon, key }) => (
            <CommandItem key={to} value={`page ${label}`} onSelect={() => go(to)} data-testid={`palette-page-${label.toLowerCase()}`}>
              <Icon className="mr-2 h-4 w-4 text-primary" />
              {label}
              <span className="ml-auto font-mono text-[10px] text-muted-foreground">G {key}</span>
            </CommandItem>
          ))}
        </CommandGroup>
        <CommandSeparator />
        <CommandGroup heading="View">
          <CommandItem value="theme toggle day night light dark" onSelect={() => { onOpenChange(false); setTimeout(toggleTheme, 120); }} data-testid="palette-toggle-theme">
            <SunMoon className="mr-2 h-4 w-4 text-primary" /> Toggle day / night view
          </CommandItem>
        </CommandGroup>
        <CommandSeparator />
        <CommandGroup heading="Minerals">
          {minerals.map((m) => (
            <CommandItem
              key={m.id}
              value={`${m.name} ${m.formula} ${m.category}`}
              onSelect={() => go(`/gemstones/${m.id}`)}
              data-testid={`palette-mineral-${m.id}`}
            >
              <Swatch color={m.colors[0]} size={10} className="mr-2" />
              {m.name}
              <span className="ml-2 font-mono text-[11px] text-muted-foreground">{m.formula}</span>
              <span className="ml-auto font-mono text-[10px] text-muted-foreground">H {hardnessLabel(m.hardness)}</span>
            </CommandItem>
          ))}
        </CommandGroup>
      </CommandList>
    </CommandDialog>
  );
};
