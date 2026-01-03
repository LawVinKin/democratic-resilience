CODEBOOK for "Parliamentary Resilience: Government Systems and Democratic Stability"

This file describes the main variables used in the analysis and where they are stored.

Key variables (in `data/02-analysis_data/merged_all_years.csv` and `stability_measures.csv`)

- `country_name`: Country name (ISO-standardized in processing).
- `year`: Calendar year (2000-2023).
- `system_type`: Factor indicating government system; levels include `Parliamentary`, `Presidential`, and `Semi-Presidential` (constructed from DPI and coded in `scripts/02-clean_data.R`).
- `volatility`: Main DV measuring year-to-year volatility in the V-Dem liberal democracy index (computed as annualized standard deviation over rolling windows; see `scripts/03-model_data.R`).
- `decline_sum`: Alternative DV; sum of year-over-year declines in the democracy index over the period of observation.
- `log_gdp`: GDP per capita (PPP) in logs; source: World Bank WDI processed in `scripts/01-download_data.R`.
- `mean_democracy`: Mean democracy score (V-Dem index) over a baseline period, used as a control.
- `ethnic_frac`: Ethnic fractionalization (from QOG/DPI processed file).

Additional variables and transformations are documented in `scripts/03-model_data.R`. If you need a variable not described here, open the script and the specific processing steps are annotated.
