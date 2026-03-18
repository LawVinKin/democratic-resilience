library(tidyverse)
library(sandwich)
library(lmtest)
library(modelsummary)
library(here)

dir.create(here("output", "tables"), showWarnings = FALSE, recursive = TRUE)
dir.create(here("output", "figures"), showWarnings = FALSE, recursive = TRUE)
dir.create(here("output", "models"), showWarnings = FALSE, recursive = TRUE)

final_data <- readRDS(here("data", "02-analysis_data", "analytical_sample.rds"))

m1 <- lm(volatility ~ system_type + log_gdp + mean_democracy + ethnic_frac,
         data = final_data)

m2 <- lm(volatility ~ system_type * log_gdp + mean_democracy + ethnic_frac,
         data = final_data)

saveRDS(list(m1 = m1, m2 = m2), here("output", "models", "main_models.rds"))

robust_m1 <- coeftest(m1, vcov = vcovHC(m1, type = "HC1"))
robust_m2 <- coeftest(m2, vcov = vcovHC(m2, type = "HC1"))

vars <- c("system_typeSemi-Presidential", "system_typePresidential", "log_gdp",
          "mean_democracy", "ethnic_frac", "system_typeSemi-Presidential:log_gdp",
          "system_typePresidential:log_gdp")
labels <- c("Semi-Pres.", "Presidential", "Log GDP p.c.", "Mean Democracy",
            "Ethnic Frac.", "Semi-Pres. × GDP", "Pres. × GDP")

add_stars <- function(coef, pval) {
  dplyr::case_when(
    pval < 0.001 ~ paste0(round(coef, 3), "***"),
    pval < 0.01 ~ paste0(round(coef, 3), "**"),
    pval < 0.05 ~ paste0(round(coef, 3), "*"),
    TRUE ~ paste0(round(coef, 3), "")
  )
}

tbl_rows <- list()
for (i in seq_along(vars)) {
  v <- vars[i]
  
  if (v %in% rownames(robust_m1)) {
    m1_coef <- add_stars(robust_m1[v, "Estimate"], robust_m1[v, "Pr(>|t|)"])
    m1_se <- paste0("(", round(robust_m1[v, "Std. Error"], 3), ")")
  } else {
    m1_coef <- ""
    m1_se <- ""
  }
  
  if (v %in% rownames(robust_m2)) {
    m2_coef <- add_stars(robust_m2[v, "Estimate"], robust_m2[v, "Pr(>|t|)"])
    m2_se <- paste0("(", round(robust_m2[v, "Std. Error"], 3), ")")
  } else {
    m2_coef <- ""
    m2_se <- ""
  }
  
  tbl_rows[[length(tbl_rows) + 1]] <- c(labels[i], m1_coef, m2_coef)
  tbl_rows[[length(tbl_rows) + 1]] <- c("", m1_se, m2_se)
}

tbl_rows[[length(tbl_rows) + 1]] <- c("N", nrow(model.frame(m1)), nrow(model.frame(m2)))
tbl_rows[[length(tbl_rows) + 1]] <- c("R²", round(summary(m1)$r.squared, 3), round(summary(m2)$r.squared, 3))
tbl_rows[[length(tbl_rows) + 1]] <- c("Adj. R²", round(summary(m1)$adj.r.squared, 3), round(summary(m2)$adj.r.squared, 3))

tbl_df <- do.call(rbind, tbl_rows) %>% as.data.frame()
names(tbl_df) <- c(" ", "Controls", "Interaction")

write_csv(tbl_df, here("output", "tables", "main_results.csv"))

beta_pres <- coef(m2)["system_typePresidential"]
beta_pres_x_gdp <- coef(m2)["system_typePresidential:log_gdp"]

log_gdp_crossover <- -beta_pres / beta_pres_x_gdp
gdp_crossover <- exp(log_gdp_crossover)

crossover_results <- tibble(
  metric = c("log_gdp_crossover", "gdp_crossover_ppp"),
  value = c(log_gdp_crossover, gdp_crossover)
)
write_csv(crossover_results, here("output", "models", "crossover_point.csv"))

