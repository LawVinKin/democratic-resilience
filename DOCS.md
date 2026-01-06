# Project Documentation: Parliamentary Resilience

This single document consolidates project-level documentation (overview, data provenance, codebook, and author notes).

## Overview

This project investigates the relationship between government system types (Parliamentary, Presidential, Semi-Presidential) and democratic stability using cross-national data (2000–2023). Key outputs: regression tables, robustness checks, mediation analysis, and methodological explorations.

## File Structure (high level)

- `data/` — processed and raw data (see `data/02-analysis_data/` for analysis-ready files).
- `scripts/` — R scripts to reproduce processing, analyses, and figures. Run scripts in numeric order.
- `output/` — generated tables, figures, and model objects.
- `paper/` — Quarto manuscript (`paper.qmd`) and BibTeX references.

## How to reproduce (minimal)

1. Obtain raw data (V-Dem, DPI, QOG, World Bank WDI) and place in `data/01-raw_data/` per filenames expected by the scripts.
2. Run scripts in order from the `scripts/` folder:

```
Rscript scripts/01-download_data.R   # optional: downloads auxiliary public data
Rscript scripts/02-clean_data.R      # processes and merges raw data into analysis files
Rscript scripts/03-model_data.R      # fits main models and writes main tables
Rscript scripts/04-robustness_checks.R
Rscript scripts/05-mediation_analysis.R
Rscript scripts/06-advanced_methods.R
Rscript scripts/07-crossover_ci.R
```

Outputs (examples): `output/tables/`, `output/figures/`, `output/robustness/`.

## Codebook (selected key variables)

- `country_name`: Country name (ISO-standardized after cleaning).
- `year`: Calendar year (2000–2023).
- `system_type`: Government system; levels: `Parliamentary` (reference), `Semi-Presidential`, `Presidential`.
- `volatility`: Dependent variable — SD of liberal democracy scores over the observation window.
- `total_decline`: Sum of year-over-year decreases in the democracy index.
- `log_gdp`: GDP per capita (PPP) in natural logs.
- `mean_democracy`: Average democracy level (2000–2023).
- `ethnic_frac`: Ethnic fractionalization (from QOG processing).

For additional variables and exact processing steps, inspect `scripts/02-clean_data.R` and `scripts/03-model_data.R`.

## Data provenance and reproduction details

- V-Dem v15 (register at https://v-dem.net)
- DPI (Database of Political Institutions)
- QOG (Quality of Government)
- World Bank WDI (GDP per capita)

Processed analysis files are stored in `data/02-analysis_data/`. See `scripts/02-clean_data.R` for exact transformations.

## Author Notes (short)

- The bootstrap CI for the GDP crossover is wide; present directional interpretation rather than a precise dollar threshold.

## Where to look for specific docs

- Variable descriptions and codebook: `scripts/03-model_data.R` and this `DOCS.md`.
- Reproducible run order and script list: `scripts/` directory and the short run commands above.

---
Last updated: 2026-01-06
