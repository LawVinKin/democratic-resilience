```markdown
# Parliamentary Resilience: Government Systems and Democratic Stability

## Quick summary

This repository accompanies an analysis of how government system types (Parliamentary, Presidential, Semi‑Presidential) relate to democratic stability across countries (2000–2023). The canonical project documentation (data provenance, full codebook, and run order) has been consolidated into `DOCS.md`; see that file for details.

## Short repo guide

- `data/` — raw and processed data. Analysis-ready files live in `data/02-analysis_data/`.
- `scripts/` — numbered R scripts to reproduce the analysis. Run them in numeric order.
- `output/` — generated tables, figures, and model objects.
- `paper/` — Quarto manuscript and references.

## Reproduce (minimal)

1. Place raw data (V-Dem, DPI, QOG, World Bank WDI) in `data/01-raw_data/` using the expected filenames described in `DOCS.md`.
2. Run scripts in order (examples):

```bash
Rscript scripts/02-clean_data.R
Rscript scripts/03-model_data.R
Rscript scripts/04-robustness_checks.R
Rscript scripts/05-mediation_analysis.R
Rscript scripts/06-advanced_methods.R
Rscript scripts/07-crossover_ci.R
```

For a complete run-order and file-level details, see `DOCS.md`.

## Essential notes

- Key dependent variables include `volatility` (SD of democracy scores) and `total_decline` (sum of year-over-year declines). Exact definitions and preprocessing steps are in `scripts/02-clean_data.R` and `DOCS.md`.
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
```
# Parliamentary Resilience: Government Systems and Democratic Stability

## Overview

This project investigates the relationship between government system types (Parliamentary, Presidential, Semi-Presidential) and democratic stability. Using cross-national panel data from 2000-2023, we analyze how different institutional arrangements affect democratic volatility and resilience to backsliding. Key findings suggest that parliamentary systems demonstrate greater stability, with the effect moderated by GDP per capita.

## File Structure

The repo is structured as follows:

### `data/`
-   `00-simulated_data/` contains simulated data used to test the analysis pipeline.
-   `01-raw_data/` contains the raw data sources:
    - `V-Dem-CY-Full+Others-v15.csv` - V-Dem democracy indicators (2000-2023)
    - `dpi2020.xlsx` - Database of Political Institutions (government system types)
    - `qog_std_cs_jan25.csv` - Quality of Government data (control variables)
-   `02-analysis_data/` contains the processed and merged datasets:
    - `vdem_2000_2023.csv` - Filtered V-Dem data
    - `dpi_processed.csv` - Processed DPI system type classifications
    - `gdp_processed.csv` - World Bank GDP per capita data
    - `qog_processed.csv` - QOG control variables (ethnic fractionalization)
    - `merged_all_years.csv` - Panel dataset merged from all sources
    - `stability_measures.csv` - Computed dependent variables (volatility, decline)

### `scripts/`  
-   `01-download_data.R` - Downloads and processes all raw data (V-Dem, DPI, GDP, QOG)
-   `02-clean_data.R` - Merges datasets and creates dependent variables (volatility, decline)
-   `03-model_data.R` - Main regression analysis with interaction models and publication tables
-   `04-robustness_checks.R` - Alternative DVs and subsample analyses
-   `05-mediation_analysis.R` - Causal mediation analysis testing theoretical mechanisms
-   `06-advanced_methods.R` - Methodological innovations (MWI estimator)

### `output/`
-   `tables/` regression tables in HTML and Word formats
-   `figures/` coefficient plots and main findings visualizations
-   `mediation/` mediation analysis results (.rds files)

### `models/`
-   Saved model objects (.rds files)

### `paper/` 
-   `paper.qmd` Quarto manuscript
-   `references.bib` Citations
-   `fonts/` LaTeX font assets
-   `styles/` Citation style formatting

### `other/`
-   Supplementary materials including notes, datasheets, and sketches

## Key Variables

**Dependent Variables:**
- `volatility` - Standard deviation of liberal democracy scores (2000-2023)
- `total_decline` - Sum of year-over-year decreases in democracy
- `n_episodes` - Count of major backsliding episodes (>0.05 drop)

**Main Independent Variable:**
- `system_type` - Parliamentary (reference), Semi-Presidential, Presidential

**Controls:**
- `log_gdp` - Log GDP per capita (PPP)
- `mean_democracy` - Mean democracy level (2000-2023)
- `ethnic_frac` - Ethnic fractionalization
- `monarchy` - Constitutional monarchy indicator

## Pre-requisites

### R Packages Required:
```r
install.packages(c(
  "tidyverse", "here", "readxl", "countrycode",
  "WDI", "sandwich", "lmtest", "modelsummary",
  "flextable", "officer", "stargazer", "skimr"
))
```

## Data Sources

- **V-Dem v15**: Varieties of Democracy dataset (https://v-dem.net)
- **DPI 2020**: Database of Political Institutions (World Bank)
- **QOG**: Quality of Government Standard Dataset (https://qog.pol.gu.se)
- **World Bank WDI**: GDP per capita indicators
