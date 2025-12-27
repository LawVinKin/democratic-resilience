# The Evolution of Neighbourhood Crime in Toronto (2019–2024): A Cluster Analysis Across Socioeconomic Opportunity Levels

## Overview

This paper examines how Toronto’s neighbourhood-level crime patterns evolved during the pandemic and its aftermath. We analyze official crime rates for Toronto’s neighbourhoods from 2019 through 2024, assessing how pre-existing social and economic inequalities shaped divergent crime trends. Specifically, we classify Toronto neighbourhoods into Low-, Medium-, and High-Opportunity clusters via $K$-means clustering on socioeconomic proxies and compare the crime trajectories of these clusters over time. The analysis, conducted in Python, utilizes the City of Toronto's neighbourhood crime data (2019–2024) and Canadian Census data (2021) attained from the Open Data Toronto Portal.


## File Structure

The repo is structured as follows:

### `data/`
-   `00-simulated_data` contains simulated data used to test the analysis pipeline.
-   `01-raw_data` contains the raw data as obtained from [City of Toronto Open Data](https://open.toronto.ca/).
-   `02-analysis_data` contains the cleaned datasets that were constructed.
-   `03-table_data` contains formatted data tables used to generate Quarto outputs.

### `scripts/`  
-   `00.0-run_pipeline.py` executes the entire data processing pipeline from simulation to final outputs.
-   `01.0-simulate_data.py` generates synthetic datasets to test logic.
-   `01.1-simulated_data_test.py` tests the structure of the simulated data.
-   `02.0-download_data.py`  downloads the raw neighbourhood crime counts (2019–2024) and Census socioeconomic indicators (2021) from the City of Toronto's Open Data Portal.
-   `03.0-clean_crime_data.py` preprocesses the raw crime data.
-   `03.1-clean_profile_data.py` preprocesses the raw Census data.
-   `04.0-merge_crime_profile.py` join the cleaned crime and profile datasets on neighbourhood identifiers.
-   `04.1-merged_test.py` tests the structure of the simulated data
-   `05-0-eda_neighbourhood_clusters.py` performs exploratory data analysis on socioeconomic proxies, calculates descriptive statistics, and inspects clustering diagnostics.
-   `06.0-table_crime_clusters.py` aggregates annual crime rates by cluster (Low-, Medium-, High-Opportunity) and exports formatted tables.
-   `07.0-plot_crime_clusters.py` creates visualizations of crime trajectories over time for each cluster.
-   `08.0-model_evaluation.py` compares clustering algorithms (K-means vs. Gaussian Mixture Models) using metrics Silhouette Score, Davies–Bouldin Index, and Calinski–Harabasz Score.

### `paper/` 
-   `paper.qmd` Quarto manuscript.  
-   `references.bib` Citations. 
-   `paper.pdf` Compiled PDF.  
-   `fonts/` LaTex font assets (CM Serif).
-   `styles/` APA 7 style formatting for Quarto.  

### `other/`
-   Supplementary materials including figures, literature, notes, and development sketches.

## Statement on LLM usage

This project was developed with the assistance of LLMs. 

**1. AI-assisted code completion** (e.g., GitHub Copilot, Qodo Gen) was used throughout development.  
**2. Prompt-based support** via the `04-mini-high` model aided in:  
   - Error messaging and debugging within selected scripts;  
   - Refining mathematical notation and function documentation;  
   - Formatting the Quarto manuscript.

## Pre-requisites
-   Install required Python packages as specified in `uv.lock`.  
-   Run all tests with `pytest`.
