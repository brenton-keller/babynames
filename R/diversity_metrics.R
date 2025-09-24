
calculate_diversity <- function(dt, start_year = 1970) {
  # Entropy: measures distribution evenness (higher = more diverse)
  # Gini: measures inequality (0 = equal, 1 = maximum inequality)
  get_name_stats(dt)[year >= start_year, {
    props <- prop[prop > 0]
    list(
      entropy = -sum(props * log(props)),
      gini = {
        x <- sort(props)
        n <- length(x)
        2 * sum((1:n) * x) / (n * sum(x)) - (n + 1) / n
      }
    )
  }, by = .(year, sex)]
}

plot_diversity <- function(dt, start_year = 1970) {
  div_data <- calculate_diversity(dt, start_year)
  
  par(mfrow = c(2,1))
  
  # Entropy plot
  plot(div_data[sex == "M", year], div_data[sex == "M", entropy],
       type = "l", col = "blue", lwd = 2, main = "Name Diversity (Entropy)",
       xlab = "Year", ylab = "Entropy")
  lines(div_data[sex == "F", year], div_data[sex == "F", entropy], 
        col = "red", lwd = 2)
  legend("topright", c("Male", "Female"), col = c("blue", "red"), lwd = 2)
  
  # Gini plot  
  plot(div_data[sex == "M", year], div_data[sex == "M", gini],
       type = "l", col = "blue", lwd = 2, main = "Name Inequality (Gini)",
       xlab = "Year", ylab = "Gini Coefficient")
  lines(div_data[sex == "F", year], div_data[sex == "F", gini],
        col = "red", lwd = 2)
  legend("topright", c("Male", "Female"), col = c("blue", "red"), lwd = 2)
}

filter_rare <- function(dt, min_pct = 0.001, min_n = 10, by = c("year","sex")){
  dt[, tot := sum(n), by=by][ n >= pmax(min_n, ceiling(tot * min_pct/100)) ][, tot := NULL][]
}

div_metrics <- function(dt, start_year = 1971){
  dt[year >= start_year][, {
    p <- n/sum(n); H <- -sum(p*log(p)); hh <- sum(p^2)
    list(
      total_n = sum(n),
      N_unique = uniqueN(name),
      entropy = H,
      shannon_eff = exp(H),   # Hill q=1 (effective # of names)
      hill_q2 = 1/hh,         # Hill q=2 (1/Herfindahl)
      top1 = max(p),
      top10 = sum(sort(p, TRUE)[seq_len(min(.N,10))])
    )
  }, by=.(year,sex)]
}

trend_test <- function(div, y = "shannon_eff", quad = TRUE){
  div[, {
    f <- reformulate(c("year", if (quad) "I(year^2)"), response = y)
    m <- lm(f, .SD, weights = total_n)
    s <- summary(m)$coef; list(
      y_var = y,
      beta_year = unname(s["year","Estimate"]),
      p_year = unname(s["year","Pr(>|t|)"]),
      beta_year2 = if (quad) unname(s["I(year^2)","Estimate"]) else NA_real_,
      p_year2 = if (quad) unname(s["I(year^2)","Pr(>|t|)"]) else NA_real_,
      r2 = summary(m)$adj.r.squared
    )
  }, by=sex]
}

# Diagnose quadratic fits: turning-point year and endpoint slopes
quad_diag <- function(res, t0 = 1971, t1 = 2024){
  res[, .(sex, y_var,
          turn_year = -beta_year/(2*beta_year2),
          slope_start = beta_year + 2*beta_year2*t0,
          slope_end   = beta_year + 2*beta_year2*t1)]
}

trend_test_center <- function(div, y, ref = 2000){
  div[, yr := year - ref][, {
    m <- lm(reformulate(c("yr","I(yr^2)"), response = y), .SD, weights = total_n)
    s <- summary(m)$coef
    list(beta_yr = s["yr","Estimate"], p_yr = s["yr","Pr(>|t|)"],
         beta_yr2 = s["I(yr^2)","Estimate"], p_yr2 = s["I(yr^2)","Pr(>|t|)"],
         r2 = summary(m)$adj.r.squared)
  }, by = sex]
}