gdp_levels <- tibble(
  level = c("Low ($5,000)", paste0("Crossover ($", format(round(gdp_crossover, 0), big.mark = ","), ")"), "High ($40,000)"),
  log_gdp = c(log(5000), log_gdp_crossover, log(40000))
)

pred_grid <- expand.grid(
  system_type = c("Parliamentary", "Presidential"),
  log_gdp = gdp_levels$log_gdp,
  mean_democracy = mean(final_data$mean_democracy, na.rm = TRUE),
  ethnic_frac = mean(final_data$ethnic_frac, na.rm = TRUE)
)

pred_grid$predicted <- predict(m2, newdata = pred_grid)

table3 <- pred_grid %>%
  pivot_wider(names_from = system_type, values_from = predicted) %>%
  mutate(
    difference = Presidential - Parliamentary,
    pct_change = round((difference / Parliamentary) * 100, 1),
    level = gdp_levels$level
  ) %>%
  select(level, Parliamentary, Presidential, difference, pct_change)

write_csv(table3, here("output", "tables", "predicted_volatility.csv"))

pred_data <- expand.grid(
  system_type = c("Parliamentary", "Presidential"),
  log_gdp = seq(min(final_data$log_gdp, na.rm = TRUE),
                max(final_data$log_gdp, na.rm = TRUE),
                length.out = 100),
  mean_democracy = mean(final_data$mean_democracy, na.rm = TRUE),
  ethnic_frac = mean(final_data$ethnic_frac, na.rm = TRUE)
)

pred_results <- predict(m2, newdata = pred_data, se.fit = TRUE)
pred_data$predicted <- pred_results$fit
pred_data$se <- pred_results$se.fit
pred_data$lower <- pred_data$predicted - 1.96 * pred_data$se
pred_data$upper <- pred_data$predicted + 1.96 * pred_data$se
pred_data$gdp <- exp(pred_data$log_gdp)

case_countries <- final_data %>%
  filter(country_name %in% c("India", "Ghana", "Indonesia")) %>%
  select(country_name, system_type, log_gdp, volatility) %>%
  mutate(gdp = exp(log_gdp))

fig1 <- ggplot(pred_data, aes(x = gdp, y = predicted, color = system_type, fill = system_type)) +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2, color = NA) +
  geom_line(linewidth = 1.2) +
  geom_point(data = case_countries, aes(x = gdp, y = volatility, color = system_type),
             size = 3, shape = 18, show.legend = FALSE) +
  geom_text(data = case_countries, aes(x = gdp, y = volatility, label = country_name),
            hjust = 0, vjust = 1.5, size = 3.5, color = "darkblue", fontface = "bold", show.legend = FALSE) +
  geom_vline(xintercept = gdp_crossover, linetype = "dashed", color = "gray40") +
  annotate("text", x = gdp_crossover * 1.1, y = max(pred_data$predicted) * 0.95,
           label = paste0("Crossover: $", format(round(gdp_crossover, 0), big.mark = ",")),
           hjust = 0, size = 3.5, color = "gray40") +
  scale_x_continuous(labels = scales::dollar_format(), trans = "log10",
                     breaks = c(2000, 5000, 10000, 20000, 50000)) +
  scale_color_manual(values = c("Parliamentary" = "#2166AC", "Presidential" = "#B2182B")) +
  scale_fill_manual(values = c("Parliamentary" = "#2166AC", "Presidential" = "#B2182B")) +
  labs(
    x = "GDP per Capita (PPP, log scale)",
    y = "Predicted Democratic Volatility",
    color = "System Type",
    fill = "System Type",
    caption = "Diamond markers show actual volatility for case study countries."
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold"),
    axis.title.x = element_text(face = "bold"),
    axis.title.y = element_text(face = "bold"),
    text = element_text(family = "serif")
  )

ggsave(here("output", "figures", "Figure1_interaction.png"), fig1, 
       width = 8, height = 5, dpi = 300)
ggsave(here("output", "figures", "Figure1_interaction.pdf"), fig1, 
       width = 8, height = 5)
