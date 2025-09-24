
add_proportions <- function(dt, ...) {
  dt[, prop := n / sum(n), by = c(...)][]
}

get_era_winners <- function(dt, start_year = 1980, period_length = 5) {
  # Find top unique name for each era by sex
  ranked <- dt[year >= start_year, 
    .(total_n = sum(n)), 
    by = .(name, sex, era = period_length * (year %/% period_length))
  ][order(sex, era, -total_n)]
  
  ranked[, {
    used <- character(0)
    rbindlist(lapply(unique(era), function(e) {
      winner <- .SD[era == e & !name %in% used][1]
      used <<- c(used, winner$name)
      winner[, era_label := paste0(e, "-", e + period_length - 1)][]
    }))
  }, by = sex]
}

get_name_stats <- function(dt, years = NULL, add_props = TRUE) {
  if (add_props) dt <- add_proportions(dt, "year", "sex")
  if (!is.null(years)) dt <- dt[year %in% years]
  dt
}

name_stability <- function(data = babynames$national, 
                          min_year = 1990, 
                          target_sex = "M", 
                          min_total = 1000) {
  
  result <- copy(data)[
    , n_prop := n/sum(n), .(year, sex)][
    year > min_year & sex == target_sex][
    , .(
      total_babies = sum(n),
      avg_proportion = mean(n_prop),
      cv = sd(n_prop)/mean(n_prop),
      years_present = .N
    ), .(name)][
    total_babies >= min_total][
    order(cv)]
  
  # Add interpretive labels
  result[, stability := fcase(
    cv < 0.2, "Very Stable",
    cv < 0.4, "Stable", 
    cv < 0.6, "Moderate",
    cv < 0.8, "Variable",
    default = "Highly Variable"
  )]
  
  result[, c("name", "total_babies", "avg_proportion", "cv", "stability", "years_present")]
}
