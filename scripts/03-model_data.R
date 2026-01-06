# This script will run our main analysis.

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


# Main Models
m1 <- lm(volatility ~ system_type + log_gdp + mean_democracy + ethnic_frac,
         data = final_data)

m2 <- lm(volatility ~ system_type * log_gdp + mean_democracy + ethnic_frac,
         data = final_data)


# Table 1: Main Results
# We'll create a side-by-side table of the two models using modelsummary

# First, we'll define the models separately
model_list <- list(
  "Full Controls" = m1,
  "Interaction Model" = m2)

# Define the coefficient names for better readability
coef_names <- c(
  "system_typeSemi-Presidential" = "Semi-Presidential System",
  "system_typePresidential" = "Presidential System",
  "log_gdp" = "Log GDP per Capita (PPP)",
  "mean_democracy" = "Mean Democracy Level (2000–2023)",
  "ethnic_frac" = "Ethnic Fractionalization",
  "system_typeSemi-Presidential:log_gdp" = "Semi-Presidential × Log GDP",
  "system_typePresidential:log_gdp" = "Presidential × Log GDP")

# Define goodness-of-fit statistics to display
gof_stats <- c("nobs", "r.squared", "adj.r.squared")

#  significance stars
sig_stars <- c('*' = .05, '**' = .01, '***' = .001)

# generating the table
tab1 <- modelsummary(
  model_list,
  vcov = "HC1",
  coef_map = coef_names,
  gof_map = gof_stats,
  stars = sig_stars,
  output = "flextable") %>%
  # these are styling features
  theme_booktabs() %>%
  fontsize(size = 10, part = "all") %>%
  bold(part = "header") %>%
  align(align = "center", part = "all") %>%
  align(j = 1, align = "left", part = "all") %>%
  autofit() %>%
  set_caption("Table 1: Democratic Volatility and Government System Type") %>%
  add_footer_lines("Robust SEs in parentheses. Reference: Parliamentary systems. * p<0.05; ** p<0.01; *** p<0.001")

doc <- read_docx()
doc <- body_add_flextable(doc, tab1)
setwd("/Users/shahin/Documents/GitHub/projects-template/output/tables")
print(doc, target = "Table1_MainResults.docx")


# Calculate Crossover Point
beta_pres <- coef(m2)["system_typePresidential"]
beta_pres_x_gdp <- coef(m2)["system_typePresidential:log_gdp"]

log_gdp_crossover <- -beta_pres / beta_pres_x_gdp
gdp_crossover <- exp(log_gdp_crossover)


# Table 3: Predicted Values at Different GDP Levels
gdp_levels <- tibble(
  level = c("Low ($5,000)", paste0("Crossover ($", format(round(gdp_crossover, 0), big.mark = ","), ")"), "High ($40,000)"),
  log_gdp = c(log(5000), log_gdp_crossover, log(40000)))

pred_grid <- expand.grid(
  system_type = c("Parliamentary", "Presidential"),
  log_gdp = gdp_levels$log_gdp,
  mean_democracy = mean(final_data$mean_democracy, na.rm = TRUE),
  ethnic_frac = mean(final_data$ethnic_frac, na.rm = TRUE))

pred_grid$predicted <- predict(m2, newdata = pred_grid)

table3 <- pred_grid %>%
  pivot_wider(names_from = system_type, values_from = predicted) %>%
  mutate(
    difference = Presidential - Parliamentary,
    pct_change = round((difference / Parliamentary) * 100, 1),
    level = gdp_levels$level) %>%
  select(level, Parliamentary, Presidential, difference, pct_change)

tab3 <- flextable(table3) %>%
  theme_booktabs() %>%
  fontsize(size = 10, part = "all") %>%
  bold(part = "header") %>%
  align(align = "center", part = "all") %>%
  align(j = 1, align = "left", part = "all") %>%
  autofit() %>%
  set_caption("Table 3: Predicted Volatility at Different GDP Levels") %>%
  add_footer_lines("Predicted values from Interaction Model. Reference: Parliamentary systems.")

doc3 <- read_docx()
doc3 <- body_add_flextable(doc3, tab3)
print(doc3, target = "Table3_Crossover.docx")
