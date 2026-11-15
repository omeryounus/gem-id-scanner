const PALETTE = {
  colorless: [236, 240, 243],
  white: [250, 250, 250],
  gray: [128, 128, 128],
  black: [20, 20, 22],
  red: [190, 30, 45],
  pink: [236, 130, 170],
  orange: [235, 120, 30],
  yellow: [240, 200, 40],
  green: [40, 150, 80],
  blue: [40, 90, 200],
  purple: [120, 60, 160],
  brown: [120, 75, 40],
  metallic: [180, 175, 160],
};

const CHROMA = Object.keys(PALETTE).filter((name) => !["white", "black", "gray", "colorless", "metallic"].includes(name));

const hex = ([r, g, b]) => `#${[r, g, b].map((n) => n.toString(16).padStart(2, "0")).join("")}`;

function nearest(r, g, b) {
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  if (max - min < 22) return max > 215 ? "white" : max < 45 ? "black" : "gray";
  return CHROMA.reduce((best, name) => {
    const [pr, pg, pb] = PALETTE[name];
    const dist = (pr - r) ** 2 + (pg - g) ** 2 + (pb - b) ** 2;
    return dist < best.dist ? { name, dist } : best;
  }, { name: CHROMA[0], dist: Infinity }).name;
}

export async function measureColors(file) {
  const bitmap = await createImageBitmap(file);
  const side = 48;
  const canvas = document.createElement("canvas");
  canvas.width = side;
  canvas.height = side;
  const ctx = canvas.getContext("2d", { willReadFrequently: true });
  ctx.drawImage(bitmap, 0, 0, side, side);
  const crop = Math.round(side / 6);
  const { data } = ctx.getImageData(crop, crop, side - crop * 2, side - crop * 2);
  const counts = {};
  const pixels = data.length / 4;
  for (let i = 0; i < data.length; i += 4) {
    const name = nearest(data[i], data[i + 1], data[i + 2]);
    counts[name] = (counts[name] || 0) + 1;
  }
  return Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 4)
    .filter(([, n]) => n / pixels >= 0.05)
    .map(([color, n]) => ({ color, hex: hex(PALETTE[color]), share: Math.round((n / pixels) * 1000) / 1000 }));
}

export function shortlistMinerals(colors, minerals) {
  return minerals
    .map((mineral) => {
      const share = colors.reduce((sum, color) => sum + (mineral.colors?.includes(color.color) ? color.share : 0), 0);
      if (share <= 0) return null;
      return { id: mineral.id, score: Math.round((share / (mineral.colors.length ** 0.3)) * 1000) / 1000, mineral };
    })
    .filter(Boolean)
    .sort((a, b) => b.score - a.score)
    .slice(0, 8);
}
