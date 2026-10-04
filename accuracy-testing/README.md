# Gem ID Scanner · Pre-Build Accuracy Test Harness 🔬

An automated, repeatable evaluation harness for benchmarking **Gemini Vision** identification accuracy and lookalike separation against ground-truth mineralogical specimens before building user interface flows or deploying on-device CoreML shortlisted classifiers.

Reference specification: `gem-scanner-accuracy-test-plan.pdf`.

---

## 1. Overview & Purpose

The **Pre-Build Accuracy Test Harness** enforces product-truth validation before screen implementation and paywall activation. It executes a blind, 100-photo benchmark (60 clean Tier A + 40 field Tier B specimens) against the frozen Gemini Vision reasoning engine and generates:

1. **Top-1 and Top-3 Accuracy per Tier**: Separates clean optical ceilings from messy field realities.
2. **Confidence Calibration Verification**: Ensures the `Confirmed (≥85%)`, `Likely (55%–84%)`, and `Best Guesses (<55%)` bands are statistically honest.
3. **Lookalike Twin Warning Rate**: Verifies that known visual lookalike twins (e.g. Citrine vs. Heat-treated Amethyst, Turquoise vs. Howlite) are identified in the top 3.
4. **Confident Wrong Answer Audit**: Enforces a strict ceiling (≤2 in entire run) of high-confidence errors.
5. **Taxonomy Error Sorting**: Classifies misses into actionable buckets (*Knowledge Gap*, *Ranking Error*, *Photo Problem*, *Calibration Error*, *Label Doubt*).
6. **Automated Executive Verdict**: Determines **`PASS`**, **`CONDITIONAL`**, or **`FAIL`** against defined spec bars.

---

## 2. Directory Layout

```text
accuracy-testing/
├── README.md                          # Complete test harness documentation
├── scoring_sheet_template.csv         # Appendix A & B schema populated with 60 launch minerals
├── run_accuracy_test.py               # Automated evaluation runner & report generator
├── prompts/
│   └── run-01-prompt.txt              # Frozen Gemini Vision system & user prompt
├── photos/                            # Benchmark imagery (A-001.jpg .. A-060.jpg, B-001.jpg .. B-040.jpg)
│   └── .gitkeep
└── reports/                           # Output markdown and JSON validation results
    ├── scored_sheet_run-01.csv
    ├── accuracy_report_run-01.md
    └── accuracy_report_run-01.json
```

---

## 3. The 100-Photo Benchmark & Capture Protocol

The benchmark uses two tiers shot in the same session from the same physical specimens, scored separately and never averaged together:

| Tier | Photos | Description | Target Function | Spec Bars |
| :--- | :--- | :--- | :--- | :--- |
| **Tier A (Clean)** | 60 (`A-001` .. `A-060`) | 1 photo per launch mineral. Plain matte card background, even diffuse daylight, stone filling 70% of frame, scale coin, second angle for translucent/chatoyant stones. | **The Ceiling**: What the model knows when photography is optimal. | **Top-1 ≥ 70%**<br>**Top-3 ≥ 90%** |
| **Tier B (Field)** | 40 (`B-001` .. `B-040`) | Same specimens shot under real-world conditions: mixed tungsten/warm light, tabletop clutter, fingers for scale, reflections/glare, slight motion blur, tumbled pebbles. | **The Floor**: What a real user gets on day one. | **Top-1 ≥ 55%**<br>**Top-3 ≥ 80%** |

### The Specimen Rule
- **The split is by specimen, never by photo**: Both Tier A and Tier B shots of the same physical stone share the same `specimen_id` (e.g., `SPEC-001`).
- **Never iterate prompt tuning on benchmark photos**: A model tuned against test photos is a memorized exam. Prompt adjustments are validated on a separate 20-photo confirmation set.

### Label Verification Standards
A specimen label is admitted only when verified by:
1. Physical diagnostic test (`hardness_test`, `streak_test`, `uv_test`, `specific_gravity`).
2. Trusted provenance (`dealer_label` from reputable mineral supplier, certified purchase).
3. Expert identification in person (`expert_named`).

---

## 4. Launch Minerals Catalog (60 Species)

Pre-populated in `scoring_sheet_template.csv` across 5 mineralogical groups:

1. **Quartz Family (8)**: Clear Quartz, Amethyst, Citrine, Rose Quartz, Smoky Quartz, Milky Quartz, Aventurine, Carnelian.
2. **Everyday Finds (14)**: Agate, Banded Agate, Jasper, Red Jasper, Calcite, Orange Calcite, Fluorite, Pyrite, Hematite, Magnetite, Obsidian, Snowflake Obsidian, Sodalite, Tiger's Eye.
3. **Collector Staples (16)**: Emerald, Ruby, Sapphire, Blue Sapphire, Labradorite, Moonstone, Rainbow Moonstone, Malachite, Turquoise, Lapis Lazuli, Opal, White Opal, Garnet, Almandine Garnet, Azurite, Rhodochrosite.
4. **Shop Regulars (12)**: Peridot, Topaz, Imperial Topaz, Tourmaline, Black Tourmaline, Watermelon Tourmaline, Aquamarine, Amazonite, Chrysocolla, Howlite, Onyx, Jade (Nephrite).
5. **Colour & Flash (10)**: Sunstone, Kyanite, Apatite, Rhodonite, Unakite, Dalmatian Jasper, Picture Jasper, Moss Agate, Fire Agate, Charoite.

