# Sensitivity checks: Oster (2019) and leave-one-out influence
# Produces small output files under output/robustness/

library(tidyverse)
library(here)
library(broom)

out_dir <- here::here("output","robustness")
if(!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# Load processed final data (country-level)
final_data <- read_csv(here::here("data","02-analysis_data","stability_measures.csv")) %>%
  # join DPI system type (ensure unique keys)
  left_join(
    read_csv(here::here("data","02-analysis_data","dpi_processed.csv")) %>% distinct(iso3c, .keep_all = TRUE),
    by = c("iso3c")
  ) %>%
  # join GDP
  left_join(
    read_csv(here::here("data","02-analysis_data","gdp_processed.csv")) %>% distinct(iso3c, .keep_all = TRUE) %>% select(iso3c, log_gdp_mean),
    by = "iso3c"
  ) %>%
  mutate(log_gdp = log_gdp_mean) %>%
  filter(!is.na(volatility) & !is.na(system_type) & !is.na(log_gdp))

# Define baseline and full models
# Baseline: system_type + log_gdp + interaction
mod_formula_base <- as.formula("volatility ~ system_type + log_gdp + system_type:log_gdp")
# Full: add standard controls
# join QOG for ethnic fractionalization
final_data <- final_data %>%
  left_join(read_csv(here::here("data","02-analysis_data","qog_processed.csv")) %>% distinct(iso3c, .keep_all = TRUE), by = "iso3c")

# Full model: include mean_democracy and ethnic fractionalization
mod_formula_full <- as.formula("volatility ~ system_type + log_gdp + system_type:log_gdp + mean_democracy + ethnic_frac")

mod_base <- lm(mod_formula_base, data = final_data)
mod_full <- lm(mod_formula_full, data = final_data)

# Save coefficients summary
write_csv(broom::tidy(mod_base), file = file.path(out_dir, "mod_base_coefs.csv"))
write_csv(broom::tidy(mod_full), file = file.path(out_dir, "mod_full_coefs.csv"))

# Simple Oster (2019) implementation helper
# If psacalc is available, use it; otherwise compute approximate delta bounds
run_oster <- function(mod_un, mod_full, delta = 1, rmax = 1) {
  # Requires: coef_un (beta_un), R2_un, R2_full, beta_full
  beta_un <- coef(mod_un)["system_typePresidential:log_gdp"]
  beta_full <- coef(mod_full)["system_typePresidential:log_gdp"]
  r2_un <- summary(mod_un)$r.squared
  r2_full <- summary(mod_full)$r.squared
  # Oster formula for adjusted estimate
  # beta* = beta_full - (beta_un - beta_full) * (rmax - r2_full)/(r2_full - r2_un)
  if(is.na(beta_un) | is.na(beta_full) | (r2_full - r2_un) == 0) return(NA)
  beta_star <- beta_full - (beta_un - beta_full) * (rmax - r2_full)/(r2_full - r2_un)
  return(list(beta_un = beta_un, beta_full = beta_full, beta_star = beta_star, r2_un = r2_un, r2_full = r2_full))
}

oster_res <- run_oster(mod_base, mod_full, delta = 1, rmax = 1)
writeLines(capture.output(oster_res), file.path(out_dir, "oster_result.txt"))

# Leave-one-out influence for the focal interaction term
iso_list <- unique(final_data$iso3c)
loo_results <- map_dfr(iso_list, function(iso) {
  df_tmp <- filter(final_data, iso3c != iso)
  mod_tmp <- lm(mod_formula_full, data = df_tmp)
  tibble(iso3c = iso,
         coef = coef(mod_tmp)["system_typePresidential:log_gdp"],
         se = summary(mod_tmp)$coefficients["system_typePresidential:log_gdp","Std. Error"]) 
})

write_csv(loo_results, file.path(out_dir, "leave_one_out_interaction.csv"))

# Quick plot of leave-one-out coefficients
library(ggplot2)
plt <- ggplot(loo_results, aes(x = reorder(iso3c, coef), y = coef)) +
  geom_point() +
  geom_hline(yintercept = coef(mod_full)["system_typePresidential:log_gdp"], color = "red") +
  coord_flip() +
  theme_minimal() +
  labs(title = "Leave-one-out coefficients for Presidential x LogGDP interaction",
       x = "Country dropped", y = "Interaction coefficient")

ggsave(file.path(out_dir, "leave_one_out_plot.png"), plt, width = 8, height = 6, dpi = 300)

message("Sensitivity checks complete. Outputs saved in: ", out_dir)
