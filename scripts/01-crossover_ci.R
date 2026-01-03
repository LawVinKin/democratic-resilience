# Compute bootstrap CIs for the GDP crossover point
# Crossover where effect of Presidential relative to Parliamentary = 0

library(tidyverse)
library(here)

set.seed(2026)
out_dir <- here::here("output","robustness")
if(!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# Load processed final data
final_data <- read_csv(here::here("data","02-analysis_data","stability_measures.csv")) %>%
  left_join(read_csv(here::here("data","02-analysis_data","dpi_processed.csv")) %>% distinct(iso3c, .keep_all = TRUE), by = "iso3c") %>%
  left_join(read_csv(here::here("data","02-analysis_data","gdp_processed.csv")) %>% distinct(iso3c, .keep_all = TRUE) %>% select(iso3c, log_gdp_mean), by = "iso3c") %>%
  left_join(read_csv(here::here("data","02-analysis_data","qog_processed.csv")) %>% distinct(iso3c, .keep_all = TRUE), by = "iso3c") %>%
  mutate(log_gdp = log_gdp_mean) %>%
  filter(!is.na(volatility) & !is.na(system_type) & !is.na(log_gdp))

# Formula: full model
mod_formula_full <- as.formula("volatility ~ system_type + log_gdp + system_type:log_gdp + mean_democracy + ethnic_frac")

# Fit full model on original sample
mod_full <- lm(mod_formula_full, data = final_data)
coefs <- coef(mod_full)
# Extract beta for Presidential (factor-level; name depends on factor coding)
pres_name <- "system_typePresidential"
int_name <- "system_typePresidential:log_gdp"
if(!pres_name %in% names(coefs) | !int_name %in% names(coefs)){
  stop("Expected coefficient names not found in model: check factor coding")
}
beta_pres <- coefs[pres_name]
beta_int <- coefs[int_name]

# Compute crossover in log GDP
crossover_log <- - as.numeric(beta_pres) / as.numeric(beta_int)
crossover_gdp <- exp(crossover_log)

# Bootstrap
B <- 1000
n <- nrow(final_data)
results <- tibble(rep = integer(), crossover_log = double(), crossover_gdp = double())

for(b in seq_len(B)){
  idx <- sample(seq_len(n), size = n, replace = TRUE)
  dfb <- final_data[idx, ]
  modb <- try(lm(mod_formula_full, data = dfb), silent = TRUE)
  if(inherits(modb, "try-error")) next
  cb <- coef(modb)
  if(!(pres_name %in% names(cb)) | !(int_name %in% names(cb))) next
  beta_pres_b <- cb[pres_name]
  beta_int_b <- cb[int_name]
  # avoid division by zero
  if(is.na(beta_int_b) | beta_int_b == 0) next
  cross_log_b <- - as.numeric(beta_pres_b) / as.numeric(beta_int_b)
  results <- results %>% add_row(rep = b, crossover_log = cross_log_b, crossover_gdp = exp(cross_log_b))
}

# Summarize
ci_log <- quantile(results$crossover_log, probs = c(0.025, 0.5, 0.975), na.rm = TRUE)
ci_gdp <- quantile(results$crossover_gdp, probs = c(0.025, 0.5, 0.975), na.rm = TRUE)
summary_txt <- paste0(
  "Crossover (log GDP): median = ", round(ci_log[2],3), ", 95% CI = [", round(ci_log[1],3), ", ", round(ci_log[3],3), "]\n",
  "Crossover (GDP, PPP): median = $", round(ci_gdp[2],0), ", 95% CI = [$", round(ci_gdp[1],0), ", $", round(ci_gdp[3],0), "]\n",
  "Original point estimate (GDP): $", round(crossover_gdp,0), " (log = ", round(crossover_log,3), ")\n",
  "Bootstrap draws (successful): ", nrow(results), " (out of ", B, ")"
)

writeLines(summary_txt, con = file.path(out_dir, "crossover_summary.txt"))
write_csv(results, file.path(out_dir, "crossover_bootstrap.csv"))

# Plot distribution and CI
library(ggplot2)
library(gridExtra)

# Left: density on log scale (matches modelling scale)
left <- ggplot(results, aes(x = crossover_log)) +
  geom_density(fill = "#2c7fb8", alpha = 0.6) +
  geom_vline(xintercept = ci_log[2], color = "black", size = 0.8) +
  geom_vline(xintercept = ci_log[c(1,3)], color = "red", linetype = "dashed") +
  theme_minimal() +
  labs(title = "Bootstrap density (log GDP)", x = "log(GDP per capita)", y = "Density")

# Right: point estimate + 95% CI in USD
ci_df <- tibble(median = ci_gdp[2], lower = ci_gdp[1], upper = ci_gdp[3])
label_text <- paste0("Median = $", format(round(ci_gdp[2],0), big.mark = ","),
                     "\n95% CI = [$", format(round(ci_gdp[1],0), big.mark = ","),
                     ", $", format(round(ci_gdp[3],0), big.mark = ","), "]")

right <- ggplot(ci_df, aes(y = 1, x = median)) +
  geom_point(size = 3, color = "#2c7fb8") +
  geom_errorbarh(aes(xmin = lower, xmax = upper), height = 0.2, color = "black") +
  geom_text(aes(x = median, y = 1.05), label = label_text, vjust = 0, hjust = 0.5, size = 3.5) +
  scale_x_continuous(labels = scales::dollar_format(prefix = "$", accuracy = 1)) +
  theme_minimal() +
  theme(axis.title.y = element_text(face = "bold", size = 11),
        axis.title.x = element_text(face = "bold", size = 11),
        axis.text.y = element_blank(), axis.ticks.y = element_blank()) +
  labs(title = "Crossover estimate (USD)", x = "GDP per capita (PPP, USD)")

combined <- grid.arrange(left, right, ncol = 2, widths = c(2, 1))
ggsave(file.path(out_dir, "crossover_ci_v2.png"), combined, width = 9, height = 4, dpi = 300)
