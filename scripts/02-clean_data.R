# Clean and Merge Data
# Purpose: Merge all processed datasets and create dependent variables
# Author: [Your Name]
# Contact: [Your Email]

library(tidyverse)
library(here)
library(countrycode)

# Load all processed datasets
vdem <- read_csv(here("data", "02-analysis_data", "vdem_2000_2023.csv"))
dpi <- read_csv(here("data", "02-analysis_data", "dpi_processed.csv"))
qog <- read_csv(here("data", "02-analysis_data", "qog_processed.csv"))

# Add ISO codes to V-Dem for merging
vdem <- vdem %>%
  mutate(iso3c = countrycode(country_name, "country.name", "iso3c"))

# Merge datasets
merged <- vdem %>%
  left_join(dpi, by = "iso3c") %>%
  left_join(qog, by = "iso3c")

# Save merged panel
write_csv(merged, here("data", "02-analysis_data", "merged_all_years.csv"))
saveRDS(merged, here("data", "02-analysis_data", "merged_all_years.rds"))


# Create Dependent Variables (Country-level stability measures)

# Measure 1: Volatility (standard deviation of democracy scores)
stability_sd <- merged %>%
  group_by(country_name, iso3c) %>%
  summarize(
    volatility = sd(v2x_libdem, na.rm = TRUE),
    mean_democracy = mean(v2x_libdem, na.rm = TRUE),
    n_years = sum(!is.na(v2x_libdem)),
    .groups = "drop"
  ) %>%
  filter(n_years >= 20)

# Measure 2: Total decline (sum of year-over-year decreases)
stability_decline <- merged %>%
  group_by(country_name, iso3c) %>%
  arrange(year) %>%
  mutate(change = v2x_libdem - lag(v2x_libdem)) %>%
  filter(change < 0) %>%
  summarize(
    total_decline = sum(abs(change)),
    avg_decline = mean(abs(change)),
    n_declines = n(),
    .groups = "drop"
  )

# Measure 3: Backsliding episodes (>0.05 drops)
stability_episodes <- merged %>%
  group_by(country_name, iso3c) %>%
  arrange(year) %>%
  mutate(
    change = v2x_libdem - lag(v2x_libdem),
    major_decline = change < -0.05
  ) %>%
  summarize(
    had_backsliding = any(major_decline, na.rm = TRUE),
    n_episodes = sum(major_decline, na.rm = TRUE),
    .groups = "drop"
  )

# Monarchy indicator
monarchy_flag <- merged %>%
  group_by(country_name, iso3c) %>%
  summarise(
    monarchy = as.numeric(mean(v2exl_legitlead, na.rm = TRUE) == 1),
    .groups = "drop"
  )

# Combine all stability measures
stability_all <- stability_sd %>%
  left_join(stability_decline, by = c("country_name", "iso3c")) %>%
  left_join(stability_episodes, by = c("country_name", "iso3c")) %>%
  left_join(monarchy_flag, by = c("country_name", "iso3c")) %>%
  mutate(
    total_decline = replace_na(total_decline, 0),
    n_declines = replace_na(n_declines, 0),
    n_episodes = replace_na(n_episodes, 0),
    had_backsliding = replace_na(had_backsliding, FALSE)
  )

# Check correlations between stability measures
cor_matrix <- stability_all %>%
  select(volatility, total_decline, n_episodes) %>%
  cor(use = "complete.obs") %>%
  round(3)

write_csv(stability_all, here("data", "02-analysis_data", "stability_measures.csv"))
