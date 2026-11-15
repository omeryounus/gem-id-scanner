import { useState } from "react";
import { ChevronsUpDown, Check } from "lucide-react";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Command, CommandEmpty, CommandInput, CommandItem, CommandList } from "@/components/ui/command";
import { Swatch } from "@/components/Bits";
import { useMinerals } from "@/lib/queries";
import { cn } from "@/lib/utils";

export function MineralPicker({ value, onChange, testid = "mineral-picker", placeholder = "Pick a species", className }) {
  const [open, setOpen] = useState(false);
  const { data: minerals = [] } = useMinerals();
  const cur = minerals.find((m) => m.id === value);
  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <button
          type="button"
          role="combobox"
          aria-expanded={open}
          data-testid={testid}
          className={cn("flex h-10 w-full items-center gap-2 rounded-md border border-input bg-transparent px-3 text-left text-sm transition-colors hover:border-primary/40", className)}
        >
          {cur ? <><Swatch color={cur.colors[0]} size={10} /><span className="truncate">{cur.name}</span></> : <span className="text-muted-foreground">{placeholder}</span>}
          <ChevronsUpDown className="ml-auto h-4 w-4 shrink-0 opacity-50" />
        </button>
      </PopoverTrigger>
      <PopoverContent className="w-[--radix-popover-trigger-width] min-w-[240px] p-0" align="start">
        <Command>
          <CommandInput placeholder="Type to search…" data-testid={`${testid}-search`} />
          <CommandList>
            <CommandEmpty>No species found.</CommandEmpty>
            {minerals.map((m) => (
              <CommandItem
                key={m.id}
                value={`${m.name} ${m.formula}`}
                onSelect={() => {
                  onChange(m.id === value ? null : m);
                  setOpen(false);
                }}
                data-testid={`${testid}-option-${m.id}`}
              >
                <Swatch color={m.colors[0]} size={10} />
                {m.name}
                <Check className={cn("ml-auto h-4 w-4 text-primary", value === m.id ? "opacity-100" : "opacity-0")} />
              </CommandItem>
            ))}
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  );
}
