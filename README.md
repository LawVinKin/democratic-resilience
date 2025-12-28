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

## Statement on LLM usage

This project was developed with the assistance of LLMs (GitHub Copilot) for:
- Code debugging and error messaging
- Documentation and commenting
- Table formatting for publication

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

## Acknowledgements

[Add acknowledgements here]
