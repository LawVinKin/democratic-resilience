# Robustness Checks
# Purpose: Alternative DVs, subsample analyses, and sensitivity tests
# Author: [Your Name]
# Contact: [Your Email]

library(tidyverse)
library(here)
library(sandwich)
library(lmtest)
library(modelsummary)
library(flextable)
library(officer)

robust_vcov <- function(model) vcovHC(model, type = "HC1")

# Load final dataset
final_data <- read_csv(here("data", "02-analysis_data", "stability_measures.csv")) %>%
  left_join(read_csv(here("data", "02-analysis_data", "dpi_processed.csv")), by = "iso3c") %>%
  left_join(read_csv(here("data", "02-analysis_data", "qog_processed.csv")), by = "iso3c") %>%
  left_join(read_csv(here("data", "02-analysis_data", "gdp_processed.csv")) %>% 
              select(iso3c, log_gdp_mean), by = "iso3c") %>%
  left_join(
    read_csv(here("data", "02-analysis_data", "merged_all_years.csv")) %>%
      group_by(country_name, iso3c) %>%
      summarise(monarchy = as.numeric(mean(v2exl_legitlead, na.rm = TRUE) == 1), .groups = "drop"),
    by = c("country_name", "iso3c")
  ) %>%
  mutate(
    system_type = factor(system_type, levels = c("Parliamentary", "Semi-Presidential", "Presidential")),
    log_gdp = log_gdp_mean
  ) %>%
  filter(!is.na(system_type) & !is.na(volatility) & !is.na(log_gdp))


# Alternative DV: Total Decline
m_decline <- lm(total_decline ~ system_type * log_gdp + mean_democracy + ethnic_frac + monarchy,
                data = final_data)

tab_decline <- modelsummary(
  list("Alt DV: Total Decline" = m_decline),
  vcov = list(robust_vcov(m_decline)),
  coef_map = c(
    "system_typeSemi-Presidential" = "Semi-Presidential System",
    "system_typePresidential" = "Presidential System",
    "log_gdp" = "Log GDP per Capita (PPP)",
    "mean_democracy" = "Mean Democracy Level (2000–2023)",
    "ethnic_frac" = "Ethnic Fractionalization",
    "monarchy" = "Constitutional Monarchy",
    "system_typeSemi-Presidential:log_gdp" = "Semi-Presidential × Log GDP",
    "system_typePresidential:log_gdp" = "Presidential × Log GDP"
  ),
  stars = c('*' = .05, '**' = .01, '***' = .001),
  output = "flextable"
) %>%
  theme_booktabs() %>%
  fontsize(size = 10, part = "all") %>%
  bold(part = "header") %>%
  autofit() %>%
  set_caption("Table S1: Interaction Model with Total Decline DV")

doc_s1 <- read_docx()
doc_s1 <- body_add_flextable(doc_s1, tab_decline)
print(doc_s1, target = here("output", "tables", "Table_S1_DeclineRobustness.docx"))


# Subsample Analyses
median_gdp <- median(final_data$log_gdp, na.rm = TRUE)
rich <- final_data %>% filter(log_gdp > median_gdp)
poor <- final_data %>% filter(log_gdp <= median_gdp)
democracies <- final_data %>% filter(mean_democracy > 0.5)

m_rich <- lm(volatility ~ system_type + mean_democracy + log_gdp + ethnic_frac + monarchy, data = rich)
m_poor <- lm(volatility ~ system_type + mean_democracy + log_gdp + ethnic_frac + monarchy, data = poor)
m_dem  <- lm(volatility ~ system_type + mean_democracy + log_gdp + ethnic_frac + monarchy, data = democracies)

tab4 <- modelsummary(
  list("High-Income" = m_rich, "Low-Income" = m_poor, "Established Democracies" = m_dem),
  vcov = list(robust_vcov(m_rich), robust_vcov(m_poor), robust_vcov(m_dem)),
  coef_map = c(
    "system_typeSemi-Presidential" = "Semi-Presidential System",
    "system_typePresidential" = "Presidential System",
    "mean_democracy" = "Mean Democracy Level",
    "log_gdp" = "Log GDP per Capita",
    "ethnic_frac" = "Ethnic Fractionalization",
    "monarchy" = "Constitutional Monarchy"
  ),
  gof_map = c("nobs", "r.squared", "adj.r.squared"),
  stars = c('*' = .05, '**' = .01, '***' = .001),
  output = "flextable"
) %>%
  theme_booktabs() %>%
  fontsize(size = 10, part = "all") %>%
  bold(part = "header") %>%
  autofit() %>%
  set_caption("Table 4: Subsample Analysis") %>%
  add_footer_lines("Robust SEs. Reference: Parliamentary systems. * p<0.05; ** p<0.01; *** p<0.001")

doc4 <- read_docx()
doc4 <- body_add_flextable(doc4, tab4)
print(doc4, target = here("output", "tables", "Table4_Subsample.docx"))
