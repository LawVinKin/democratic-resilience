# We use the Mechanism Weighted Index (MWI) approach to assess how different mechanisms
# contribute to the overall effect of system type on stability.

library(tidyverse)
library(sandwich)

# Create output directories
dir.create("/Users/shahin/Documents/GitHub/projects-template/output/models", showWarnings = FALSE)

# Load and prepare final analytical dataset
stability <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/stability_measures.csv")
dpi <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/dpi_processed.csv")
qog <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/qog_processed.csv")
gdp <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/gdp_processed.csv") %>% 
  dplyr::select(iso3c, log_gdp_mean)

final_data <- stability %>%
  left_join(dpi, by = "iso3c") %>%
  left_join(qog, by = "iso3c") %>%
  left_join(gdp, by = "iso3c") %>%
  mutate(
    system_type = factor(system_type, levels = c("Parliamentary", "Semi-Presidential", "Presidential")),
    log_gdp = log_gdp_mean,
    presidential = ifelse(system_type == "Presidential", 1, 0),
    semi_pres = ifelse(system_type == "Semi-Presidential", 1, 0)) %>%
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

# Extract MWI terms with robust SEs
mwi_coefs <- coef(mwi_model)
mwi_se <- sqrt(diag(vcovHC(mwi_model, type = "HC1")))

mwi_results <- tibble(
  Term = names(mwi_coefs),
  Coefficient = round(mwi_coefs, 4),
  SE = round(mwi_se, 4),
  t_stat = round(mwi_coefs / mwi_se, 3),
  p_value = round(2 * (1 - pt(abs(mwi_coefs / mwi_se), df.residual(mwi_model))), 4)) %>%
  filter(str_detect(Term, "mwi_"))