plot_quad <- function(div, y = "top10", s = "M") {
  d <- div[sex == s][order(year)]
  m <- lm(reformulate(c("year","I(year^2)"), response = y), d, weights = total_n)
  plot(d$year, d[[y]], type="l", lwd=2, col=ifelse(s=="M","blue","red"),
       xlab="Year", ylab=y, main=paste(y, "(", s, ")"))
  lines(d$year, predict(m), lwd=2, lty=2, col="gray40")
  if (coef(m)["I(year^2)"] > 0) {
    tp <- -coef(m)["year"]/(2*coef(m)["I(year^2)"])
    abline(v = tp, col="orange", lty=3, lwd=2)
  }
}

mono_test <- function(div, y){
  div[, { ct <- cor.test(year, get(y), method="kendall")
  list(tau = unname(ct$estimate), p = ct$p.value) }, by=sex]
}

# Decade-level summary (weighted by births) + within-decade change
decade_summary <- function(div, y = "shannon_eff"){
  div[order(year), .(
    mean   = weighted.mean(get(y), total_n),
    start  = first(get(y)),
    end    = last(get(y)),
    delta  = last(get(y)) - first(get(y))  # within-decade net change
  ), by = .(sex, decade = 10L*(year %/% 10L))][order(sex, decade)][
    , `:=`(prev = shift(mean),
           abs_change = mean - shift(mean),
           pct_change = 100*(mean/shift(mean) - 1)), by = sex][]
}

# Base R plot for any diversity metric with loess trend and optional breakpoints
plot_metric <- function(div, y = "shannon_eff", span = 0.4, show_breaks = TRUE) {
  op <- par(mfrow = c(2,1), mar = c(4,4,2,1)); on.exit(par(op))
  cols <- c(M="blue", F="red")
  for (s in sort(unique(div$sex))) {
    d <- div[sex == s][order(year)]
    yv <- d[[y]]
    plot(d$year, yv, type="l", lwd=2, col=cols[s], xlab="Year", ylab=y,
         main = paste0(y, " (", s, ")"))
    points(d$year, yv, pch=16, cex=.55, col=grDevices::adjustcolor(cols[s], .5))
    pred <- predict(stats::loess(stats::as.formula(paste(y, "~ year")), data=d, span=span),
                    newdata = data.frame(year = d$year))
    lines(d$year, pred, col="gray30", lwd=2, lty=2)
    if (show_breaks && requireNamespace("strucchange", quietly=TRUE)) {
      bp <- strucchange::breakpoints(stats::as.formula(paste(y, "~ year")), data=d, h=0.15)
      if (length(bp$breakpoints)) abline(v = d$year[bp$breakpoints], col="orange", lwd=2, lty=3)
    }
  }
}

# "How many names to cover X% of births?" (computed on name-level data)
k_coverage <- function(dt, p = c(.5, .8, .9), by = c("year","sex")){
  dt[, { o <- order(-n); cp <- cumsum(n[o]) / sum(n)
        setNames(as.list(sapply(p, function(th) which.max(cp >= th))),
                 paste0("K", as.integer(p*100))) }, by = by]
}

plot_k <- function(kdt, k = "K50") {
  cols <- c(M="blue", F="red")
  rng <- range(kdt[[k]], na.rm=TRUE)
  plot(NA, xlim=range(kdt$year), ylim=rng, xlab="Year", ylab=k, main=k)
  for (s in sort(unique(kdt$sex))) {
    d <- kdt[sex == s][order(year)]
    lines(d$year, d[[k]], col=cols[s], lwd=2)
  }
  legend("topleft", legend=sort(unique(kdt$sex)), col=cols[sort(unique(kdt$sex))], lwd=2, bty="n")
}
