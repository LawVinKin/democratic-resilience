# Codebook: Democratic Resilience Project

## Overview

This codebook documents all variables and methods used in the paper. The analysis examines how government system types affect democratic stability across 100+ countries from 2000–2023.

## Data Sources

| Source | Description | Years | URL |
|--------|-------------|-------|-----|
| V-Dem v15 | Varieties of Democracy indicators | 2000–2023 | https://v-dem.net |
| DPI 2020 | Database of Political Institutions | 2020 | World Bank |
| QOG | Quality of Government Standard Dataset | January 2025 | https://qog.pol.gu.se |
| World Bank WDI | World Development Indicators | 2000–2023 | World Bank |

## File Structure

### Raw Data (`data/01-raw_data/`)
- `V-Dem-CY-Full+Others-v15.csv` — V-Dem democracy indicators (full dataset)
- `dpi2020.xlsx` — Government system classifications
- `qog_std_cs_jan25.csv` — Quality of Government control variables

### Analysis Data (`data/02-analysis_data/`)
- `analytical_sample.rds` — **Main analytical dataset** (cross-sectional, N ≈ 100 countries)
- `stability_measures.csv` — Dependent variables (volatility, decline, episodes)
- `merged_all_years.csv` — Panel dataset (country-years, 2000–2023)
- `vdem_2000_2023.csv` — Filtered V-Dem data
- `dpi_processed.csv` — Processed system type classifications
- `gdp_processed.csv` — GDP per capita (PPP)
- `qog_processed.csv` — Control variables

---

## Variables in `analytical_sample.rds` (Main Dataset)

### Dependent Variables: Democratic Stability Measures

| Variable | Type | Description | Range |
|----------|------|-------------|-------|
| `volatility` | Continuous | Standard deviation of V-Dem liberal democracy index (2000–2023). **Primary outcome.** Higher values = greater instability. | 0–1 |
| `total_decline` | Continuous | Sum of all year-over-year *decreases* in liberal democracy score. Captures only democratic erosion, not improvement. | 0+ |
| `n_declines` | Count | Number of year-over-year declines (any magnitude) | 0+ |
| `n_episodes` | Count | Number of major backsliding episodes (drops > 0.05) | 0+ |
| `had_backsliding` | Binary | Any major backsliding episode (1 = yes) | 0, 1 |

**Important methodological note**: The primary measure (`volatility`) uses standard deviation, which could potentially "penalize" countries that have steadily *improved* their democracy scores. A country on a positive democratic trajectory would show high variance despite experiencing no instability. We address this by:
1. Including `mean_democracy` as a control variable
2. Using `total_decline` (which captures only negative changes) for robustness checks
3. Examining `n_episodes` to identify substantively meaningful erosion

### Independent Variables

| Variable | Type | Description | Coding |
|----------|------|-------------|--------|
| `system_type` | Factor | Government system type | Parliamentary (reference), Semi-Presidential, Presidential |
| `log_gdp` | Continuous | Log GDP per capita (PPP, constant 2017 $) | Mean 2000–2023 |

### Control Variables

| Variable | Type | Description | Source | Range |
|----------|------|-------------|--------|-------|
| `mean_democracy` | Continuous | Mean V-Dem liberal democracy index (2000–2023) | V-Dem | 0–1 |
| `ethnic_frac` | Continuous | Ethnic fractionalization index | QOG | 0–1 |

### Identifiers

| Variable | Description |
|----------|-------------|
| `country_name` | Country name (V-Dem convention) |
| `iso3c` | ISO 3-letter country code |

---

## Variables in `merged_all_years.csv` (Panel Data)

### Core Democracy Measures (V-Dem)

| Variable | Description | Range |
|----------|-------------|-------|
| `v2x_libdem` | Liberal democracy index (main DV source) | 0–1 |
| `v2x_polyarchy` | Electoral democracy index | 0–1 |
| `v2x_regime` | Regime type classification | Categorical |

### Institutional Constraints

| Variable | Description |
|----------|-------------|
| `v2x_jucon` | Judicial constraints on executive |
| `v2xlg_legcon` | Legislative constraints on executive |
| `v2x_horacc` | Horizontal accountability |
| `v2x_diagacc` | Diagonal accountability |

### Rights and Freedoms

| Variable | Description |
|----------|-------------|
| `v2x_pubcorr` | Public sector corruption |
| `v2x_freexp` | Freedom of expression |
| `v2x_frassoc_thick` | Freedom of association |
| `v2x_clphy` | Civil liberties (physical integrity) |
| `v2x_civsoc` | Civil society participation |

---

## Variable Construction Details

### Volatility (Main DV)
```r
volatility = sd(v2x_libdem)  # Standard deviation across 2000–2023
```
- Requires minimum 20 years of non-missing data
- Range: 0–1 (higher = more volatile)
- **Interpretation**: Captures overall variability in democratic quality, regardless of direction

