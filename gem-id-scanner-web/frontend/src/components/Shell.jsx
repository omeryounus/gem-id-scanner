import { useEffect, useState } from "react";
import { Outlet, useNavigate } from "react-router-dom";
import { SideRail, TabBar, NAV } from "@/components/Nav";
import { TopBar } from "@/components/TopBar";
import { CommandPalette } from "@/components/CommandPalette";
import { TooltipProvider } from "@/components/ui/tooltip";

const isTyping = (e) => ["INPUT", "TEXTAREA", "SELECT"].includes(e.target.tagName) || e.target.isContentEditable;

function useShortcuts(setOpen) {
  const navigate = useNavigate();
  useEffect(() => {
    let gPressed = false;
    let timer;
    const onKey = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "k") {
        e.preventDefault();
        setOpen((o) => !o);
        return;
      }
      if (isTyping(e) || e.metaKey || e.ctrlKey || e.altKey) return;
      if (e.key === "g") {
        gPressed = true;
        clearTimeout(timer);
        timer = setTimeout(() => (gPressed = false), 900);
        return;
      }
      const item = gPressed && NAV.find((n) => n.key === e.key);
      if (item) {
        gPressed = false;
        navigate(item.to, { viewTransition: true });
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [navigate, setOpen]);
}

export default function Shell() {
  const [open, setOpen] = useState(false);
  useShortcuts(setOpen);
  return (
    <TooltipProvider delayDuration={250}>
      <div className="flex min-h-dvh bg-background text-foreground">
        <SideRail />
        <div className="flex min-w-0 flex-1 flex-col">
          <TopBar onOpenPalette={() => setOpen(true)} />
          <main className="vt-main mx-auto w-full max-w-[1400px] flex-1 px-4 pb-28 pt-8 md:px-8 md:pb-16 lg:px-12">
            <Outlet />
          </main>
        </div>
        <TabBar />
        <CommandPalette open={open} onOpenChange={setOpen} />
      </div>
    </TooltipProvider>
  );
}
