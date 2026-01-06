# This script will produce sensitivity checks using Oster (2019) and leave-one-out influence

library(tidyverse)
library(broom)

out_dir <- "/Users/shahin/Documents/GitHub/projects-template/output/robustness"
dir.create(out_dir, recursive = TRUE)
setwd(out_dir)

# Cleaning and loading and merging data
DPI <- "/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/dpi_processed.csv"
GDP <- "/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/gdp_processed.csv"
Stab <- "/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/stability_measures.csv"

stability_data <- read_csv(Stab)

dpi_data <- read_csv(DPI) %>%
  distinct(iso3c, .keep_all = TRUE)

gdp_data <- read_csv(GDP) %>%
  distinct(iso3c, .keep_all = TRUE) %>%
  select(iso3c, log_gdp_mean)

final_data <- left_join(stability_data, dpi_data, by = "iso3c")

final_data <- left_join(final_data, gdp_data, by = "iso3c")

final_data <- final_data %>%
  mutate(log_gdp = log_gdp_mean) %>%
  filter(!is.na(volatility) & !is.na(system_type) & !is.na(log_gdp))

final_data <- final_data %>%
  left_join(read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/qog_processed.csv") %>% distinct(iso3c, .keep_all = TRUE), by = "iso3c")

# Defining models
m1 <- lm(volatility ~ system_type + log_gdp + system_type*log_gdp, data = final_data)
m2 <- lm(volatility ~ system_type + log_gdp + system_type*log_gdp + mean_democracy + ethnic_frac, data = final_data)

# Getting their summaries
m1_summary <- tidy(m1)

# Save m1 summary to a CSV file
write_csv(m1_summary, "mod_base_coefs.csv")

# Get summary of model m2
m2_summary <- tidy(m2)

# Save m2 summary to a CSV file
write_csv(m2_summary, "mod_full_coefs.csv")

# Oster calculation
# Oster (2019) formula: beta* = beta_full - (beta_un - beta_full) * (1 - r2_full) / (r2_full - r2_un)
beta_un <- coef(m1)["system_typePresidential:log_gdp"]
beta_full <- coef(m2)["system_typePresidential:log_gdp"]
r2_un <- summary(m1)$r.squared #to extract r2 from model 1
r2_full <- summary(m2)$r.squared # Same as above
numerator <- (beta_un - beta_full) * (1 - r2_full)
denominator <- r2_full - r2_un
beta_star <- beta_full - (numerator / denominator)
oster_res <- list(beta_un = beta_un, beta_full = beta_full, beta_star = beta_star, r2_un = r2_un, r2_full = r2_full)

sink("oster_result.txt")
print(oster_res)
sink()

# Leave-one-out influence for the focal interaction term
# Leave-one-out analysis: Refit model excluding each country
# to assess influence on the interaction coefficient "system_typePresidential:log_gdp"
iso_list <- unique(final_data$iso3c)
loo_results <- data.frame()
for (iso in iso_list) {
  df_tmp <- filter(final_data, iso3c != iso)
  mod_tmp <- lm(volatility ~ system_type + log_gdp + system_type*log_gdp + mean_democracy + ethnic_frac, data = df_tmp)
  coef_val <- coef(mod_tmp)["system_typePresidential:log_gdp"]
  se_val <- summary(mod_tmp)$coefficients["system_typePresidential:log_gdp", "Std. Error"]
  loo_results <- rbind(loo_results, data.frame(iso3c = iso, coef = coef_val, se = se_val))
}

write_csv(loo_results, "leave_one_out_interaction.csv")