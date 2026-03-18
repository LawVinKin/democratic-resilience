# Economic Development and Democratic Stability in Presidential and Parliamentary Systems (2000–2023)

This repository contains code and data for the aforementioned paper. The project analyzes how government system type and economic development affect democratic stability across 100+ countries. All code, data, and replication materials are included.

**To reproduce:**
1. Install R (≥ 4.0) and Quarto
2. Install required R packages
3. Run:
	- `Rscript scripts/01_data_processing.R`
	- `Rscript scripts/02_analysis.R`
	- `Rscript scripts/03_robustness.R`
	- `quarto render paper/paper.qmd`

See the main paper in `paper/paper.qmd` and the codebook in `data/02-analysis_data/CODEBOOK.md` for details.

License: MIT (code); data per original sources
