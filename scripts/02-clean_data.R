# This script cleans and merges data 

library(tidyverse)
library(countrycode)

vdem <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/vdem_2000_2023.csv")
dpi <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/dpi_processed.csv")
qog <- read_csv("/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/qog_processed.csv")

# Add ISO codes to V-Dem so we can easily merge using left_join()
vdem <- vdem %>%
  mutate(iso3c = countrycode(country_name, "country.name", "iso3c"))

# Merge datasets
merged <- vdem %>%
  left_join(dpi, by = "iso3c") %>%
  left_join(qog, by = "iso3c")

# Save merged panel
write_csv(merged, "/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/merged_all_years.csv")

# Creating our variables of interest. In this section
# In this case, we're making the measure of democratic stability/resilience
# To diversify our appraoch, we're making three different measures of stability

# The first is the standard deviation of democracy scores (volatility).
# While the simplest, it has the potential to be misinterpretted if a country has a 
# positive trend. That is, if the country is steadily improving, the standard deviation
# will still be high, even though the country is not unstable but becoming more democratic.

# To account for this, we also make two additional measures:
# The second one is total decline, which sums up all year-over-year declines in democracy scores.
# This captures the negative changes only.

# The third one is counting the number of backsliding episodes, defined as year-over-year drops
# greater than 0.05 in the democracy score. This captures the frequency of significant declines in a specific country
# which would speak volumes about the democratic stability of that country.

# Measure 1: Volatility (standard deviation of democracy scores)
stability_sd <- merged %>%
  group_by(country_name, iso3c) %>%
  summarize(
    volatility = sd(v2x_libdem),
    mean_democracy = mean(v2x_libdem),
    n_years = sum(!is.na(v2x_libdem))) %>% # count number of non-missing years; this is needed for the filter function later
  ungroup() %>%
  filter(n_years >= 20) # So that we keep only countries with at least 20 years of data

# Measure 2: Total decline (sum of year-over-year decreases)
stability_decline <- merged %>%
  group_by(country_name, iso3c) %>%
  arrange(year) %>%
  mutate(change = v2x_libdem - lag(v2x_libdem)) %>%
  filter(change < 0) %>%
  summarize(
    total_decline = sum(abs(change)), # the abs function calculates the absolute value,
    avg_decline = mean(abs(change)), # ensuring that we get positive numbers
    n_declines = n()) %>%
  ungroup()

# Measure 3: Backsliding episodes (>0.05 drops)
stability_episodes <- merged %>%
  group_by(country_name, iso3c) %>%
  arrange(year) %>%
  mutate(
    change = v2x_libdem - lag(v2x_libdem),
    major_decline = change < -0.05) %>%
  summarize(
    had_backsliding = any(major_decline), # this shows if any major decline took place
    n_episodes = sum(major_decline)) %>% # this counts the number of these episodes
  ungroup()

# Combine all stability measures
stability_all <- stability_sd %>%
  left_join(stability_decline, by = c("country_name", "iso3c")) %>%
  left_join(stability_episodes, by = c("country_name", "iso3c")) %>%
  mutate(
    total_decline = replace_na(total_decline, 0), # this replaces NAs with 0s for countries with no declines
    n_declines = replace_na(n_declines, 0), # same as above, but for number of declines
    n_episodes = replace_na(n_episodes, 0), # same, but for number of episodes
    had_backsliding = replace_na(had_backsliding, FALSE)) # same, but for backsliding flag

write_csv(stability_all, "/Users/shahin/Documents/GitHub/projects-template/data/02-analysis_data/stability_measures.csv")
