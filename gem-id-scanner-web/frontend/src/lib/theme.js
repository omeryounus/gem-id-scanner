import { useSyncExternalStore } from "react";

const KEY = "fieldbench.theme";
const listeners = new Set();
const current = () => (document.documentElement.classList.contains("light") ? "light" : "dark");

function apply(theme) {
  const root = document.documentElement;
  root.classList.toggle("light", theme === "light");
  root.classList.toggle("dark", theme === "dark");
  document.querySelector('meta[name="theme-color"]')?.setAttribute("content", theme === "light" ? "#F5F2EA" : "#0B0C0E");
  localStorage.setItem(KEY, theme);
  listeners.forEach((l) => l());
}

// Circular reveal from the click point using the View Transitions API.
export function toggleTheme(e) {
  const next = current() === "dark" ? "light" : "dark";
  if (!document.startViewTransition || matchMedia("(prefers-reduced-motion: reduce)").matches) return apply(next);
  const x = e?.clientX ?? innerWidth - 40;
  const y = e?.clientY ?? 28;
  const r = Math.hypot(Math.max(x, innerWidth - x), Math.max(y, innerHeight - y));
  document.documentElement.classList.add("theme-vt");
  const vt = document.startViewTransition(() => apply(next));
  vt.ready.then(() =>
    document.documentElement.animate(
      { clipPath: [`circle(0px at ${x}px ${y}px)`, `circle(${r}px at ${x}px ${y}px)`] },
      { duration: 520, easing: "cubic-bezier(0.2,0.7,0.2,1)", pseudoElement: "::view-transition-new(root)" },
    ),
  );
  vt.finished.finally(() => document.documentElement.classList.remove("theme-vt"));
}

export const useTheme = () =>
  useSyncExternalStore(
    (cb) => (listeners.add(cb), () => listeners.delete(cb)),
    current,
  );
