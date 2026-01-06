# ============================================================================
# ENHANCED INTERACTION PLOT WITH CONFIDENCE BANDS (UPDATED CROSSOVER)
# ============================================================================

# Create prediction grid
pred_interaction <- expand.grid(
  system_type = c("Parliamentary", "Presidential"),
  log_gdp = seq(6.5, 11, by = 0.05),
  mean_democracy = mean(final_data$mean_democracy, na.rm = TRUE),
  ethnic_frac = mean(final_data$ethnic_frac, na.rm = TRUE)
)

# Get predictions
preds <- predict(m_int_volatility, newdata = pred_interaction, 
                 interval = "confidence", level = 0.95)
pred_interaction <- cbind(pred_interaction, preds)

# Add GDP in dollars for interpretation
pred_interaction$gdp_dollars <- exp(pred_interaction$log_gdp)

# Plot
p <- ggplot(pred_interaction, aes(x = gdp_dollars, y = fit, 
                                  color = system_type, fill = system_type)) +
  geom_line(size = 1.5) +
  geom_ribbon(aes(ymin = lwr, ymax = upr), alpha = 0.2, linetype = 0) +
  geom_vline(xintercept = 14159, linetype = "dashed", color = "gray30") +
  annotate("text", x = 14159, y = 0.08, 
           label = "Crossover:\n$14,159", hjust = -0.1, size = 3.5, family = "Times New Roman") +
  scale_x_log10(
    breaks = c(1000, 5000, 14159, 40000, 80000),
    labels = scales::dollar,
    name = NULL
  ) +
  labs(
    title = "Figure 3: Presidential Systems Are More Stable in Poor Countries",
    subtitle = "But the advantage disappears as countries develop",
    y = "Predicted Democratic Volatility\n(Lower = More Stable)",
    color = "System Type",
    fill = "System Type",
    caption = "Note: Shaded regions show 95% confidence intervals. Predictions hold other variables at means."
  ) +
  theme_minimal() +
  theme(
    legend.position = "bottom",
    plot.title = element_text(face = "bold", size = 14, family = "Times New Roman"),
    plot.subtitle = element_text(size = 11, color = "gray30", family = "Times New Roman"),
    axis.title = element_text(family = "Times New Roman"),
    axis.text = element_text(family = "Times New Roman"),
    legend.text = element_text(family = "Times New Roman"),
    legend.title = element_text(family = "Times New Roman"),
    plot.caption = element_text(family = "Times New Roman")
  ) +
  scale_color_manual(values = c("Parliamentary" = "#2E86AB", "Presidential" = "#A23B72")) +
  scale_fill_manual(values = c("Parliamentary" = "#2E86AB", "Presidential" = "#A23B72"))

# Save
ggsave(here("output", "figures", "Figure3_MainFinding.png"), 
       plot = p, width = 10, height = 6, dpi = 300)

print(p)