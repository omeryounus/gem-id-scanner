import { useEffect, useState } from "react";
import { Star, X } from "lucide-react";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { MineralPicker } from "@/components/MineralPicker";
import { useSaveRecord, useUsage } from "@/lib/queries";
import { FORMS } from "@/lib/catalog";
import { errMsg } from "@/lib/api";

const EMPTY = { mineral_id: null, name: "", notes: "", weight: "", weight_unit: "g", location: "", form: "Raw", favorite: false, confirmed: "unconfirmed", tags: [] };

const TagInput = ({ value, onChange }) => {
  const [draft, setDraft] = useState("");
  const add = () => {
    const t = draft.trim().toLowerCase();
    if (t && !value.includes(t)) onChange([...value, t]);
    setDraft("");
  };
  return (
    <div className="flex min-h-10 flex-wrap items-center gap-1.5 rounded-md border border-input bg-transparent px-2 py-1.5 focus-within:ring-1 focus-within:ring-ring">
      {value.map((t) => (
        <span key={t} className="inline-flex items-center gap-1 rounded-full bg-primary/15 px-2 py-0.5 font-mono text-[11px] text-primary">
          #{t}
          <button type="button" onClick={() => onChange(value.filter((x) => x !== t))} aria-label={`Remove ${t}`}><X className="h-3 w-3" /></button>
        </span>
      ))}
      <input
        value={draft}
        onChange={(e) => setDraft(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === "Enter" || e.key === ",") {
            e.preventDefault();
            add();
          } else if (e.key === "Backspace" && !draft && value.length) onChange(value.slice(0, -1));
        }}
        onBlur={add}
        placeholder={value.length ? "" : "field-trip, display, trade…"}
        className="min-w-[100px] flex-1 bg-transparent text-sm outline-none placeholder:text-muted-foreground"
        data-testid="record-tags-input"
      />
    </div>
  );
};

export function RecordDialog({ open, onOpenChange, initial }) {
  const [v, setV] = useState(EMPTY);
  const save = useSaveRecord();
  const { data: u } = useUsage();
  const editing = !!initial?.id;
  const full = !editing && u && u.saved >= u.save_limit;

  useEffect(() => {
    if (open) setV({ ...EMPTY, ...initial, weight: initial?.weight ?? "" });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open]);

  const set = (k) => (val) => setV((s) => ({ ...s, [k]: val?.target ? val.target.value : val }));

  const submit = async (e) => {
    e.preventDefault();
    const { id, created_at, updated_at, source, ...rest } = v;
    const body = { ...rest, weight: v.weight === "" ? null : Number(v.weight) };
    try {
      await save.mutateAsync(editing ? { id, ...body } : body);
      toast.success(editing ? "Record updated" : "Saved to records");
      onOpenChange(false);
    } catch (err) {
      toast.error(errMsg(err, "Could not save"));
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[92dvh] overflow-y-auto sm:max-w-xl" data-testid="record-dialog">
        <DialogHeader>
          <DialogTitle className="font-display text-2xl">{editing ? "Edit record" : "Save specimen"}</DialogTitle>
          <DialogDescription>{u && `${u.saved} of ${u.save_limit} saved specimens used in this browser.`}</DialogDescription>
        </DialogHeader>
        <form onSubmit={submit} className="space-y-4">
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Species</Label>
              <MineralPicker value={v.mineral_id} onChange={(m) => setV((s) => ({ ...s, mineral_id: m?.id || null, name: m ? m.name : s.name }))} />
            </div>
            <div className="space-y-1.5">
              <Label htmlFor="rec-name">Label</Label>
              <Input id="rec-name" required value={v.name} onChange={set("name")} placeholder="e.g. Hilltop quartz point" data-testid="record-name-input" />
            </div>
          </div>
          <div className="grid gap-4 sm:grid-cols-[1fr_auto_1fr]">
            <div className="space-y-1.5">
              <Label htmlFor="rec-weight">Weight</Label>
              <Input id="rec-weight" type="number" min="0" step="0.01" inputMode="decimal" value={v.weight} onChange={set("weight")} placeholder="0.00" data-testid="record-weight-input" />
            </div>
            <div className="space-y-1.5">
              <Label>Unit</Label>
              <Select value={v.weight_unit} onValueChange={set("weight_unit")}>
                <SelectTrigger className="w-24" data-testid="record-weight-unit"><SelectValue /></SelectTrigger>
                <SelectContent><SelectItem value="g">grams</SelectItem><SelectItem value="ct">carats</SelectItem></SelectContent>
              </Select>
            </div>
            <div className="space-y-1.5">
              <Label>Form</Label>
              <Select value={v.form} onValueChange={set("form")}>
                <SelectTrigger data-testid="record-form-select"><SelectValue /></SelectTrigger>
                <SelectContent>{FORMS.map((f) => <SelectItem key={f} value={f} data-testid={`record-form-${f.toLowerCase()}`}>{f}</SelectItem>)}</SelectContent>
              </Select>
            </div>
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="rec-loc">Where you got it</Label>
            <Input id="rec-loc" value={v.location} onChange={set("location")} placeholder="Quarry, shop, show, trade…" data-testid="record-location-input" />
            <p className="text-[11px] text-muted-foreground">Add a town, region or country to place it on your field map.</p>
          </div>
          <div className="space-y-1.5">
            <Label htmlFor="rec-notes">Notes</Label>
            <Textarea id="rec-notes" rows={3} value={v.notes} onChange={set("notes")} placeholder="Streak, scratch tests, inclusions…" data-testid="record-notes-input" />
          </div>
          <div className="space-y-1.5">
            <Label>Tags</Label>
            <TagInput value={v.tags} onChange={set("tags")} />
          </div>
          <div className="grid gap-4 sm:grid-cols-2">
            <div className="space-y-1.5">
              <Label>Confirmation</Label>
              <Select value={v.confirmed} onValueChange={set("confirmed")}>
                <SelectTrigger data-testid="record-confirmed-select"><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="unconfirmed" data-testid="record-confirmed-unconfirmed">Unconfirmed</SelectItem>
                  <SelectItem value="confirmed" data-testid="record-confirmed-confirmed">Confirmed by tests</SelectItem>
                  <SelectItem value="disputed" data-testid="record-confirmed-disputed">Disputed</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <label className="flex items-center justify-between gap-3 rounded-md border border-input px-3 py-2 sm:mt-6">
              <span className="flex items-center gap-2 text-sm"><Star className="h-4 w-4 text-primary" /> Favorite</span>
              <Switch checked={v.favorite} onCheckedChange={set("favorite")} data-testid="record-favorite-switch" />
            </label>
          </div>
          {full && <p className="text-sm text-primary" data-testid="record-limit-warning">You've reached 20 saved specimens. Delete one to save another.</p>}
          <DialogFooter className="gap-2 pt-2">
            <Button type="button" variant="ghost" onClick={() => onOpenChange(false)} data-testid="record-cancel">Cancel</Button>
            <Button type="submit" disabled={save.isPending || full} data-testid="record-submit">{save.isPending ? "Saving…" : editing ? "Update" : "Save"}</Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
