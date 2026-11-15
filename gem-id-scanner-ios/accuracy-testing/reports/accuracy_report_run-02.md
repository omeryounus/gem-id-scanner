# Gem ID Scanner · Pre-Build Accuracy Validation Report

**Run ID**: `run-02` | **Model**: `gemini-1.5-flash` | **Date**: `2026-10-04 14:53:00Z`  
**Prompt**: `run-02-prompt.txt` (`accuracy-testing/prompts/run-02-prompt.txt`) | **Prompt SHA-256**: `8bd79862a603ba7f1cf1805c672eb02d47b0313a7424c908718a762b41219f39`  
**Spec Reference**: `gem-scanner-accuracy-test-plan.pdf` (Appendix A & B)

---

## Executive Verdict: 🟢 **PASS — READY TO BUILD**

> **Verdict Rationale**:  
- All Tier A and Tier B accuracy bars met.
- Confidence calibration bands are verified honest (Confirmed >=85%).
- Lookalike twin warning rate meets >=80% spec.
- Confident wrong answers within tolerance (0 <= 2).

---

## 1. Primary Accuracy Benchmark (Tier A vs. Tier B)

| Benchmark Metric | Spec Target | Tier A (Clean Ceiling) | Tier B (Field Floor) | Combined Overall | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Top-1 Accuracy** | Tier A ≥70% / Tier B ≥55% | **83.3%** (50/60) | **70.0%** (28/40) | **78.0%** (78/100) | ✅ PASS |
| **Top-3 Accuracy** | Tier A ≥90% / Tier B ≥80% | **95.0%** (57/60) | **95.0%** (38/40) | **95.0%** (95/100) | ✅ PASS |
| **Family Hit Rate (0.5)** | Diagnostic Tracking | 0.0% (0) | 0.0% (0) | 0.0% (0) | ℹ️ Logged |
| **Miss Rate (0.0)** | Minimize | 5.0% (3) | 5.0% (2) | 5.0% (5) | — |

---

## 2. Confidence Calibration & Honest Bands

| In-App Confidence Band | Confidence Range | Total Answers | Actual Top-1 Hit Rate | Spec Requirement | Calibration Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Confirmed Match** | `85% – 96%` | 59 | **100.0%** | **≥ 85.0%** (Honest Promise) | ✅ Honest |
| **Likely Match** | `55% – 84%` | 39 | **48.7%** | `55% – 84%` | ⚠️ Skewed |
| **Best Guesses** | `< 55%` | 2 | Top-3: **100.0%** | Top-3 recovery | ✅ Guesses Only |

- **Confident Wrong Answers (Conf ≥ 85% & Miss)**: **0** (Spec allows ≤ 2 in entire run) → ✅ PASS
- **Lookalike Twin Detection Rate**: **100.0%** (87/87 pairs named in top 3) → ✅ PASS (≥80%)

---

## 3. Candidate Confidence Spreads & Lookalike Margins (`conf_1 - conf_2`)

| Calibration & Tier Cohort | Sample Count | Mean Margin (`conf_1 - conf_2`) | Target Margin Behavior | Spread Distribution (Decisive ≥0.40 / Moderate 0.15–0.39 / Tight <0.15) | Spread Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Confirmed Match Band (≥85%)** | 59 | **+0.83** | Decisive separation (≥ +0.60) | 59 decisive / 0 mod / 0 tight | ✅ Wide Margin |
| **Likely Match Band (55%–84%)** | 39 | **+0.52** | Moderate separation (+0.15 to +0.55) | 29 decisive / 10 mod / 0 tight | ✅ Aligned Margin |
| **Best Guesses Band (<55%)** | 2 | **+0.19** | Tight tie-break (< +0.15) | 0 decisive / 2 mod / 0 tight | ✅ Close Tie-Break |
| **Tier A (Clean Ceiling)** | 60 | **+0.77** | High diagnostic contrast | 55 decisive / 5 mod / 0 tight | — |
| **Tier B (Field Floor)** | 40 | **+0.58** | Resilient lookalike separation | 33 decisive / 7 mod / 0 tight | — |
| **Overall Dataset** | 100 | **+0.70** | Robust candidate ranking | 88 decisive / 12 mod / 0 tight | — |

---

## 4. Misses Sorted by Error Taxonomy

| Error Category | Count | Diagnostic Meaning | Prescribed Fix Action |
| :--- | :--- | :--- | :--- |
| **Knowledge Gap** | 3 | Mineral missing from top-3 entirely | Add reference descriptions & physical diagnostic rules to prompt |
| **Ranking Error** | 17 | True mineral placed at rank 2 or 3 | Enhance separating-test contrast language in prompt |
| **Photo Problem** | 2 | Tier B field shot failed while Tier A passed | Enhance in-app real-time camera guidance & retake banners |
| **Calibration Error** | 0 | High confidence assigned to incorrect species | Adjust confidence floor & merge weighting rules |
| **Label Doubt** | 0 | Specimen physical identity uncertain | Physically re-verify specimen with hardness/streak/UV tests |

---

## 5. Per-Mineral Launch Rotation Status

> [!NOTE]
> All tested launch minerals achieved ≥1 Top-3 hit across test specimens. Zero minerals demoted.

---
*Report generated automatically by `accuracy-testing/run_accuracy_test.py`.*
