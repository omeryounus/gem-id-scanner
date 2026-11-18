import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api, localMode } from "@/lib/api";
import { firebaseConfigured } from "@/lib/firebaseApp";
import { identifyHybrid } from "@/lib/hybridIdentify";
import { saveLocalPhoto } from "@/lib/localPhotos";

const get = (url) => () => api.get(url).then((r) => r.data);

export const useMinerals = () =>
  useQuery({ queryKey: ["minerals"], queryFn: get("/minerals"), staleTime: Infinity });

export const useMineral = (id) =>
  useQuery({ queryKey: ["mineral", id], queryFn: get(`/minerals/${id}`), enabled: !!id, staleTime: Infinity });

export const useUsage = () => useQuery({ queryKey: ["usage"], queryFn: get("/usage"), staleTime: 10_000 });

export const useAnalysis = (id) =>
  useQuery({ queryKey: ["analysis", id], queryFn: get(`/analyses/${id}`), enabled: !!id, staleTime: Infinity, retry: 1 });

export const useAnalyses = () => useQuery({ queryKey: ["analyses"], queryFn: get("/analyses?limit=6") });

export const usePhotos = () => useQuery({ queryKey: ["photos"], queryFn: get("/photos") });

export const useRecords = () => useQuery({ queryKey: ["records"], queryFn: get("/records") });

const useInvalidate = (...keys) => {
  const qc = useQueryClient();
  return () => keys.forEach((k) => qc.invalidateQueries({ queryKey: [k] }));
};

async function saveHybrid(draft, blob) {
  const fd = new FormData();
  fd.append("result", JSON.stringify(draft));
  // A remote backend stores only photos Gemini saw. Local mode keeps every photo in this browser.
  if (draft.engine === "cloud_vision" || localMode) fd.append("file", blob, blob.name || "specimen.jpg");
  const saved = await api.post("/analyses", fd).then((r) => r.data);
  await saveLocalPhoto(saved.id, blob).catch(() => {});
  return saved;
}

export const useIdentify = () => {
  const qc = useQueryClient();
  const inv = useInvalidate("usage", "analyses", "photos");
  return useMutation({
    mutationFn: async (blob) => {
      if (!firebaseConfigured) {
        const fd = new FormData();
        fd.append("file", blob, blob.name || "specimen.jpg");
        return api.post("/identify", fd).then((r) => r.data);
      }
      const minerals = qc.getQueryData(["minerals"]) || (await api.get("/minerals")).data;
      const draft = await identifyHybrid(blob, minerals);
      return saveHybrid(draft, blob);
    },
    onSettled: inv,
  });
};

export const useSaveRecord = () => {
  const inv = useInvalidate("records", "usage");
  return useMutation({
    mutationFn: ({ id, ...body }) =>
      (id ? api.patch(`/records/${id}`, body) : api.post("/records", body)).then((r) => r.data),
    onSuccess: inv,
  });
};

export const useDeleteRecord = () => {
  const inv = useInvalidate("records", "usage");
  return useMutation({ mutationFn: (id) => api.delete(`/records/${id}`), onSuccess: inv });
};
