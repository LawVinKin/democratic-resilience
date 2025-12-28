# Advanced Methods
# Purpose: Methodological innovations including MWI estimator and RDD analysis
# Author: [Your Name]
# Contact: [Your Email]

library(tidyverse)
library(here)
library(sandwich)

# Create output directories
dir.create(here("output", "models"), showWarnings = FALSE)

# Load data
final_data <- read_csv(here("data", "02-analysis_data", "stability_measures.csv")) %>%
  left_join(read_csv(here("data", "02-analysis_data", "dpi_processed.csv")), by = "iso3c") %>%
  left_join(read_csv(here("data", "02-analysis_data", "qog_processed.csv")), by = "iso3c") %>%
  left_join(
    read_csv(here("data", "02-analysis_data", "gdp_processed.csv")) %>% 
      dplyr::select(iso3c, log_gdp_mean), 
    by = "iso3c"
  ) %>%
  left_join(
    read_csv(here("data", "02-analysis_data", "merged_all_years.csv")) %>%
      group_by(country_name, iso3c) %>%
      summarise(monarchy = as.numeric(mean(v2exl_legitlead, na.rm = TRUE) == 1), .groups = "drop"),
    by = c("country_name", "iso3c")
  ) %>%
  mutate(
    system_type = factor(system_type, levels = c("Parliamentary", "Semi-Presidential", "Presidential")),
    log_gdp = log_gdp_mean,
    presidential = ifelse(system_type == "Presidential", 1, 0),
    semi_pres = ifelse(system_type == "Semi-Presidential", 1, 0)
  ) %>%
  filter(!is.na(system_type) & !is.na(volatility) & !is.na(log_gdp))


# MWI Estimator: Weight institutional effects by mechanism relevance
final_data <- final_data %>%
  mutate(
    # Crisis Response: Presidential autonomy matters more when GDP is low
    crisis_response_weight = presidential * (1 / (log_gdp + 1)),
    
    # Institutional Quality: Threshold effect above high income
    inst_quality_weight = ifelse(log_gdp > log(15000), 1, 0),
    
    # Party Institutionalization: Parliamentary advantage with strong parties
    party_inst_weight = ifelse(system_type == "Parliamentary", 1 / (ethnic_frac + 0.1), 0),
    
    # MWI terms
    mwi_crisis = crisis_response_weight * log_gdp,
    mwi_inst_quality = presidential * inst_quality_weight * log_gdp,
    mwi_party_inst = ifelse(system_type == "Parliamentary", party_inst_weight * log_gdp, 0)
  )

# Fit models
original_model <- lm(volatility ~ system_type * log_gdp + mean_democracy + ethnic_frac,
                     data = final_data)

mwi_model <- lm(volatility ~ system_type + log_gdp + mean_democracy + ethnic_frac +
                  mwi_crisis + mwi_inst_quality + mwi_party_inst,
                data = final_data)

# Extract MWI terms
mwi_coefs <- coef(mwi_model)
mwi_se <- sqrt(diag(vcovHC(mwi_model, type = "HC1")))

mwi_results <- tibble(
  Term = names(mwi_coefs),
  Coefficient = round(mwi_coefs, 4),
  SE = round(mwi_se, 4),
  t_stat = round(mwi_coefs / mwi_se, 3),
  p_value = round(2 * (1 - pt(abs(mwi_coefs / mwi_se), df.residual(mwi_model))), 4)
) %>%
  filter(str_detect(Term, "mwi_"))

# Save models
saveRDS(mwi_model, here("output", "models", "mwi_model.rds"))
saveRDS(mwi_results, here("output", "models", "mwi_results.rds"))
