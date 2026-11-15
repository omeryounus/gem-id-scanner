import "@/App.css";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { Toaster } from "@/components/ui/sonner";
import Shell from "@/components/Shell";
import IdentifyPage from "@/pages/IdentifyPage";
import GemstonesPage from "@/pages/GemstonesPage";
import GemstoneDetailPage from "@/pages/GemstoneDetailPage";
import GalleryPage from "@/pages/GalleryPage";
import RecordsPage from "@/pages/RecordsPage";
import AnalysisPage from "@/pages/AnalysisPage";
import ComparePage from "@/pages/ComparePage";
import PrivacyPage from "@/pages/PrivacyPage";
import LabelsPage from "@/pages/LabelsPage";
import SpecimenPage from "@/pages/SpecimenPage";
import { useTheme } from "@/lib/theme";

function App() {
  const theme = useTheme();
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/records/labels" element={<LabelsPage />} />
        <Route path="/s/:token" element={<SpecimenPage />} />
        <Route element={<Shell />}>
          <Route index element={<Navigate to="/identify" replace />} />
          <Route path="/identify" element={<IdentifyPage />} />
          <Route path="/gemstones" element={<GemstonesPage />} />
          <Route path="/gemstones/:id" element={<GemstoneDetailPage />} />
          <Route path="/gallery" element={<GalleryPage />} />
          <Route path="/records" element={<RecordsPage />} />
          <Route path="/analysis/:id" element={<AnalysisPage />} />
          <Route path="/compare" element={<ComparePage />} />
          <Route path="/privacy" element={<PrivacyPage />} />
          <Route path="*" element={<Navigate to="/identify" replace />} />
        </Route>
      </Routes>
      <Toaster theme={theme} position="top-center" richColors />
    </BrowserRouter>
  );
}

export default App;
