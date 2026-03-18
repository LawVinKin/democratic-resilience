library(tidyverse)
library(sandwich)
library(lmtest)
library(modelsummary)
library(broom)
library(here)

dir.create(here("output", "robustness"), showWarnings = FALSE, recursive = TRUE)
dir.create(here("output", "tables"), showWarnings = FALSE, recursive = TRUE)

final_data <- readRDS(here("data", "02-analysis_data", "analytical_sample.rds"))
main_models <- readRDS(here("output", "models", "main_models.rds"))
m2 <- main_models$m2

beta_pres <- coef(m2)["system_typePresidential"]
beta_pres_x_gdp <- coef(m2)["system_typePresidential:log_gdp"]
log_gdp_crossover <- -beta_pres / beta_pres_x_gdp
gdp_crossover <- exp(log_gdp_crossover)

m_decline <- lm(total_decline ~ system_type * log_gdp + mean_democracy + ethnic_frac,
                data = final_data)

robust_decline <- coeftest(m_decline, vcov = vcovHC(m_decline, type = "HC1"))

decline_results <- tibble(
  specification = "Alt. DV (Total Decline)",
  coef = robust_decline["system_typePresidential:log_gdp", "Estimate"],
  se = robust_decline["system_typePresidential:log_gdp", "Std. Error"],
  p_value = robust_decline["system_typePresidential:log_gdp", "Pr(>|t|)"],
  n = nrow(model.frame(m_decline))
)

write_csv(decline_results, here("output", "robustness", "alt_dv_results.csv"))

high_income <- final_data %>% filter(log_gdp >= median(log_gdp, na.rm = TRUE))
m_high <- lm(volatility ~ system_type * log_gdp + mean_democracy + ethnic_frac,
             data = high_income)

low_income <- final_data %>% filter(log_gdp < median(log_gdp, na.rm = TRUE))
m_low <- lm(volatility ~ system_type * log_gdp + mean_democracy + ethnic_frac,
            data = low_income)

democracies <- final_data %>% filter(mean_democracy > 0.5)
m_dem <- lm(volatility ~ system_type * log_gdp + mean_democracy + ethnic_frac,
            data = democracies)

get_interaction <- function(model) {
  robust_v <- vcovHC(model, type = "HC1")
  term <- "system_typePresidential:log_gdp"
  if (term %in% names(coef(model))) {
    t_stat <- coef(model)[term] / sqrt(robust_v[term, term])
    df <- df.residual(model)
    p_val <- 2 * pt(abs(t_stat), df, lower.tail = FALSE)
    return(tibble(
      coef = coef(model)[term],
      se = sqrt(robust_v[term, term]),
      p_value = p_val,
      n = nrow(model.frame(model))
    ))
  } else {
    return(tibble(coef = NA, se = NA, p_value = NA, n = nrow(model.frame(model))))
  }
}

subsample_results <- bind_rows(
  tibble(specification = "High-Income Subsample", get_interaction(m_high)),
  tibble(specification = "Low-Income Subsample", get_interaction(m_low)),
  tibble(specification = "Democracies Only", get_interaction(m_dem))
)

write_csv(subsample_results, here("output", "robustness", "subsample_results.csv"))

final_data_region <- final_data %>%
  mutate(region = case_when(
    iso3c %in% c("ARG", "BOL", "BRA", "CHL", "COL", "CRI", "CUB", "DOM", "ECU", "SLV",
                 "GTM", "HND", "MEX", "NIC", "PAN", "PRY", "PER", "URY", "VEN") ~ "Latin America",
    iso3c %in% c("AUT", "BEL", "BGR", "HRV", "CYP", "CZE", "DNK", "EST", "FIN", "FRA",
                 "DEU", "GRC", "HUN", "IRL", "ITA", "LVA", "LTU", "LUX", "MLT", "NLD",
                 "POL", "PRT", "ROU", "SVK", "SVN", "ESP", "SWE", "GBR", "NOR", "CHE",
                 "ISL", "ALB", "MKD", "SRB", "MNE", "BIH", "UKR", "MDA", "BLR") ~ "Europe",
    iso3c %in% c("DZA", "EGY", "LBY", "MAR", "TUN", "BHR", "IRN", "IRQ", "ISR", "JOR",
                 "KWT", "LBN", "OMN", "QAT", "SAU", "SYR", "TUR", "ARE", "YEM") ~ "MENA",
    iso3c %in% c("AFG", "BGD", "BTN", "IND", "MDV", "NPL", "PAK", "LKA", "CHN", "JPN",
                 "KOR", "MNG", "PRK", "TWN", "BRN", "KHM", "IDN", "LAO", "MYS", "MMR",
                 "PHL", "SGP", "THA", "TLS", "VNM") ~ "Asia-Pacific",
    iso3c %in% c("AGO", "BEN", "BWA", "BFA", "BDI", "CMR", "CPV", "CAF", "TCD", "COM",
                 "COD", "COG", "CIV", "DJI", "GNQ", "ERI", "SWZ", "ETH", "GAB", "GMB",
                 "GHA", "GIN", "GNB", "KEN", "LSO", "LBR", "MDG", "MWI", "MLI", "MRT",
                 "MUS", "MOZ", "NAM", "NER", "NGA", "RWA", "STP", "SEN", "SYC", "SLE",
                 "SOM", "ZAF", "SSD", "SDN", "TZA", "TGO", "UGA", "ZMB", "ZWE") ~ "Sub-Saharan Africa",
    TRUE ~ "Other"
  ))

