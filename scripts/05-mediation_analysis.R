# Mediation Analysis
# Purpose: Test theoretical mechanisms through causal mediation analysis
# Author: [Your Name]
# Contact: [Your Email]

library(tidyverse)
library(here)
library(mediation)

# Load final dataset
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
    presidential = ifelse(system_type == "Presidential", 1, 0)
  ) %>%
  filter(!is.na(system_type) & !is.na(volatility) & !is.na(log_gdp))

# Create proxy mediators based on theory:
# 1. Crisis Response: Presidential autonomy matters more when resources are scarce
# 2. Institutional Quality: GDP as proxy for institutional capacity
# 3. Party Institutionalization: Inverse of ethnic fractionalization

final_data <- final_data %>%
  mutate(
    crisis_response_mediator = presidential * (1 / (log_gdp + 1)),
    inst_quality_mediator = log_gdp, 
    party_inst_mediator = 1 / (ethnic_frac + 0.1)
  )

# Mediation Analysis: Party Institutionalization
m_model_party <- lm(party_inst_mediator ~ presidential + log_gdp + mean_democracy + ethnic_frac, 
                    data = final_data)
y_model_party <- lm(volatility ~ presidential + party_inst_mediator + log_gdp + mean_democracy + ethnic_frac, 
                    data = final_data)
med_out_party <- mediate(m_model_party, y_model_party, 
                         treat = "presidential", mediator = "party_inst_mediator", 
                         boot = TRUE, sims = 500)

saveRDS(med_out_party, here("output", "mediation", "mediation_results_party_proxy.rds"))

# Mediation Analysis: Crisis Response
m_model_crisis <- lm(crisis_response_mediator ~ presidential + log_gdp + mean_democracy + ethnic_frac, 
                     data = final_data)
y_model_crisis <- lm(volatility ~ presidential + crisis_response_mediator + log_gdp + mean_democracy + ethnic_frac, 
                     data = final_data)
med_out_crisis <- mediate(m_model_crisis, y_model_crisis, 
                          treat = "presidential", mediator = "crisis_response_mediator", 
                          boot = TRUE, sims = 500)

saveRDS(med_out_crisis, here("output", "mediation", "mediation_results_crisis_proxy.rds"))

# Mediation Analysis: Institutional Quality
m_model_inst <- lm(inst_quality_mediator ~ presidential + log_gdp + mean_democracy + ethnic_frac, 
                   data = final_data)
y_model_inst <- lm(volatility ~ presidential + inst_quality_mediator + log_gdp + mean_democracy + ethnic_frac, 
                   data = final_data)
med_out_inst <- mediate(m_model_inst, y_model_inst, 
                        treat = "presidential", mediator = "inst_quality_mediator", 
                        boot = TRUE, sims = 500)

saveRDS(med_out_inst, here("output", "mediation", "mediation_results_inst_proxy.rds"))
