# Mediation Analysis
# Purpose: Test theoretical mechanisms through causal mediation analysis

library(tidyverse)
library(mediation)

# Load and prepare final analytical dataset
stability <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/stability_measures.csv")
dpi <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/dpi_processed.csv")
qog <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/qog_processed.csv")
gdp <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/gdp_processed.csv") %>% 
  select(iso3c, log_gdp_mean)

final_data <- stability %>%
  left_join(dpi, by = "iso3c") %>%
  left_join(qog, by = "iso3c") %>%
  left_join(gdp, by = "iso3c") %>%
  mutate(
    system_type = factor(system_type, levels = c("Parliamentary", "Semi-Presidential", "Presidential")),
    log_gdp = log_gdp_mean,
    presidential = ifelse(system_type == "Presidential", 1, 0)) %>%
  filter(!is.na(system_type) & !is.na(volatility) & !is.na(log_gdp))

# We create proxy mediators based on theory:
# 1. Crisis Response: Presidential autonomy matters more when resources are scarce
# 2. Institutional Quality: GDP as proxy for institutional capacity
# 3. Party Institutionalization: Inverse of ethnic fractionalization

final_data <- final_data %>%
  mutate(
    crisis_response_mediator = presidential * (1 / (log_gdp + 1)),
    inst_quality_mediator = log_gdp, 
    party_inst_mediator = 1 / (ethnic_frac + 0.1))

# Mediation Analysis: Party Institutionalization
# Step 1: We model the mediator as a function of treatment and covariates
m_model_party <- lm(party_inst_mediator ~ presidential + log_gdp + mean_democracy + ethnic_frac, 
                    data = final_data)
# Step 2: We model the outcome as a function of treatment, mediator, and covariates
y_model_party <- lm(volatility ~ presidential + party_inst_mediator + log_gdp + mean_democracy + ethnic_frac, 
                    data = final_data)
# Step 3: We perform mediation analysis with bootstrapping
med_out_party <- mediate(m_model_party, y_model_party, 
                         treat = "presidential", mediator = "party_inst_mediator", 
                         boot = TRUE, sims = 500)

# Mediation Analysis: Crisis Response
# Step 1: We model the mediator
m_model_crisis <- lm(crisis_response_mediator ~ presidential + log_gdp + mean_democracy + ethnic_frac, 
                     data = final_data)
# Step 2: We model the outcome
y_model_crisis <- lm(volatility ~ presidential + crisis_response_mediator + log_gdp + mean_democracy + ethnic_frac, 
                     data = final_data)
# Step 3: We do the mediation analysis
med_out_crisis <- mediate(m_model_crisis, y_model_crisis, 
                         treat = "presidential", mediator = "crisis_response_mediator", 
                         boot = TRUE, sims = 500)

# Mediation Analysis: Institutional Quality
# Step 1: We model the mediator
m_model_inst <- lm(inst_quality_mediator ~ presidential + log_gdp + mean_democracy + ethnic_frac, 
                   data = final_data)
# Step 2: We model the outcome
y_model_inst <- lm(volatility ~ presidential + inst_quality_mediator + log_gdp + mean_democracy + ethnic_frac, 
                   data = final_data)
# Step 3: We do the mediation analysis
med_out_inst <- mediate(m_model_inst, y_model_inst, 
                        treat = "presidential", mediator = "inst_quality_mediator", 
                        boot = TRUE, sims = 500)