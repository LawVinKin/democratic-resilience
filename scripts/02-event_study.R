# Event-study on system-type changes: within-country dynamics of democracy index
# Uses merged_all_years.csv (panel with system_type per year)

library(tidyverse)
library(here)
library(broom)
library(sandwich)
library(lmtest)
library(ggplot2)

out_dir <- here::here("output","robustness")
if(!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)

# Load panel
panel <- read_csv(here::here("data","02-analysis_data","merged_all_years.csv")) %>%
  rename(iso3c = iso3c) %>%
  arrange(iso3c, year)

# Ensure system_type exists and is consistent
panel <- panel %>% select(iso3c, country_name, year, system_type, v2x_libdem, v2x_polyarchy)

# Identify first system change year per country in the sample period (2000-2023)
changes <- panel %>% group_by(iso3c) %>%
  mutate(system_prev = lag(system_type)) %>%
  mutate(change_flag = if_else(!is.na(system_prev) & system_type != system_prev, 1L, 0L)) %>%
  summarize(first_change_year = if_else(any(change_flag == 1L), min(year[which(change_flag == 1L)]), NA_integer_),
            n_changes = sum(change_flag, na.rm = TRUE), .groups = "drop")

# Merge change year back
panel2 <- panel %>% left_join(changes, by = "iso3c")

# Count treated units
treated <- changes %>% filter(!is.na(first_change_year))
cat("Detected", nrow(treated), "countries with at least one system change between 2000-2023\n")

if(nrow(treated) < 3){
  cat("Too few treated units for a meaningful event-study (found <3). Exiting gracefully.\n")
  quit(status = 0)
}

# Define event window: -5 to +5 years around change (inclusive)
w <- 5
panel2 <- panel2 %>% mutate(event_time = if_else(!is.na(first_change_year), year - first_change_year, NA_integer_))

# Create event dummies for k in -5..5, but exclude k = -1 as reference
ks <- seq(-w, w)
ks <- ks[ks != -1]
for(k in ks){
  varname <- paste0("ev_k", k)
  panel2[[varname]] <- as.integer(panel2$event_time == k)
}

# Keep rows with non-missing outcome (use v2x_libdem) and within broader window for treated; include never-treated (they have all zeros)
panel_analysis <- panel2 %>% filter(!is.na(v2x_libdem))

# Fit event-study model: outcome ~ sum(ev_k) + country FE + year FE
ev_terms <- paste0("ev_k", ks, collapse = " + ")
formula_str <- paste0("v2x_libdem ~ ", ev_terms, " + factor(iso3c) + factor(year)")
cat("Estimating event-study model with formula:\n", formula_str, "\n")
fit <- lm(as.formula(formula_str), data = panel_analysis)

# Clustered SEs by country (iso3c)
cluster <- panel_analysis$iso3c
vcov_cl <- sandwich::vcovCL(fit, cluster = cluster, type = "HC1")
ct <- lmtest::coeftest(fit, vcov_cl)

# Extract coefficients for event dummies
coef_tbl <- broom::tidy(ct) %>%
  rownames_to_column(var = "term") %>%
  filter(str_starts(term, "ev_k")) %>%
  mutate(event = as.integer(str_replace(term, "ev_k", ""))) %>%
  select(event, estimate = estimate, std.error = std.error, p.value = p.value)

# Add reference event -1 at zero
coef_tbl <- coef_tbl %>% bind_rows(tibble(event = -1L, estimate = 0, std.error = NA_real_, p.value = NA_real_)) %>% arrange(event)
coef_tbl <- coef_tbl %>% mutate(lower = estimate - 1.96 * std.error, upper = estimate + 1.96 * std.error)

write_csv(coef_tbl, file.path(out_dir, "event_study_coefs.csv"))

# Plot coefficients with CIs
plt <- ggplot(coef_tbl %>% filter(event != -1), aes(x = event, y = estimate)) +
  geom_point(color = "#2c7fb8") +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.2) +
  geom_vline(xintercept = -1, linetype = "dashed", color = "grey30") +
  theme_minimal() +
  labs(x = "Event time (years)", y = "Coefficient on event dummy (v2x_libdem)",
       title = "Event-study: dynamics of liberal democracy around system-type changes (ref = t-1)")

ggsave(file.path(out_dir, "event_study_plot.png"), plt, width = 8, height = 4, dpi = 300)

cat("Event-study complete. Coefficients and plot saved in:", out_dir, "\n")
