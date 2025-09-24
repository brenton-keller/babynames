# data.table helpers: rare-name filter, diversity metrics, trend test
# example usage (national, year > 1970), filter out very-rare names
div <- babynames$national |>
  filter_rare(min_pct = 0.001, min_n = 10) |>
  div_metrics(start_year = 1971)

# test "more diversity over time?" (expect + slope for shannon_eff, hill_q2; - slope for top10)
trend_div1 <- trend_test(div, y = "shannon_eff", quad = TRUE)
trend_div2 <- trend_test(div, y = "hill_q2", quad = TRUE)
trend_conc <- trend_test(div, y = "top10", quad = TRUE)   # concentration; negative slope => more diversity

# quick peek
div[order(year)][sex=="F"]
trend_div1
trend_conc


quad_diag(trend_div1)  # shannon_eff: minima ~1940 (F), ~1970 (M); slopes > 0 and growing
quad_diag(trend_conc)  # top10: minima far future for M (~2060); slopes < 0 but shrinking

trend_test_center(div, "top10")       # expect clearer “down then flatten” for M
trend_test_center(div, "shannon_eff") # “up + accelerating” both sexes

plot_quad(div, "top10", "M")          # decelerating decline; small recent bounce is visible
plot_quad(div, "shannon_eff", "M")    # accelerating rise since ~1970
plot_quad(div, "shannon_eff", "F")

mono_test(div, "shannon_eff")  # strong + monotonic trend
mono_test(div, "top10")        # strong − monotonic trend (esp. M)




# Visuals
plot_metric(div, y = "shannon_eff")   # rising = more diverse
plot_metric(div, y = "top10")         # falling = less dominance

# Decade context
decade_summary(div, "shannon_eff")[order(sex, decade)]
decade_summary(div, "top10")[order(sex, decade)]

# Coverage counts (use the same filtered name-level data you built div from)
dt_filt <- babynames$national[year >= 1971]   # or your rare-name-filtered dt
kdt <- k_coverage(dt_filt, p = c(.5, .8))     # K50, K80 per year/sex
plot_k(kdt, "K50")
plot_k(kdt, "K80")

