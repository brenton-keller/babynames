# SIMPLE ORIGIN ANALYSIS - NO PROBLEMATIC VISUALIZATIONS
# Focused on reliable origin detection without hanging visualizations

#' Simple origin analysis without complex visualizations
#' @param name Name to analyze
#' @param sex Sex to analyze ("M", "F", or "both")
analyze_name_origin_simple <- function(name, sex = "F") {

  message("🎯 SIMPLE ORIGIN ANALYSIS: ", stringr::str_to_title(name), " (", sex, ")")
  message("=" %r% 50)

  # Load functions
  source("R/analysis/enhanced_origin_detection.R")
  source("R/interface/quick_analysis.R")

  # Step 1: Show classification
  message("📊 Classification Status:")
  investigate_name(name, sex = sex, show_plot = FALSE)

  # Step 2: Find origin (improved algorithm)
  message("\n🔍 Origin Detection:")
  message("-" %r% 20)

  # Check if this is an established name that shouldn't be analyzed for origin
  source("R/interface/quick_analysis.R")
  class_check <- investigate_name(name, sex, show_plot = FALSE)

  if (!is.null(class_check)) {
    target_class <- class_check[sex == sex]$classification[1]
    if (target_class == "ESTABLISHED") {
      message("⚠️  ", stringr::str_to_title(name), " is classified as ESTABLISHED")
      message("   Traditional names are not suitable for geographic origin analysis")
      message("   This name has historical origins predating our data (1910+)")
      message("   For cultural analysis, focus on TRULY_NEW or EMERGING names")
      return(invisible(NULL))
    }
  }

  origin_result <- investigate_origin(name, sex)

  if (!is.null(origin_result) && nrow(origin_result) > 0) {
    # Show additional details
    result <- origin_result[1]  # First result

    message("\n📈 Origin Details:")
    message("   🏛️ Most likely origin: ", result$origin_state, " in ", result$origin_year)
    message("   📊 Confidence: ", round(result$confidence_score * 100, 1), "%")
    message("   🎯 Early births: ", format(result$total_early_births, big.mark = ","))

    # Interpretation
    if (result$confidence_score >= 0.7) {
      message("   ✅ High confidence result")
    } else if (result$confidence_score >= 0.5) {
      message("   ⚡ Moderate confidence result")
    } else {
      message("   ⚠️ Low confidence - multiple possible origins")
    }

    # Show adoption timeline (text only)
    show_simple_adoption_timeline(name, sex)
  } else {
    message("❌ Could not determine origin")
  }

  invisible(origin_result)
}

#' Show simple adoption timeline without plots
show_simple_adoption_timeline <- function(name, sex) {

  message("\n🗺️ State Adoption Timeline:")

  # Load state data
  source("R/core/data_cache_manager.R")
  full_data <- load_babynames_cached(include_state = TRUE)

  if (is.null(full_data)) {
    message("❌ Could not load data")
    return(invisible(NULL))
  }

  name <- stringr::str_to_title(name)
  name_data <- full_data$state[name == name & sex == sex]

  if (nrow(name_data) == 0) {
    message("❌ No state data found")
    return(invisible(NULL))
  }

  # Find first appearance in each state
  first_apps <- name_data[, .(
    first_year = min(year),
    first_births = .SD[which.min(year)]$n
  ), by = state]

  setorder(first_apps, first_year, -first_births)

  # Show first 10 states
  message("-" %r% 35)
  cat(sprintf("%-4s %-8s %-6s %-8s\n", "Rank", "State", "Year", "Births"))
  message("-" %r% 35)

  for (i in 1:min(nrow(first_apps), 10)) {
    state_info <- first_apps[i]
    cat(sprintf("%-4d %-8s %-6d %-8d\n",
                i, state_info$state, state_info$first_year, state_info$first_births))
  }

  if (nrow(first_apps) > 10) {
    message("... and ", nrow(first_apps) - 10, " more states")
  }

  # Regional summary
  show_regional_summary(first_apps)

  invisible(first_apps)
}

