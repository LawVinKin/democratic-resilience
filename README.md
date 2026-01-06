# Parliamentary Resilience: Government Systems and Democratic Stability

## Quick summary

This repository accompanies an analysis of how government system types (Parliamentary, Presidential, Semi‑Presidential) relate to democratic stability across countries (2000–2023). The canonical paper examines resilience metrics derived from V-Dem democracy scores.

## Short repo guide

- `data/` — raw and processed data. Analysis-ready files live in `data/02-analysis_data/`.
- `scripts/` — numbered R scripts to reproduce the analysis. Run them in numeric order.
- `output/` — generated tables, figures, and model objects.
- `paper/` — Quarto manuscript and references.

For a complete run-order and file-level details, see `DOCS.md`.

## Essential notes

- Key dependent variables include `volatility` (SD of democracy scores) and `total_decline` (sum of year-over-year declines). Exact definitions and preprocessing steps are in `scripts/02-clean_data.R`.
- Main independent variable: `system_type` (Parliamentary, Semi‑Presidential, Presidential).
- Robust standard errors: models use HC1-style robust SEs across tables for consistency.

## Requirements

Install the main R packages used in the analysis (example):

```r
install.packages(c(
  "tidyverse", "readr", "readxl", "countrycode",
  "WDI", "sandwich", "lmtest", "modelsummary",
  "flextable", "officer"
))
```

## Data sources

- V-Dem v15 — https://v-dem.net
- Database of Political Institutions (DPI)
- Quality of Government (QOG) — https://qog.pol.gu.se
- World Bank WDI

## Where to look for more

- Full documentation and the codebook: `DOCS.md`
- Script-level processing details: `scripts/02-clean_data.R` and `scripts/03-model_data.R`

---
Last updated: 2026-01-06

Current Date and Time (UTC - YYYY-MM-DD HH:MM:SS formatted): 2026-01-06 20:57:37
Current User's Login: LawVinKin