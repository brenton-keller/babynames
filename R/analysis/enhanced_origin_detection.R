# ENHANCED ORIGIN DETECTION FOR WEEK 2
# Fixed algorithm that only analyzes TRULY_NEW and EMERGING names
# Uses population weighting and full historical context

# LOAD CLASSIFICATION DATA ====

#' Load the Week 1 classification results and filter for suitable names
#' @return List with classified names suitable for origin analysis
load_suitable_names <- function() {

  class_file <- "data/processed/name_classifications.rds"

  if (!file.exists(class_file)) {
    message("❌ Classification data not found. Run Week 1 classification first:")
    message("    source('tests/test_name_classification.R')")
    return(NULL)
  }

  message("✅ Loading Week 1 classification data...")
  classification_data <- readRDS(class_file)

  # Filter for names suitable for origin analysis
  suitable_names <- classification_data$classified_names[
    classification %in% c("TRULY_NEW", "EMERGING")
  ]

  message("📊 Found ", nrow(suitable_names), " names suitable for origin analysis:")
  summary_stats <- suitable_names[, .N, by = classification]
  for (i in 1:nrow(summary_stats)) {
    message("   ", summary_stats[i, classification], ": ", format(summary_stats[i, N], big.mark = ","))
  }

  return(list(
    suitable_names = suitable_names,
    all_classifications = classification_data$classified_names
  ))
}

# ENHANCED ORIGIN DETECTION ====

