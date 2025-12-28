# Download Data
# Purpose: Load and process all raw data sources (V-Dem, DPI, GDP, QOG)
# Author: [Your Name]
# Contact: [Your Email]

library(tidyverse)
library(here)
library(countrycode)
library(readxl)
library(WDI)

# 1. Load V-Dem Data
vdem_raw <- read_csv(here("data", "01-raw_data", "V-Dem-CY-Full+Others-v15.csv"))

variables_of_interest <- c(
  "country_name", "country_text_id", "country_id", "year",
  "v2x_libdem", "v2x_polyarchy", "v2x_regime",
  "v2x_jucon", "v2xlg_legcon", "v2x_horacc", "v2x_diagacc",
  "v2x_pubcorr", "v2x_freexp", "v2x_frassoc_thick", "v2x_clphy",
  "v2pepwrsoc", "v2x_civsoc", "v2x_client", "v2x_suffr",
  "v2x_parties", "v2x_feduni",
  "v2x_elecoff", "v2xel_frefair",
  "v2x_accountability", "v2x_veracc",
  "v2x_state", "v2x_rulse",
  "v2exl_legitlead", "v2expathhg"
)

existent_variables <- intersect(variables_of_interest, names(vdem_raw))

vdem_filtered <- vdem_raw %>%
  select(all_of(existent_variables)) %>%
  filter(year >= 2000 & year <= 2023)

write_csv(vdem_filtered, here("data", "02-analysis_data", "vdem_2000_2023.csv"))


# 2. Load DPI Data (Government System Types)
dpi_raw <- read_excel(here("data", "01-raw_data", "dpi2020.xlsx"))

dpi_processed <- dpi_raw %>%
  select(countryname, year, system) %>%
  mutate(
    year_num = lubridate::year(year),
    system_type = case_when(
      system == "Presidential" ~ "Presidential",
      system == "Parliamentary" ~ "Parliamentary",
      system == "Assembly-Elected President" ~ "Semi-Presidential",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(year_num == max(year_num), !is.na(system_type)) %>%
  select(countryname, system_type) %>%
  mutate(
    iso3c = countrycode(countryname, "country.name", "iso3c", warn = FALSE),
    iso3c = case_when(
      countryname == "Cent. Af. Rep." ~ "CAF",
      countryname == "PRC" ~ "CHN",
      countryname == "Dom. Rep." ~ "DOM",
      countryname == "ROK" ~ "KOR",
      countryname == "PRK" ~ "PRK",
      countryname == "S. Africa" ~ "ZAF",
      TRUE ~ iso3c
    )
  )

write_csv(dpi_processed, here("data", "02-analysis_data", "dpi_processed.csv"))


# 3. Download World Bank GDP Data
gdp_raw <- WDI(
  indicator = "NY.GDP.PCAP.PP.KD",
  start = 2000, end = 2023,
  extra = TRUE
)

gdp_processed <- gdp_raw %>%
  filter(!is.na(NY.GDP.PCAP.PP.KD)) %>%
  group_by(iso3c, country) %>%
  summarise(
    gdp_pc_mean = mean(NY.GDP.PCAP.PP.KD, na.rm = TRUE),
    log_gdp_mean = log(gdp_pc_mean),
    .groups = "drop"
  )

write_csv(gdp_processed, here("data", "02-analysis_data", "gdp_processed.csv"))


# 4. Load QOG Data (Control Variables)
qog_raw <- read_csv(here("data", "01-raw_data", "qog_std_cs_jan25.csv"))

qog_processed <- qog_raw %>%
  select(cname, ccodealp, fe_etfra) %>%
  rename(
    country_name_qog = cname,
    iso3c = ccodealp,
    ethnic_frac = fe_etfra
  )

write_csv(qog_processed, here("data", "02-analysis_data", "qog_processed.csv"))