m_region <- lm(volatility ~ system_type * log_gdp + mean_democracy + ethnic_frac + region,
               data = final_data_region)

robust_region <- coeftest(m_region, vcov = vcovHC(m_region, type = "HC1"))

region_results <- tibble(
  specification = "Regional FE",
  coef = robust_region["system_typePresidential:log_gdp", "Estimate"],
  se = robust_region["system_typePresidential:log_gdp", "Std. Error"],
  p_value = robust_region["system_typePresidential:log_gdp", "Pr(>|t|)"],
  n = nrow(model.frame(m_region))
)

write_csv(region_results, here("output", "robustness", "regional_fe_results.csv"))

m2_data <- model.frame(m2)
cooks_d <- cooks.distance(m2)
outlier_threshold <- 4 / nrow(m2_data)

m_no_outliers <- lm(volatility ~ system_type * log_gdp + mean_democracy + ethnic_frac,
                    data = m2_data[cooks_d < outlier_threshold, ])

n_excluded <- nrow(m2_data) - nrow(model.frame(m_no_outliers))

robust_outliers <- coeftest(m_no_outliers, vcov = vcovHC(m_no_outliers, type = "HC1"))

outlier_results <- tibble(
  specification = paste0("Excluding ", n_excluded, " outliers"),
  coef = robust_outliers["system_typePresidential:log_gdp", "Estimate"],
  se = robust_outliers["system_typePresidential:log_gdp", "Std. Error"],
  p_value = robust_outliers["system_typePresidential:log_gdp", "Pr(>|t|)"],
  n = nrow(model.frame(m_no_outliers))
)

write_csv(outlier_results, here("output", "robustness", "outlier_results.csv"))

m1_restricted <- lm(volatility ~ system_type + log_gdp + system_type * log_gdp, 
                    data = final_data)

m2_full <- lm(volatility ~ system_type + log_gdp + system_type * log_gdp + 
                mean_democracy + ethnic_frac, data = final_data)

beta_un <- coef(m1_restricted)["system_typePresidential:log_gdp"]
beta_full <- coef(m2_full)["system_typePresidential:log_gdp"]
r2_un <- summary(m1_restricted)$r.squared
r2_full <- summary(m2_full)$r.squared

numerator <- (beta_un - beta_full) * (1 - r2_full)
denominator <- r2_full - r2_un
beta_star <- beta_full - (numerator / denominator)

oster_results <- tibble(
  beta_unrestricted = beta_un,
  beta_full = beta_full,
  beta_oster = beta_star,
  r2_unrestricted = r2_un,
  r2_full = r2_full
)

write_csv(oster_results, here("output", "robustness", "oster_bounds.csv"))

iso_list <- unique(final_data$iso3c)
loo_results <- map_dfr(iso_list, function(iso) {
  df_tmp <- filter(final_data, iso3c != iso)
  mod_tmp <- lm(volatility ~ system_type + log_gdp + system_type * log_gdp + 
                  mean_democracy + ethnic_frac, data = df_tmp)
  coef_val <- coef(mod_tmp)["system_typePresidential:log_gdp"]
  se_val <- summary(mod_tmp)$coefficients["system_typePresidential:log_gdp", "Std. Error"]
  tibble(iso3c = iso, coef = coef_val, se = se_val)
})

write_csv(loo_results, here("output", "robustness", "leave_one_out.csv"))

