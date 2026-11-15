import { PageHeader, Panel, Eyebrow } from "@/components/Bits";

const SECTIONS = [
  ["No account, no tracking", "Field Bench on the web has no sign-up and no paywall. Your browser gets a random anonymous ID so we can keep your gallery and records together and enforce the same limits as the phone: 5 scans per day and 20 saved specimens. We run no ads and no third-party analytics."],
  ["What leaves your device", "Chrome asks Gemini Nano, on this computer, to rank a measured colour brief. The photograph stays in the browser when that rank is confident. The photo is sent to cloud Gemini through Firebase AI Logic only when Nano is missing or the rank is below the escalation threshold. Each analysis names the route: on-device, cloud text, cloud vision, or colour shortlist."],
  ["API keys stay out of the page", "The browser talks to Firebase AI Logic. It does not embed a Gemini API key. App Check guards the cloud call. Remote Config can change the cloud model name without a new build."],
  ["What we store", "Cloud-vision photos, the analysis result, and the records you save — tied only to your anonymous browser ID. On-device scans keep the JPEG in this browser. Catalog browsing stores nothing."],
  ["Phones", "Saves made only on an iPhone stay on that iPhone until the iOS app posts them. Photos posted by the iOS or Android apps carry a source badge in your gallery."],
  ["Deleting data", "Delete records at any time from Records. Clearing this site's browser storage disconnects you from your anonymous ID; the data then becomes unreachable and is purged on our retention cycle."],
];

export default function PrivacyPage() {
  return (
    <div className="rise max-w-3xl">
      <PageHeader eyebrow="Station 06 · Privacy" title="How your data moves" testid="privacy-header" />
      <div className="space-y-3" data-testid="privacy-content">
        {SECTIONS.map(([t, body], i) => (
          <Panel key={t} className="grid gap-2 p-6 sm:grid-cols-[48px_1fr]">
            <span className="font-mono text-sm text-primary">0{i + 1}</span>
            <div>
              <h2 className="font-display text-base font-medium md:text-lg">{t}</h2>
              <p className="mt-1.5 text-sm leading-relaxed text-muted-foreground">{body}</p>
            </div>
          </Panel>
        ))}
      </div>
      <Eyebrow className="mt-8">Last updated · November 2026</Eyebrow>
    </div>
  );
}