#' Enhanced origin detection that only analyzes suitable names
#' @param state_dt Raw state data
#' @param min_total_births Minimum total births across all states
#' @param min_states Minimum states name must appear in
#' @param confidence_threshold Minimum confidence for reliable results
find_enhanced_origins <- function(state_dt, min_total_births = 100, min_states = 5, confidence_threshold = 0.5) {

  # Load suitable names from Week 1 classification
  suitable_data <- load_suitable_names()
  if (is.null(suitable_data)) return(NULL)

  suitable_names <- suitable_data$suitable_names

  message("🔍 Analyzing origins for ", nrow(suitable_names), " suitable names...")

  # Filter state data to only include suitable names
  # Create lookup for efficient filtering
  suitable_lookup <- suitable_names[, .(name, sex)]
  setkey(suitable_lookup, name, sex)
  setkey(state_dt, name, sex)

  # Filter state data to only suitable names
  filtered_state_dt <- suitable_lookup[state_dt, nomatch = 0]

  message("📈 Filtered from ", format(nrow(state_dt), big.mark = ","),
         " to ", format(nrow(filtered_state_dt), big.mark = ","), " state records")

  # Calculate total births per name to filter small names
  name_totals <- filtered_state_dt[, .(total_births = sum(n)), by = .(name, sex)]
  qualified_names <- name_totals[total_births >= min_total_births]

  # Filter to qualified names
  qualified_state_dt <- qualified_names[filtered_state_dt, on = .(name, sex), nomatch = 0]

  message("🎯 Analyzing ", nrow(qualified_names), " names with enough births (≥", min_total_births, ")")

  # For each qualified name, find the origin using enhanced algorithm
  origins <- qualified_state_dt[, {

    # Get first appearance year and early years window
    first_year <- min(year)
    early_years <- first_year:(first_year + 4)  # 5 year window

    # Get data from early emergence period
    early_data <- .SD[year %in% early_years]

    if (nrow(early_data) == 0) {
      return(data.table(
        origin_state = NA_character_,
        origin_year = NA_integer_,
        confidence_score = 0.0,
        total_early_births = 0L,
        n_early_states = 0L
      ))
    }

    # Calculate state population weights (assuming larger states = higher baseline)
    # For simplicity, use total births in that year as proxy for state size
    state_sizes <- early_data[, .(state_size = sum(n)), by = .(state, year)]
    early_with_sizes <- state_sizes[early_data, on = .(state, year)]

    # Calculate origin metrics for each state in early period
    state_metrics <- early_with_sizes[, {

      # Core metrics
      total_births_state <- sum(n)
      years_present <- uniqueN(year)
      first_year_in_state <- min(year)

      # Population-adjusted proportion
      # Higher proportion relative to state size indicates cultural significance
      avg_state_size <- mean(state_size)
      pop_adjusted_prop <- total_births_state / avg_state_size

      # Early emergence bonus (earlier = better for origin)
      early_bonus <- max(0, 5 - (first_year_in_state - first_year))

      # Consistency score (appearing in multiple early years)
      consistency <- years_present / length(early_years)

      # Combined origin score
      origin_score <- (
        log1p(total_births_state) * 2 +     # Raw births (log scale)
        pop_adjusted_prop * 1000 +          # Population-adjusted significance
        early_bonus * 3 +                   # Early emergence bonus
        consistency * 4                     # Consistency across years
      )

      list(
        total_births = total_births_state,
        years_present = years_present,
        first_year_in_state = first_year_in_state,
        pop_adjusted_prop = pop_adjusted_prop,
        early_bonus = early_bonus,
        consistency = consistency,
        origin_score = origin_score
      )
    }, by = state]

    # Check if we have enough states for reliable analysis
    if (nrow(state_metrics) < min_states) {
      return(data.table(
        origin_state = NA_character_,
        origin_year = NA_integer_,
        confidence_score = 0.0,
        total_early_births = sum(early_data$n),
        n_early_states = nrow(state_metrics)
      ))
    }

    # Find the state with highest origin score
    best_state <- state_metrics[which.max(origin_score)]

    # Improved confidence calculation
    # Base confidence on multiple factors, not just score gap

    # Factor 1: Score separation (how much better is the best state?)
    sorted_scores <- sort(state_metrics$origin_score, decreasing = TRUE)
    if (length(sorted_scores) >= 2) {
      score_gap <- sorted_scores[1] - sorted_scores[2]
      score_separation <- score_gap / sorted_scores[1]  # Relative gap
    } else {
      score_separation <- 1.0  # Only one state = perfect confidence
    }

    # Factor 2: Early emergence (appeared in first year = high confidence)
    early_emergence_conf <- if (best_state$first_year_in_state == first_year) {
      0.8  # High confidence for first-year appearance
    } else {
      0.4  # Lower confidence for later appearance
    }

    # Factor 3: Consistency (appeared in multiple early years)
    consistency_conf <- min(1.0, best_state$years_present / 3)  # Up to 3 years is ideal

    # Factor 4: Birth volume (more births = higher confidence)
    birth_volume_conf <- min(1.0, log1p(best_state$total_births) / 10)

    # Combined confidence score (weighted average)
    confidence_score <- (
      score_separation * 0.3 +      # How distinctive is this state?
      early_emergence_conf * 0.3 +  # Did it appear early?
      consistency_conf * 0.2 +      # Is it consistent over time?
      birth_volume_conf * 0.2       # Are there enough births?
    )

    list(
      origin_state = best_state$state,
      origin_year = as.integer(best_state$first_year_in_state),
      confidence_score = confidence_score,
      total_early_births = as.integer(sum(early_data$n)),
      n_early_states = as.integer(nrow(state_metrics)),
      origin_score = best_state$origin_score,
      pop_adjusted_prop = best_state$pop_adjusted_prop
    )
  }, by = .(name, sex)]

  # Filter results by confidence threshold
  confident_origins <- origins[confidence_score >= confidence_threshold]

  message("✅ Found ", nrow(confident_origins), " high-confidence origins (≥", confidence_threshold, ")")

  # Add classification info back
  origins_with_class <- suitable_names[origins, on = .(name, sex)]

  # Return both confident and all results
  list(
    all_origins = origins_with_class,
    confident_origins = confident_origins,
    summary_stats = list(
      total_analyzed = nrow(origins),
      high_confidence = nrow(confident_origins),
      confidence_rate = nrow(confident_origins) / nrow(origins)
    )
  )
}

# VISUALIZATION FUNCTIONS ====

