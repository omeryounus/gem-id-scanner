import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { MapContainer, TileLayer, Marker, Popup, useMap, useMapEvents } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { useQueryClient } from "@tanstack/react-query";
import { MapPinOff, MapPinPlus, Move, X } from "lucide-react";
import { toast } from "sonner";
import { useSaveRecord } from "@/lib/queries";
import { errMsg } from "@/lib/api";
import { api } from "@/lib/api";
import { Eyebrow } from "@/components/Bits";
import { cn } from "@/lib/utils";

const pin = (fav) =>
  L.divIcon({
    className: "",
    html: `<span style="display:block;width:18px;height:18px;border-radius:9999px;background:#f59e0b;border:3px solid ${fav ? "#fff" : "#1a1d24"};box-shadow:0 0 0 4px rgba(245,158,11,.25),0 2px 8px rgba(0,0,0,.4)"></span>`,
    iconSize: [18, 18],
    iconAnchor: [9, 9],
  });

const Fit = ({ points }) => {
  const map = useMap();
  useEffect(() => {
    if (points.length === 1) map.setView(points[0], 7);
    else if (points.length > 1) map.fitBounds(points, { padding: [48, 48], maxZoom: 9 });
  }, [map, points]);
  return null;
};

const ClickToPlace = ({ onPlace }) => {
  useMapEvents({ click: (e) => onPlace(e.latlng) });
  return null;
};

export function RecordsMap({ records }) {
  const save = useSaveRecord();
  const [placing, setPlacing] = useState(null);
  const pinAt = (r, { lat, lng }, verb) =>
    save.mutate(
      { id: r.id, lat: +lat.toFixed(5), lng: +(((lng + 540) % 360) - 180).toFixed(5) },
      { onSuccess: () => toast.success(`${r.name} ${verb}`), onError: (e) => toast.error(errMsg(e)) },
    );
  useEffect(() => {
    if (!placing) return;
    const onKey = (e) => e.key === "Escape" && setPlacing(null);
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [placing]);
  const qc = useQueryClient();
  const placed = records.filter((r) => r.lat != null && r.lng != null);
  const unplaced = records.filter((r) => r.lat == null);
  const points = placed.map((r) => [r.lat, r.lng]);
  const key = placed.map((r) => r.id).join("|");

  useEffect(() => {
    if (!records.some((r) => r.location && r.lat == null)) return;
    api.post("/records/geocode").then(({ data }) => data.updated && qc.invalidateQueries({ queryKey: ["records"] }));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <div className="space-y-4" data-testid="records-map">
      <div className={cn("relative isolate h-[60dvh] min-h-[360px] overflow-hidden rounded-xl border border-border", placing && "placing border-primary")}>
        <MapContainer center={[20, 0]} zoom={2} scrollWheelZoom className="h-full w-full" worldCopyJump>
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://tile.openstreetmap.org/{z}/{x}/{y}.png"
            maxZoom={18}
          />
          <Fit points={points} key={key} />
          {placing && <ClickToPlace onPlace={(ll) => { pinAt(placing, ll, "placed on the map"); setPlacing(null); }} />}
          {placed.map((r) => (
            <Marker
              key={r.id}
              position={[r.lat, r.lng]}
              icon={pin(r.favorite)}
              draggable
              eventHandlers={{ dragend: (e) => pinAt(r, e.target.getLatLng(), "pin moved") }}
            >
              <Popup>
                <div className="space-y-0.5" data-testid={`map-popup-${r.id}`}>
                  <div className="text-sm font-semibold">{r.name}</div>
                  <div className="text-xs opacity-70">{r.location}</div>
                  {r.weight != null && <div className="font-mono text-[11px]">{r.weight} {r.weight_unit} · {r.form}</div>}
                  {r.geo_manual && <div className="font-mono text-[10px] opacity-60">pinned by hand</div>}
                  {r.mineral_id && <Link to={`/gemstones/${r.mineral_id}`} className="block text-xs text-amber-600">Species sheet →</Link>}
                  <div className="flex items-center gap-1 pt-1 text-[10px] opacity-60"><Move className="h-3 w-3" /> Drag the pin to move it</div>
                </div>
              </Popup>
            </Marker>
          ))}
        </MapContainer>
        {placing && (
          <div className="rise absolute inset-x-3 bottom-8 z-[500] flex items-center gap-3 rounded-lg border border-primary/50 bg-card/95 px-4 py-2.5 text-sm shadow-xl backdrop-blur sm:left-1/2 sm:right-auto sm:-translate-x-1/2" data-testid="records-map-placing-banner" role="status">
            <MapPinPlus className="h-4 w-4 shrink-0 text-primary" />
            <span className="min-w-0 flex-1">Tap the map to place <b className="font-medium">{placing.name}</b></span>
            <button onClick={() => setPlacing(null)} aria-label="Cancel placing" data-testid="records-map-placing-cancel" className="grid h-7 w-7 place-items-center rounded-full hover:bg-ink/10"><X className="h-4 w-4" /></button>
          </div>
        )}
        <div className="pointer-events-none absolute right-3 top-3 z-[400] rounded-md border border-border bg-card/90 px-2.5 py-1 font-mono text-[11px] backdrop-blur" data-testid="records-map-count">
          {placed.length} of {records.length} on map
        </div>
      </div>
      {unplaced.length > 0 && (
        <div className="rounded-xl border border-dashed border-border p-4" data-testid="records-map-unplaced">
          <Eyebrow className="mb-2 flex items-center gap-1.5"><MapPinOff className="h-3 w-3" /> Not on the map</Eyebrow>
          <div className="flex flex-wrap gap-2 text-sm">
            {unplaced.map((r) => (
              <button
                key={r.id}
                onClick={() => setPlacing(r)}
                aria-pressed={placing?.id === r.id}
                data-testid={`records-map-place-${r.id}`}
                className={cn(
                  "inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs transition-colors",
                  placing?.id === r.id ? "border-primary bg-primary/15 text-primary" : "border-border text-muted-foreground hover:border-primary/50 hover:text-foreground",
                )}
              >
                <MapPinPlus className="h-3.5 w-3.5" />
                {r.name} · {r.location ? `“${r.location}” not found` : "no location"}
              </button>
            ))}
          </div>
          <p className="mt-2 text-xs text-muted-foreground">Tap one, then tap the map to drop its pin — or add a town, region or country to “Where you got it”.</p>
        </div>
      )}
    </div>
  );
}