---

## 5. Scoring Rubric & Metrics

### Result Scoring
- **Top-1 Hit (1.0)**: Primary candidate is the true species or accepted variety.
- **Top-3 Hit**: True species is in candidate position 2 or 3 (measures Best Guesses recovery).
- **Family Hit (0.5)**: Wrong species, correct mineral family (e.g. Citrine called Amethyst, Nephrite called Jadeite).
- **Miss (0.0)**: Any unlisted species or confident wrong answer.

### Confidence Calibration Bands
- **Confirmed Match (`≥85%`)**: Actual hit rate inside band must be **≥ 85.0%**.
- **Likely Match (`55%–84%`)**: Actual hit rate aligns between 55% and 84%.
- **Best Guesses (`<55%`)**: Evaluated on Top-3 hit rate.
- **Confident Wrong Answers (`conf ≥ 85%` & miss)**: Must be **≤ 2** in the entire benchmark.

### Lookalike Twin Discipline
- Checks whether deceptive mineral twins (e.g. Turquoise vs. Dyed Howlite, Emerald vs. Green Tourmaline, Obsidian vs. Black Tourmaline) are explicitly named in the top-3 predictions. Spec target: **≥ 80.0%**.

### Error Taxonomy
Misses and family hits are automatically categorized into one of five actionable causes:
1. **Knowledge Gap**: True mineral missing from top-3; model describes non-existent features. *(Fix: Prompt reference descriptions / dataset expansion)*.
2. **Ranking Error**: True mineral in slot 2 or 3 behind a lookalike. *(Fix: Separating-test prompt rules)*.
3. **Photo Problem**: Tier B shot failed while Tier A passed. *(Fix: In-app capture guidance banners)*.
4. **Calibration Error**: Overconfident miss (≥85%). *(Fix: Confidence mapping & merge weighting)*.
5. **Label Doubt**: Model and literature disagree with physical label. *(Fix: Re-test specimen physically)*.

---

## 6. Step-by-Step Benchmark Execution

### Step 1: Prepare Photos
Place renamed photos in `accuracy-testing/photos/`:
- `A-001.jpg` through `A-060.jpg` (Tier A Clean)
- `B-001.jpg` through `B-040.jpg` (Tier B Field)

### Step 2: Set Environment Variable
```bash
export GEMINI_API_KEY="your_api_key_here"
```

### Step 3: Run the Benchmark
Execute the automated test harness:

```bash
# Run full 100-photo benchmark with Gemini Vision 1.5 Flash
python3 accuracy-testing/run_accuracy_test.py --run-id run-01 --model gemini-1.5-flash

# Run only Tier A clean benchmark
python3 accuracy-testing/run_accuracy_test.py --tier A --run-id run-01-tierA

# Run high-fidelity simulated benchmark (for CI / pipeline verification without API key)
python3 accuracy-testing/run_accuracy_test.py --mock --run-id mock-run-01

# Re-score an existing filled CSV without making new API calls
python3 accuracy-testing/run_accuracy_test.py --score-only --sheet accuracy-testing/reports/scored_sheet_run-01.csv --run-id run-01-rescore
```

---

## 7. Reading the Results & Decision Matrix

| Benchmark Verdict | Criteria | Action & Deployment Protocol |
| :--- | :--- | :--- |
| 🟢 **`PASS`** | Tier A Top-1 ≥70%, Top-3 ≥90%<br>Tier B Top-1 ≥55%, Top-3 ≥80%<br>Confirmed Band ≥85% honest<br>Confident wrong ≤2<br>Lookalike twin ≥80% | **Build with confidence**. The Gemini Vision core is validated. Proceed to camera-to-result UI integration and train CoreML on the labelled dataset. |
| 🟡 **`CONDITIONAL`** | Top-3 passes (≥90% / ≥80%) but Top-1 or calibration misses. | **Ship Best Guesses first**. Launch with single-answer restricted to passing minerals; remainder route to Best Guesses screen. Run 5-day fix loop before enabling paywall. |
| 🔴 **`FAIL`** | Tier A Top-1 <55%, Top-3 <80%, or confident wrong >2. | **Stop and fix core**. Do not build UI. Order of fixes: prompt separating tests → reference descriptions → confirmation set validation. |

### Per-Mineral Single-Answer Rule
Any mineral with $\ge 3$ test photos that misses Top-3 across all photos is automatically flagged and demoted to Best Guesses mode until additional reference data is acquired.

---

## 8. The 5-Day Fix Loop Schedule

If a run lands in `CONDITIONAL` or `FAIL`:

- **Day 1**: Specimen inventory & diagnostic library entries.
- **Day 2**: Shoot and lock Tier A & B photo set (100 photos).
- **Day 3**: Freeze prompt, execute blind run, sort misses by error taxonomy.
- **Day 4**: Fix round 1 (rewrite separating-test rules in prompt); shoot 20-photo confirmation set.
- **Day 5**: Run Prompt v2 on confirmation set **only**. Compare and finalize release decision.
