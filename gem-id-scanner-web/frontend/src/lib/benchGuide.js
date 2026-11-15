export const GUIDE = {
  "Mohs hardness": {
    tools: ["Glass plate or bottle (5.5)", "Steel nail or knife (6.5)", "Copper coin (3.5)", "Fingernail (2.5)"],
    steps: [
      "Pick a clean, fresh face on the specimen — not a weathered crust.",
      "Press a sharp point of the specimen firmly across the glass and drag about 1 cm.",
      "Wipe the mark with a damp finger. A real scratch stays; powder from a softer mineral rubs off.",
      "If it won't scratch glass, try the steel, then the copper coin, then your fingernail to bracket the value.",
    ],
    safety: "Hold glass flat on a table, never in your hand.",
  },
  Streak: {
    tools: ["Unglazed porcelain tile (back of a bathroom tile)"],
    steps: [
      "Hold the tile flat and drag a corner of the specimen firmly across it.",
      "Blow away loose grit and read the colour of the powder line, not the specimen.",
      "Minerals harder than ~7 scratch the tile and leave no streak — record that as ‘white / none’.",
    ],
  },
  "Specific gravity (heft)": {
    tools: ["Kitchen scale (0.1 g)", "Cup of water", "Thread"],
    steps: [
      "Weigh the dry specimen and note the value (A).",
      "Tie it with thread, hang it fully submerged in the cup on the scale without touching the sides, and note the extra weight (W).",
      "Specific gravity ≈ A ÷ W. No scale? Compare heft against a same-size quartz pebble (2.65).",
    ],
  },
  "Cleavage / fracture": {
    tools: ["10× hand loupe", "Single bright light"],
    steps: [
      "Rotate the specimen under a single light and look for flat faces that flash together.",
      "Count how many directions of flat planes repeat and the angles between them.",
      "Curved, shell-like breaks indicate conchoidal fracture instead of cleavage.",
    ],
  },
  Lustre: {
    tools: ["Single light source"],
    steps: [
      "Tilt a fresh surface toward the light at a low angle.",
      "Compare the reflection: metallic (like steel), vitreous (glass), resinous, pearly, silky, greasy or dull.",
    ],
  },
  "Acid reaction": {
    tools: ["Dilute HCl (10%) or white vinegar", "Dropper", "Gloves"],
    steps: [
      "Place one drop on an inconspicuous, freshly scraped spot.",
      "Watch closely for 10 seconds. Bubbling or fizzing indicates a carbonate.",
      "If nothing happens, scrape a little powder and try again — dolomite only fizzes when powdered.",
      "Rinse the specimen with water afterwards.",
    ],
    safety: "Wear gloves and eye protection. Never use acid on specimens you plan to sell or display untreated.",
  },
};

export function verdict(steps, answers) {
  const tally = {};
  steps.forEach((s) => {
    const v = answers[s.key];
    if (v === "a") tally[s.aId] = (tally[s.aId] || 0) + 1;
    if (v === "b") tally[s.bId] = (tally[s.bId] || 0) + 1;
  });
  const top = steps[0]?.aId;
  const topScore = tally[top] || 0;
  const rival = Object.entries(tally).filter(([id]) => id !== top).sort((x, y) => y[1] - x[1])[0];
  const answered = steps.filter((s) => answers[s.key] && answers[s.key] !== "unsure").length;
  if (!answered) return { status: "unconfirmed", winner: null, tally };
  if (rival && rival[1] > topScore) return { status: "disputed", winner: rival[0], tally };
  if (topScore >= 2 && !rival) return { status: "confirmed", winner: top, tally };
  return { status: "unconfirmed", winner: topScore >= (rival?.[1] || 0) ? top : null, tally };
}
