````markdown
DATA_README for "Parliamentary Resilience: Government Systems and Democratic Stability"

Overview
--------
This repository includes processed analysis-ready data used in the paper. Raw data sources (V-Dem, DPI, QOG, World Bank WDI) are not redistributed here due to licensing and size; instead provenance and instructions to obtain the raw data are provided below.

Included processed files (in `data/02-analysis_data/`)
- `vdem_2000_2023_comprehensive_plus.csv` — merged and harmonized V-Dem indicators used to compute democracy volatility measures.
- `stability_measures.csv` — country-level volatility and decline measures used as the main dependent variables.
- `merged_all_years.csv` — the pooled year-country panel used for event-time analyses and robustness checks.
- Other auxiliary processed files used by scripts are listed in the `data/02-analysis_data/` folder.

How to reproduce
----------------
1. Obtain raw V-Dem data (v15) from: https://www.v-dem.net/en/data/data/v-dem-dataset-v15/
   - You must register and accept V-Dem terms. Do not redistribute the raw V-Dem dataset.
2. Place the raw V-Dem CSV in `data/01-raw_data/` (file name expected by scripts: `V-Dem-CY-Full+Others-v15.csv`).
3. Run the processing scripts in order:

```bash
# from repository root
Rscript scripts/01-download_data.R   # (optional; downloads public auxiliary data)
Rscript scripts/02-clean_data.R      # cleans raw files and produces files in data/02-analysis_data
Rscript scripts/03-model_data.R      # constructs analysis datasets used for models
```

4. Run model and robustness scripts to recreate tables and figures:

```bash
Rscript scripts/04-robustness_checks.R
Rscript scripts/05-mediation_analysis.R
# or run run_all.R (provided) to execute full pipeline
```

Licensing and attribution
-------------------------
- V-Dem: Please cite V-Dem as follows in any reuse: Coppedge, Michael et al. (2024). V-Dem Dataset v15. Varieties of Democracy (V-Dem) Project. https://www.v-dem.net
- DPI (Database of Political Institutions) and QOG: cite appropriately as in their documentation.

Included processed derivatives are provided under CC-BY (unless you request CC-BY-NC). Raw proprietary datasets (V-Dem full CSV) are not included and must be obtained from their owners.

Contact
-------
For questions about reproducing results, contact Lawrence Vincent King (email in `paper/paper.qmd`).

````