### Total Decline (Alternative DV)
```r
change[t] = v2x_libdem[t] - v2x_libdem[t-1]
total_decline = sum(|change[t]| where change[t] < 0)
```
- Captures cumulative magnitude of democratic *erosion only*
- Range: 0+ (higher = more decline)
- **Interpretation**: Isolates negative changes from improvements

### Backsliding Episodes
```r
major_decline = (change < -0.05)
n_episodes = sum(major_decline)
```
- Threshold of 0.05 follows convention in backsliding literature (e.g., Lührmann & Lindberg 2019)
- **Interpretation**: Counts substantively meaningful erosion events

### GDP per Capita
```r
gdp_pc_mean = mean(NY.GDP.PCAP.PP.KD, 2000–2023)
log_gdp = log(gdp_pc_mean)
```
- Source: World Bank WDI indicator `NY.GDP.PCAP.PP.KD`
- Constant 2017 international $, PPP
- Log transformation reduces skewness

---

## Government System Type Classification

Based on DPI 2020 `system` variable:

| DPI Value | Our Classification | Description |
|-----------|-------------------|-------------|
| "Presidential" | Presidential | Directly elected executive independent of legislature |
| "Parliamentary" | Parliamentary | Executive dependent on legislative confidence |
| "Assembly-Elected President" | Semi-Presidential | Directly elected president + PM dependent on legislature |

**Country-specific ISO code corrections:**
| Original Name | Corrected ISO3 |
|---------------|----------------|
| Cent. Af. Rep. | CAF |
| PRC | CHN |
| Dom. Rep. | DOM |
| ROK | KOR |
| PRK | PRK |
| S. Africa | ZAF |

---

## Sample Selection Criteria

Countries are included if they meet all criteria:

1. **Time coverage**: Minimum 20 years of non-missing V-Dem democracy scores (2000–2023)
2. **System type**: Valid DPI government system classification
3. **GDP data**: Non-missing World Bank GDP data
4. **Controls**: Non-missing ethnic fractionalization data

**Final sample**: Approximately 100 countries

---

## Missing Data Handling

| Variable | Handling Rule |
|----------|---------------|
| Volatility | Countries with <20 years excluded from sample |
| Total decline | Set to 0 for countries with no declines |
| n_episodes | Set to 0 for countries with no episodes |
| had_backsliding | Set to FALSE for countries with no episodes |
| GDP | Countries without WDI data excluded |
| System type | Countries without DPI classification excluded |
| Ethnic fractionalization | Countries without QOG data excluded |

---

## Measurement Considerations

### Why Standard Deviation as Primary Measure?

The choice of standard deviation as the primary measure of democratic instability reflects our theoretical focus on *volatility* rather than purely *decline*. Democratic resilience encompasses both:
- Resistance to erosion (avoiding declines)
- Consistency in democratic quality (avoiding fluctuations)

However, we recognize that standard deviation alone could conflate improvement with instability. Our multi-measure approach addresses this:
1. **Volatility** (SD) — Main measure: captures overall variability
2. **Total Decline** — Robustness: captures erosion only
3. **Backsliding Episodes** — Robustness: captures major drops

### Why 20-Year Minimum?

The 20-year threshold ensures:
- Sufficient observations for stable volatility estimates
- Focus on consolidated regimes rather than transient democracies
- Coverage of multiple electoral cycles

### Why 0.05 Threshold for Episodes?

The 0.05 threshold (5% of the 0–1 scale) follows Lührmann & Lindberg (2019) and represents a substantively meaningful decline—approximately one standard deviation of year-to-year changes in the global sample.

---

## Reproducibility

### Recreate Analytical Sample
```r
source("scripts/01_data_processing.R")
data <- readRDS("data/02-analysis_data/analytical_sample.rds")
```

### Reproduce Main Analysis
```r
Rscript scripts/01_data_processing.R
Rscript scripts/02_analysis.R
Rscript scripts/03_robustness.R
Rscript scripts/04_mechanisms.R
```

---

## Version Information

| Component | Version | Access Date |
|-----------|---------|-------------|
| V-Dem | v15 | 2026 |
| DPI | 2020 | 2026 |
| QOG | Standard Dataset January 2025 | 2026 |
| WDI | Current | 2026 |
| Codebook | 1.0 | 2026-03-05 |

---

## References

- Lührmann, Anna, and Staffan I. Lindberg. 2019. "A Third Wave of Autocratization is Here: What is New About It?" *Democratization* 26(7): 1095–1113.
- Coppedge, Michael, et al. 2024. "V-Dem Codebook v15." Varieties of Democracy Project.
- Beck, Thorsten, et al. 2001. "New Tools in Comparative Political Economy: The Database of Political Institutions." *World Bank Economic Review* 15(1): 165–176.

---

## Contact

For questions about data or codebook, please file an issue on GitHub: https://github.com/LawVinKin/democratic-resilience
