library(tidyverse)
library(countrycode)
library(readxl)
library(WDI)
library(here)

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

dpi_raw <- read_excel(here("data", "01-raw_data", "dpi2020.xlsx"))

dpi_selected <- dpi_raw %>%
  select(countryname, year, system)

dpi_with_types <- dpi_selected %>%
  mutate(
    year_num = lubridate::year(year),
    system_type = case_when(
      system == "Presidential" ~ "Presidential",
      system == "Parliamentary" ~ "Parliamentary",
      system == "Assembly-Elected President" ~ "Semi-Presidential",
      TRUE ~ NA_character_))

dpi_filtered <- dpi_with_types %>%
  filter(year_num == max(year_num)) %>%
  filter(!is.na(system_type))

dpi_reselected <- dpi_filtered %>%
  select(countryname, system_type)

dpi_processed <- dpi_reselected %>%
  mutate(
    iso3c = countrycode(countryname, "country.name", "iso3c", warn = FALSE),
    iso3c = case_when(
      countryname == "Cent. Af. Rep." ~ "CAF",
      countryname == "PRC" ~ "CHN",
      countryname == "Dom. Rep." ~ "DOM",
      countryname == "ROK" ~ "KOR",
      countryname == "PRK" ~ "PRK",
      countryname == "S. Africa" ~ "ZAF",
      TRUE ~ iso3c))

write_csv(dpi_processed, here("data", "02-analysis_data", "dpi_processed.csv"))

gdp_raw <- WDI(
  indicator = "NY.GDP.PCAP.PP.KD",
  start = 2000, end = 2023,
  extra = TRUE)

gdp_processed <- gdp_raw %>%
  filter(!is.na(NY.GDP.PCAP.PP.KD)) %>%
  group_by(iso3c, country) %>%
  summarise(
    gdp_pc_mean = mean(NY.GDP.PCAP.PP.KD),
    log_gdp_mean = log(gdp_pc_mean),
    .groups = "drop")

write_csv(gdp_processed, here("data", "02-analysis_data", "gdp_processed.csv"))

qog_raw <- read_csv(here("data", "01-raw_data", "qog_std_cs_jan25.csv"))

qog_processed <- qog_raw %>%
  select(cname, ccodealp, fe_etfra) %>%
  rename(
    country_name_qog = cname,
    iso3c = ccodealp,
    ethnic_frac = fe_etfra)

write_csv(qog_processed, here("data", "02-analysis_data", "qog_processed.csv"))

vdem <- read_csv(here("data", "02-analysis_data", "vdem_2000_2023.csv"))
dpi <- read_csv(here("data", "02-analysis_data", "dpi_processed.csv"))
qog <- read_csv(here("data", "02-analysis_data", "qog_processed.csv"))

vdem_with_iso <- vdem %>%
  mutate(iso3c = countrycode(country_name, "country.name", "iso3c"))

merged_panel <- vdem_with_iso %>%
  left_join(dpi, by = "iso3c") %>%
  left_join(qog, by = "iso3c")

write_csv(merged_panel, here("data", "02-analysis_data", "merged_all_years.csv"))
saveRDS(merged_panel, here("data", "02-analysis_data", "merged_all_years.rds"))

stability_sd <- merged_panel %>%
  group_by(country_name, iso3c) %>%
  summarize(
    volatility = sd(v2x_libdem),
    mean_democracy = mean(v2x_libdem),
    n_years = sum(!is.na(v2x_libdem)),
    .groups = "drop") %>%
  filter(n_years >= 20)

stability_decline <- merged_panel %>%
  group_by(country_name, iso3c) %>%
  arrange(year) %>%
  mutate(change = v2x_libdem - lag(v2x_libdem)) %>%
  filter(change < 0) %>%
  summarize(
    total_decline = sum(abs(change)),
    avg_decline = mean(abs(change)),
    n_declines = n(),
    .groups = "drop")

stability_episodes <- merged_panel %>%
  group_by(country_name, iso3c) %>%
  arrange(year) %>%
  mutate(
    change = v2x_libdem - lag(v2x_libdem),
    major_decline = change < -0.05) %>%
  summarize(
    had_backsliding = any(major_decline),
    n_episodes = sum(major_decline),
    .groups = "drop")

stability_all <- stability_sd %>%
  left_join(stability_decline, by = c("country_name", "iso3c")) %>%
  left_join(stability_episodes, by = c("country_name", "iso3c")) %>%
  mutate(
    total_decline = replace_na(total_decline, 0),
    n_declines = replace_na(n_declines, 0),
    n_episodes = replace_na(n_episodes, 0),
    had_backsliding = replace_na(had_backsliding, FALSE))

write_csv(stability_all, here("data", "02-analysis_data", "stability_measures.csv"))

gdp <- read_csv(here("data", "02-analysis_data", "gdp_processed.csv")) %>%
  select(iso3c, log_gdp_mean)

analytical_sample <- stability_all %>%
  left_join(dpi, by = "iso3c") %>%
  left_join(qog, by = "iso3c") %>%
  left_join(gdp, by = "iso3c") %>%
  mutate(
    system_type = factor(system_type, levels = c("Parliamentary", "Semi-Presidential", "Presidential")),
    log_gdp = log_gdp_mean) %>%
  filter(!is.na(system_type) & !is.na(volatility) & !is.na(log_gdp))

saveRDS(analytical_sample, here("data", "02-analysis_data", "analytical_sample.rds"))
