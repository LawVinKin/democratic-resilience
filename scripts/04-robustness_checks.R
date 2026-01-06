# This script runs our robustness checks

library(tidyverse)
library(sandwich)
library(lmtest)
library(modelsummary)
library(flextable)
library(officer)

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
    log_gdp = log_gdp_mean) %>%
  filter(!is.na(system_type) & !is.na(volatility) & !is.na(log_gdp))


# Alternative DV: Total Decline
m_decline <- lm(total_decline ~ system_type * log_gdp + mean_democracy + ethnic_frac,
                data = final_data)

# Define coefficient names for readability
coef_names <- c(
  "system_typeSemi-Presidential" = "Semi-Presidential System",
  "system_typePresidential" = "Presidential System",
  "log_gdp" = "Log GDP per Capita (PPP)",
  "mean_democracy" = "Mean Democracy Level (2000–2023)",
  "ethnic_frac" = "Ethnic Fractionalization",
  "system_typeSemi-Presidential:log_gdp" = "Semi-Presidential × Log GDP",
  "system_typePresidential:log_gdp" = "Presidential × Log GDP")

# Define significance stars
sig_stars <- c('*' = .05, '**' = .01, '***' = .001)

# Generate the table
tab_decline <- modelsummary(
  list("Alt DV: Total Decline" = m_decline),
  vcov = "HC1",
  coef_map = coef_names,
  stars = sig_stars,
  output = "flextable") %>%
  theme_booktabs() %>%
  fontsize(size = 10, part = "all") %>%
  bold(part = "header") %>%
  autofit() %>%
  set_caption("Table S1: Interaction Model with Total Decline DV")

doc_s1 <- read_docx()
doc_s1 <- body_add_flextable(doc_s1, tab_decline)
setwd("/Users/shahin/Documents/GitHub/projects-template/output/tables")
print(doc_s1, target = "Table_S1_DeclineRobustness.docx")


# Subsample Analyses
median_gdp <- median(final_data$log_gdp, na.rm = TRUE)
rich <- final_data %>% filter(log_gdp > median_gdp)
poor <- final_data %>% filter(log_gdp <= median_gdp)
democracies <- final_data %>% filter(mean_democracy > 0.5)

m_rich <- lm(volatility ~ system_type + mean_democracy + log_gdp + ethnic_frac, data = rich)
m_poor <- lm(volatility ~ system_type + mean_democracy + log_gdp + ethnic_frac, data = poor)
m_dem  <- lm(volatility ~ system_type + mean_democracy + log_gdp + ethnic_frac, data = democracies)

# Define the models separately for clarity
model_list <- list(
  "High-Income" = m_rich,
  "Low-Income" = m_poor,
  "Established Democracies" = m_dem)

# Define coefficient names
coef_names_sub <- c(
  "system_typeSemi-Presidential" = "Semi-Presidential System",
  "system_typePresidential" = "Presidential System",
  "mean_democracy" = "Mean Democracy Level",
  "log_gdp" = "Log GDP per Capita",
  "ethnic_frac" = "Ethnic Fractionalization")

# Define goodness-of-fit statistics
gof_stats <- c("nobs", "r.squared", "adj.r.squared")

# Generate the table
tab4 <- modelsummary(
  model_list,
  vcov = "HC1",
  coef_map = coef_names_sub,
  gof_map = gof_stats,
  stars = sig_stars,
  output = "flextable") %>%
  theme_booktabs() %>%
  fontsize(size = 10, part = "all") %>%
  bold(part = "header") %>%
  autofit() %>%
  set_caption("Table 4: Subsample Analysis") %>%
  add_footer_lines("Robust SEs. Reference: Parliamentary systems. * p<0.05; ** p<0.01; *** p<0.001")

doc4 <- read_docx()
doc4 <- body_add_flextable(doc4, tab4)
setwd("/Users/shahin/Documents/GitHub/projects-template/output/tables")
print(doc4, target = "Table4_Subsample.docx")