#' Show regional emergence summary
show_regional_summary <- function(first_apps) {

  # Regional mapping
  US_REGIONS <- list(
    West = c("AK", "AZ", "CA", "CO", "HI", "ID", "MT", "NV", "NM", "OR", "UT", "WA", "WY"),
    South = c("AL", "AR", "DE", "FL", "GA", "KY", "LA", "MD", "MS", "NC", "OK", "SC", "TN", "TX", "VA", "WV"),
    Midwest = c("IL", "IN", "IA", "KS", "MI", "MN", "MO", "NE", "ND", "OH", "SD", "WI"),
    Northeast = c("CT", "ME", "MA", "NH", "NJ", "NY", "PA", "RI", "VT")
  )

  # Add regions safely
  first_apps[, region := NA_character_]

  # Use explicit region assignment to avoid indexing errors
  first_apps[state %in% US_REGIONS$West, region := "West"]
  first_apps[state %in% US_REGIONS$South, region := "South"]
  first_apps[state %in% US_REGIONS$Midwest, region := "Midwest"]
  first_apps[state %in% US_REGIONS$Northeast, region := "Northeast"]

  # Regional first appearances
  regional_first <- first_apps[!is.na(region), .(
    first_year = min(first_year),
    n_states = .N
  ), by = region]

  setorder(regional_first, first_year)

  message("\n🌎 Regional Emergence:")
  message("-" %r% 25)
  cat(sprintf("%-12s %-6s %-8s\n", "Region", "Year", "States"))
  message("-" %r% 25)

  for (i in 1:nrow(regional_first)) {
    d <- regional_first[i]
    cat(sprintf("%-12s %-6d %-8d\n", d$region, d$first_year, d$n_states))
  }
}

#' Compare origins of multiple names (simple version)
compare_origins_simple <- function(..., sex = "F") {

  names_list <- unlist(list(...))

  message("🔄 COMPARING ORIGINS: ", paste(names_list, collapse = ", "))
  message("=" %r% 50)

  comparison_table <- data.table()

  for (name in names_list) {
    message("\n--- ", stringr::str_to_title(name), " ---")
    result <- analyze_name_origin_simple(name, sex)

    if (!is.null(result) && nrow(result) > 0) {
      r <- result[1]
      comparison_table <- rbind(comparison_table, data.table(
        name = r$name,
        origin_state = r$origin_state,
        origin_year = r$origin_year,
        confidence = round(r$confidence_score * 100, 1),
        early_births = r$total_early_births
      ))
    }
  }

  if (nrow(comparison_table) > 0) {
    message("\n📊 COMPARISON SUMMARY")
    message("=" %r% 40)
    cat(sprintf("%-12s %-8s %-6s %-6s %-8s\n",
                "Name", "Origin", "Year", "Conf%", "Births"))
    message("-" %r% 40)

    for (i in 1:nrow(comparison_table)) {
      d <- comparison_table[i]
      cat(sprintf("%-12s %-8s %-6d %-6.1f %-8d\n",
                  d$name, d$origin_state, d$origin_year, d$confidence, d$early_births))
    }
  }

  invisible(comparison_table)
}

#' Quick batch analysis of interesting names
quick_batch_analysis <- function() {

  message("🚀 QUICK BATCH ORIGIN ANALYSIS")
  message("=" %r% 40)

  # Test names from different categories
  test_names <- list(
    got_names = c("Khaleesi", "Daenerys"),
    aiden_variants = c("Aiden", "Ayden", "Jayden", "Brayden"),
    modern_invented = c("Nevaeh", "Jaelyn")
  )

  for (category in names(test_names)) {
    message("\n🔍 ", toupper(category), ":")
    message("-" %r% 30)

    for (name in test_names[[category]]) {
      sex_to_use <- if (category == "aiden_variants") "M" else "F"
      result <- analyze_name_origin_simple(name, sex_to_use)
      message("")  # Space between names
    }
  }

  message("✅ Batch analysis complete!")
}

# Helper function
`%r%` <- function(x, n) paste(rep(x, n), collapse = "")