#' Show top origin results in a clean table
#' @param origins_result Result from find_enhanced_origins()
#' @param n_show Number of results to show
show_origin_results <- function(origins_result, n_show = 15) {

  if (is.null(origins_result)) return(invisible(NULL))

  confident <- origins_result$confident_origins

  if (nrow(confident) == 0) {
    message("❌ No high-confidence origins found")
    return(invisible(NULL))
  }

  message("🎯 TOP ORIGIN RESULTS (High Confidence)")
  message("=" %r% 60)

  # Sort by confidence and show top results
  top_results <- head(confident[order(-confidence_score)], n_show)

  cat(sprintf("%-12s %-3s %-8s %-4s %-5s %-8s %-12s\n",
              "Name", "Sex", "Origin", "Year", "Conf", "Births", "Class"))
  message("-" %r% 60)

  for (i in 1:nrow(top_results)) {
    d <- top_results[i]
    cat(sprintf("%-12s %-3s %-8s %-4d %-5.1f%% %-8d %-12s\n",
                d$name,
                d$sex,
                d$origin_state,
                d$origin_year,
                d$confidence_score * 100,
                d$total_early_births,
                d$classification))
  }

  message("\n📊 Summary: ", origins_result$summary_stats$high_confidence, " of ",
         origins_result$summary_stats$total_analyzed, " names (",
         round(origins_result$summary_stats$confidence_rate * 100, 1), "% confident)")

  invisible(top_results)
}

#' Investigate origin of specific name
#' @param name_to_investigate Name to analyze
#' @param sex_to_investigate Sex ("M", "F", or "both")
investigate_origin <- function(name_to_investigate, sex_to_investigate = "both") {

  message("🔍 INVESTIGATING ORIGIN: ", name_to_investigate)
  message("=" %r% 50)

  # Load state data
  source("R/core/data_cache_manager.R")
  full_data <- load_babynames_cached(include_state = TRUE)

  if (is.null(full_data)) {
    message("❌ Could not load state data")
    return(invisible(NULL))
  }

  # Get origins for this specific name
  if (sex_to_investigate == "both") {
    target_data <- full_data$state[name == stringr::str_to_title(name_to_investigate)]
  } else {
    target_data <- full_data$state[name == stringr::str_to_title(name_to_investigate) &
                                  sex == sex_to_investigate]
  }

  if (nrow(target_data) == 0) {
    message("❌ Name not found in state data")
    return(invisible(NULL))
  }

  # Run enhanced origin detection on just this name
  origins <- find_enhanced_origins(target_data, min_total_births = 10, min_states = 3)

  if (is.null(origins) || nrow(origins$all_origins) == 0) {
    message("❌ Could not determine origin for this name")
    return(invisible(NULL))
  }

  # Show results
  for (i in 1:nrow(origins$all_origins)) {
    result <- origins$all_origins[i]

    message("\n📍 ", result$name, " (", result$sex, ")")
    message("   Origin: ", result$origin_state, " in ", result$origin_year)
    message("   Confidence: ", round(result$confidence_score * 100, 1), "%")
    message("   Early births: ", format(result$total_early_births, big.mark = ","))
    message("   Classification: ", result$classification)

    if (result$confidence_score < 0.7) {
      message("   ⚠️ Low confidence - results may be unreliable")
    }
  }

  invisible(origins$all_origins)
}

# CONVENIENCE FUNCTIONS ====

#' Quick test of enhanced origin detection
test_enhanced_origins <- function() {

  message("🧪 TESTING ENHANCED ORIGIN DETECTION")
  message("=" %r% 50)

  # Load state data
  source("R/core/data_cache_manager.R")
  full_data <- load_babynames_cached(include_state = TRUE)

  if (is.null(full_data)) {
    message("❌ Could not load data for testing")
    return(invisible(NULL))
  }

  # Test with a small sample to avoid overwhelming output
  test_names <- c("Ayden", "Khaleesi", "Nevaeh", "Jayden", "Brayden")

  message("Testing with sample names: ", paste(test_names, collapse = ", "))

  # Filter to just these test names
  test_data <- full_data$state[name %in% test_names]

  # Run origin detection
  results <- find_enhanced_origins(test_data, min_total_births = 50, min_states = 3)

  # Show results
  show_origin_results(results, n_show = 10)

  invisible(results)
}

# HELPER FUNCTIONS ====
`%r%` <- function(x, n) paste(rep(x, n), collapse = "")