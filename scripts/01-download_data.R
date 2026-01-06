# This script downloads all the relevant data

library(tidyverse)
library(countrycode)
library(readxl)
library(WDI)

# V-dem
vdem_raw <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/01-raw_data/V-Dem-CY-Full+Others-v15.csv")

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

# The follwoing finds variables that exist in both the desired list and the dataset
existent_variables <- intersect(variables_of_interest, names(vdem_raw))

vdem_filtered <- vdem_raw %>%
  select(existent_variables) %>%
  filter(year >= 2000 & year <= 2023)

write_csv(vdem_filtered, "/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/vdem_2000_2023.csv")


# Dpi 
dpi_raw <- read_excel("/Users/shahin/Documents/GitHub/projects-template/data/01-raw_data/dpi2020.xlsx")

dpi_selected <- dpi_raw %>%
  select(countryname, year, system)

dpi_with_types <- dpi_selected %>%
  mutate(
    year_num = lubridate::year(year),  # extracts year from date
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
    iso3c = case_when( # We're modifying some country codes that countrycode package does not handle well to the ones that it does handle well
      countryname == "Cent. Af. Rep." ~ "CAF",
      countryname == "PRC" ~ "CHN",
      countryname == "Dom. Rep." ~ "DOM",
      countryname == "ROK" ~ "KOR",
      countryname == "PRK" ~ "PRK", # PRK is not recognized by countrycode, so we manually set it to PRK
      countryname == "S. Africa" ~ "ZAF",
      TRUE ~ iso3c))

write_csv(dpi_processed, "/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/dpi_processed.csv")

# World bank (for gdp)
gdp_raw <- WDI(
  indicator = "NY.GDP.PCAP.PP.KD",   # This is the code fo GDP per capita (constant 2017 international $, PPP)
  start = 2000, end = 2023,
  extra = TRUE)   # Includes extra metadata like country names

gdp_processed <- gdp_raw %>%
  filter(!is.na(NY.GDP.PCAP.PP.KD)) %>%
  group_by(iso3c, country) %>%
  summarise(
    gdp_pc_mean = mean(NY.GDP.PCAP.PP.KD),
    log_gdp_mean = log(gdp_pc_mean)) %>%
  ungroup()

write_csv(gdp_processed, "/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/gdp_processed.csv")


# QOG data (which are mostly control variables)
qog_raw <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/01-raw_data/qog_std_cs_jan25.csv")

qog_processed <- qog_raw %>%
  select(cname, ccodealp, fe_etfra) %>% #the variable names in the raw file
  rename(
    country_name_qog = cname,
    iso3c = ccodealp,
    ethnic_frac = fe_etfra)

write_csv(qog_processed, "/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/qog_processed.csv")
