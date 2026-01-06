# This script will compute bootstrap CIs for the GDP crossover point
# Crossover where effect of Presidential relative to Parliamentary = 0

library(tidyverse)
library(broom)

set.seed(2026)
dir.create("/Users/shahin/Documents/GitHub/projects-template/output/robustness", recursive = TRUE)

# Loading processed final data
stability_data <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/stability_measures.csv")

dpi_data <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/dpi_processed.csv") %>% distinct(iso3c, .keep_all = TRUE)

gdp_data <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/gdp_processed.csv") %>% distinct(iso3c, .keep_all = TRUE) %>% select(iso3c, log_gdp_mean)

qog_data <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/qog_processed.csv") %>% distinct(iso3c, .keep_all = TRUE)

# Merging data
final_data <- left_join(stability_data, dpi_data, by = "iso3c")
final_data <- left_join(final_data, gdp_data, by = "iso3c")
final_data <- left_join(final_data, qog_data, by = "iso3c")

final_data <- final_data %>%
  mutate(log_gdp = log_gdp_mean) %>%
  filter(!is.na(volatility) & !is.na(system_type) & !is.na(log_gdp))

# Fit full model on original sample
mod_full <- lm(volatility ~ system_type * log_gdp + mean_democracy + ethnic_frac, data = final_data)
coefs_df <- tidy(mod_full)

# Extract beta for Presidential
beta_pres <- coefs_df %>%
 filter(term == "system_typePresidential") %>%
 pull(estimate)

# Extract beta for interaction
beta_int <- coefs_df %>%
 filter(term == "system_typePresidential:log_gdp") %>%
 pull(estimate)

# Compute crossover in log GDP
crossover_log <- - as.numeric(beta_pres) / as.numeric(beta_int)
crossover_gdp <- exp(crossover_log) # converts to GDP in PPP

# Bootstrap: This follows the basic outline of case resampling bootstrap
results <- map_dfr(1:1000, function(b) {
  idx <- sample(1:nrow(final_data), nrow(final_data), replace = TRUE)
  dfb <- final_data[idx, ]
  modb <- lm(volatility ~ system_type * log_gdp + mean_democracy + ethnic_frac, data = dfb)
  cb_df <- tidy(modb)
  beta_pres_b <- cb_df %>%
    filter(term == "system_typePresidential") %>%
    pull(estimate)
  beta_int_b <- cb_df %>%
    filter(term == "system_typePresidential:log_gdp") %>%
    pull(estimate)
  cross_log_b <- - beta_pres_b / beta_int_b
  tibble(rep = b, crossover_log = cross_log_b, crossover_gdp = exp(cross_log_b))})

# Summarize
ci_log <- quantile(results$crossover_log, probs = c(0.025, 0.5, 0.975), na.rm = TRUE)
ci_gdp <- quantile(results$crossover_gdp, probs = c(0.025, 0.5, 0.975), na.rm = TRUE)

write_csv(results, "/Users/shahin/Documents/GitHub/projects-template/output/robustness/crossover_bootstrap.csv")