loo_plot <- ggplot(loo_results, aes(x = reorder(iso3c, coef), y = coef)) +
  geom_hline(yintercept = coef(m2)["system_typePresidential:log_gdp"], 
             color = "red", linetype = "dashed", linewidth = 1) +
  geom_point(size = 2, alpha = 0.6) +
  coord_flip() +
  labs(
    x = "Country",
    y = "Interaction Coefficient",
    title = "Leave-One-Out Influence Analysis",
    subtitle = "Red line shows full sample estimate",
    caption = "Each point shows coefficient when excluding that country"
  ) +
  theme_minimal(base_size = 10) +
  theme(axis.text.y = element_text(size = 7))

ggsave(here("output", "robustness", "leave_one_out_plot.png"), loo_plot,
       width = 10, height = 8, dpi = 300)

set.seed(2026)

bootstrap_crossover <- function(data, n_boot = 1000) {
  results <- map_dfr(1:n_boot, function(b) {
    idx <- sample(1:nrow(data), nrow(data), replace = TRUE)
    dfb <- data[idx, ]
    
    modb <- lm(volatility ~ system_type * log_gdp + mean_democracy + ethnic_frac, 
               data = dfb)
    
    beta_pres_b <- coef(modb)["system_typePresidential"]
    beta_int_b <- coef(modb)["system_typePresidential:log_gdp"]
    
    cross_log_b <- -beta_pres_b / beta_int_b
    
    tibble(
      rep = b,
      crossover_log = cross_log_b,
      crossover_gdp = exp(cross_log_b)
    )
  })
  
  return(results)
}

bootstrap_results <- bootstrap_crossover(final_data, n_boot = 1000)

ci_log <- quantile(bootstrap_results$crossover_log, probs = c(0.025, 0.5, 0.975), na.rm = TRUE)
ci_gdp <- quantile(bootstrap_results$crossover_gdp, probs = c(0.025, 0.5, 0.975), na.rm = TRUE)

write_csv(bootstrap_results, here("output", "robustness", "crossover_bootstrap.csv"))

crossover_summary <- tibble(
  statistic = c("Point Estimate", "2.5%", "50% (Median)", "97.5%"),
  log_gdp = c(log_gdp_crossover, ci_log),
  gdp_ppp = c(gdp_crossover, ci_gdp)
)

write_csv(crossover_summary, here("output", "robustness", "crossover_summary.csv"))

bootstrap_plot <- ggplot(bootstrap_results, aes(x = crossover_gdp)) +
  geom_histogram(bins = 50, fill = "#2166AC", alpha = 0.7, color = "white") +
  geom_vline(xintercept = gdp_crossover, color = "red", linetype = "dashed", linewidth = 1) +
  geom_vline(xintercept = ci_gdp[2], color = "darkgray", linetype = "dotted", linewidth = 1) +
  geom_vline(xintercept = ci_gdp[3], color = "darkgray", linetype = "dotted", linewidth = 1) +
  scale_x_continuous(labels = scales::dollar_format()) +
  labs(
    x = "Crossover GDP per Capita (PPP)",
    y = "Frequency",
    title = "Bootstrap Distribution of Crossover Point",
    subtitle = paste0("95% CI: $", format(round(ci_gdp[2], 0), big.mark = ","), 
                      " - $", format(round(ci_gdp[3], 0), big.mark = ",")),
    caption = "Red line shows point estimate; dotted lines show 95% CI"
  ) +
  theme_minimal(base_size = 12)

ggsave(here("output", "robustness", "crossover_bootstrap_dist.png"), bootstrap_plot,
       width = 8, height = 5, dpi = 300)

robustness_summary <- bind_rows(
  tibble(specification = "Main Model", 
         coef = coeftest(m2, vcov = vcovHC(m2, type = "HC1"))["system_typePresidential:log_gdp", "Estimate"],
         se = coeftest(m2, vcov = vcovHC(m2, type = "HC1"))["system_typePresidential:log_gdp", "Std. Error"],
         p_value = coeftest(m2, vcov = vcovHC(m2, type = "HC1"))["system_typePresidential:log_gdp", "Pr(>|t|)"],
         n = nrow(model.frame(m2))),
  decline_results %>% select(specification, coef, se, p_value, n),
  subsample_results,
  region_results,
  outlier_results
)

robustness_summary <- robustness_summary %>%
  mutate(
    coef_stars = case_when(
      p_value < 0.001 ~ paste0(round(coef, 4), "***"),
      p_value < 0.01 ~ paste0(round(coef, 4), "**"),
      p_value < 0.05 ~ paste0(round(coef, 4), "*"),
      TRUE ~ paste0(round(coef, 4), "")
    )
  )

write_csv(robustness_summary, here("output", "tables", "robustness_summary.csv"))
