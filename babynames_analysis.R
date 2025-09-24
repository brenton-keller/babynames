
# For your 5120x2160 screen
screen_width <- 5120
screen_height <- 2160

center_x <- (screen_width / 2) - 400  # = 2160
center_y <- (screen_height / 2) - 300  # = 780

windows(width = 12, height = 8, pointsize = 14, xpos = center_x, ypos = center_y)

## Notes
    # **Shape:**
    # - **Skewness** - asymmetry (left/right tail heavy)
    # - **Kurtosis** - tail heaviness vs normal distribution
    # 
    # **Position:**
    # - **Quantiles/Percentiles** - 25th, 75th, 95th, etc.
    # - **IQR** - interquartile range (robust spread measure)
    # 
    # **Robust alternatives:**
    # - **MAD** - median absolute deviation (robust to outliers)
    # - **Range** - max - min (simple but fragile)
    # 
    # **For your babynames context specifically:**
    # - **Entropy** - how "spread out" popularity is across names
    # - **Gini coefficient** - inequality measure (how concentrated popularity is)
    # - **Peak year** - when a name hit maximum popularity
    # - **Trend slope** - is it rising/falling over time
    # 
    # For time series like name popularity, you might also want:
    # - **Autocorrelation** - how much each year predicts the next
    # - **Changepoint detection** - when did trends shift
    # 
    # CV falls into **"Relative/Normalized measures"** - metrics that combine multiple distribution properties to # enable meaningful comparisons.
    # 
    # **Efficiency/Signal ratios:**
    # - **Signal-to-noise ratio** - mean/sd (inverse of CV)
    # - **Sharpe ratio** - (return - risk_free_rate)/volatility 
    # - **Information ratio** - excess_return/tracking_error
    # 
    # **Standardized scores:**
    # - **Z-score** - (value - mean)/sd
    # - **T-statistic** - (sample_mean - pop_mean)/(sd/√n)
    # - **Effect size (Cohen's d)** - difference_in_means/pooled_sd
    # 
    # **Inequality measures:**
    # - **Gini coefficient** - combines area under Lorenz curve with perfect equality
    # - **Theil index** - entropy-based inequality using mean and individual values
    # 
    # **Risk-adjusted measures:**
    # - **VaR (Value at Risk)** - combines quantile with scale
    # - **Calmar ratio** - return/max_drawdown
    # 
    # **For your babynames:**
    # - **Popularity momentum** - (recent_trend)/(historical_volatility)
    # - **Cultural penetration** - (peak_popularity)/(years_to_peak)
## Notes
