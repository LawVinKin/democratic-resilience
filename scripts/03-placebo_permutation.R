# Placebo / permutation test for the Presidential × log(GDP) interaction
# Approach: shuffle `system_type` across countries in the country-level analytic sample
# and re-estimate the full cross-sectional model, collecting the permutation distribution
# of the focal interaction coefficient. Compare observed coefficient to permutation distribution.

library(tidyverse)
library(here)

set.seed(20260103)
out_dir <- here::here("output","robustness")
if(!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# Load country-level final data (same as used in sensitivity scripts)
final_data <- read_csv(here::here("data","02-analysis_data","stability_measures.csv")) %>%
  left_join(read_csv(here::here("data","02-analysis_data","dpi_processed.csv")) %>% distinct(iso3c, .keep_all = TRUE), by = "iso3c") %>%
  left_join(read_csv(here::here("data","02-analysis_data","gdp_processed.csv")) %>% distinct(iso3c, .keep_all = TRUE) %>% select(iso3c, log_gdp_mean), by = "iso3c") %>%
  left_join(read_csv(here::here("data","02-analysis_data","qog_processed.csv")) %>% distinct(iso3c, .keep_all = TRUE), by = "iso3c") %>%
  mutate(log_gdp = log_gdp_mean) %>%
  filter(!is.na(volatility) & !is.na(system_type) & !is.na(log_gdp))

# Full model formula (same as used elsewhere)
mod_formula_full <- as.formula("volatility ~ system_type + log_gdp + system_type:log_gdp + mean_democracy + ethnic_frac")

# Fit observed model
mod_obs <- lm(mod_formula_full, data = final_data)
coefs_obs <- coef(mod_obs)
int_name <- "system_typePresidential:log_gdp"
if(!int_name %in% names(coefs_obs)) stop("Focal interaction coef not found in observed model; check factor coding")
obs_coef <- as.numeric(coefs_obs[int_name])
obs_se <- summary(mod_obs)$coefficients[int_name, "Std. Error"]

# Permutation: shuffle system_type across rows (countries) and re-estimate
B <- 2000
perm_res <- vector("numeric", B)

for(b in seq_len(B)){
  final_data_perm <- final_data %>% mutate(system_type = sample(system_type))
  modb <- try(lm(mod_formula_full, data = final_data_perm), silent = TRUE)
  if(inherits(modb, "try-error")){
    perm_res[b] <- NA_real_
    next
  }
  cb <- coef(modb)
  if(!(int_name %in% names(cb))){
    perm_res[b] <- NA_real_
  } else {
    perm_res[b] <- as.numeric(cb[int_name])
  }
}

perm_res_valid <- perm_res[!is.na(perm_res)]

# Summary
perm_summary <- tibble(
  observed = obs_coef,
  perm_median = median(perm_res_valid),
  perm_mean = mean(perm_res_valid),
  perm_sd = sd(perm_res_valid),
  n_perm = length(perm_res_valid)
)

# Empirical p-value (two-sided)
p_two_sided <- mean(abs(perm_res_valid) >= abs(obs_coef))
perm_summary <- perm_summary %>% mutate(p_value = p_two_sided)

write_csv(tibble(perm = perm_res_valid), file.path(out_dir, "placebo_permutation_distribution.csv"))
write_csv(perm_summary, file.path(out_dir, "placebo_permutation_summary.csv"))

# Plot distribution and observed line
library(ggplot2)
plt <- ggplot(tibble(perm = perm_res_valid), aes(x = perm)) +
  geom_histogram(bins = 50, fill = "#2c7fb8", color = "white", alpha = 0.9) +
  geom_vline(xintercept = obs_coef, color = "red", size = 1) +
  theme_minimal() +
  theme(axis.title = element_text(face = "bold", size = 11), axis.text = element_text(size = 10)) +
  labs(title = "Placebo permutation distribution: Presidential × log(GDP) interaction",
       subtitle = paste0("Observed coef = ", round(obs_coef,4), "; empirical two-sided p = ", round(p_two_sided,3)),
       x = "Interaction coefficient (permutation)", y = "Count")

ggsave(file.path(out_dir, "placebo_permutation_hist_v2.png"), plt, width = 7, height = 4, dpi = 300)

cat("Placebo permutation complete. Observed coef:", round(obs_coef,4), "empirical p-value:", round(p_two_sided,4), "\n")
cat("Outputs written to:", out_dir, "(placebo_permutation_distribution.csv, placebo_permutation_summary.csv, placebo_permutation_hist.png)\n")
