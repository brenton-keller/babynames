# ORIGIN AND DIFFUSION VISUALIZATION
# Visual exploration of name origins and geographic spread

# LOAD REQUIRED FUNCTIONS ====

#' Ensure required functions are loaded
setup_visualization <- function() {
  if (!exists("load_babynames_cached")) {
    source("R/core/data_cache_manager.R")
  }
  if (!exists("find_enhanced_origins")) {
    source("R/analysis/enhanced_origin_detection.R")
  }
}

# GEOGRAPHIC SPREAD VISUALIZATION ====

#' Create timeline showing name spread across states
#' @param name_to_plot Name to visualize
#' @param sex_to_plot Sex to analyze
#' @param years_to_plot Year range to show
#' @param min_births Minimum births to show a state
visualize_name_spread <- function(name_to_plot, sex_to_plot = "F",
                                 years_to_plot = NULL, min_births = 5) {

  setup_visualization()

  name_to_plot <- stringr::str_to_title(name_to_plot)

  message("📊 Visualizing geographic spread: ", name_to_plot, " (", sex_to_plot, ")")

  # Load state data
  full_data <- load_babynames_cached(include_state = TRUE)
  if (is.null(full_data)) {
    message("❌ Could not load data")
    return(invisible(NULL))
  }

  # Filter to target name
  name_data <- full_data$state[name == name_to_plot & sex == sex_to_plot]

  if (nrow(name_data) == 0) {
    message("❌ No data found for ", name_to_plot, " (", sex_to_plot, ")")
    return(invisible(NULL))
  }

  # Determine year range
  if (is.null(years_to_plot)) {
    first_year <- min(name_data$year)
    last_year <- max(name_data$year)
    years_to_plot <- first_year:last_year
  }

  # Filter by years and minimum births
  plot_data <- name_data[year %in% years_to_plot & n >= min_births]

  if (nrow(plot_data) == 0) {
    message("❌ No data meeting criteria (min births: ", min_births, ")")
    return(invisible(NULL))
  }

  message("📈 Showing ", nrow(plot_data), " state-year combinations")

  # Get origin information
  origin_result <- investigate_origin(name_to_plot, sex_to_plot)
  origin_state <- if (!is.null(origin_result) && nrow(origin_result) > 0) {
    origin_result[sex == sex_to_plot]$origin_state[1]
  } else {
    NA
  }

  # Create spread timeline plot
  create_spread_timeline(plot_data, name_to_plot, origin_state)

  # Create state adoption map
  create_adoption_sequence(plot_data, name_to_plot, origin_state)

  invisible(plot_data)
}

#' Create timeline showing adoption by state
create_spread_timeline <- function(plot_data, name_title, origin_state = NULL) {

  # Find first appearance in each state
  first_appearances <- plot_data[, .SD[which.min(year)], by = state]
  setorder(first_appearances, year, -n)

  # Create color scheme - highlight origin state
  colors <- rainbow(nrow(first_appearances), alpha = 0.7)
  if (!is.na(origin_state)) {
    origin_idx <- which(first_appearances$state == origin_state)
    if (length(origin_idx) > 0) {
      colors[origin_idx] <- "red"  # Highlight origin in red
    }
  }

  # Create timeline plot
  plot(first_appearances$year, first_appearances$n,
       type = "n",  # Don't plot points yet
       main = paste("Geographic Emergence:", name_title),
       xlab = "Year of First Appearance",
       ylab = "Initial Births in State",
       las = 1)

  # Add points with state labels
  points(first_appearances$year, first_appearances$n,
         col = colors, pch = 16, cex = 1.2)

  # Add state labels for larger points
  significant <- first_appearances[n >= quantile(first_appearances$n, 0.7)]
  text(significant$year, significant$n, significant$state,
       pos = 3, cex = 0.7, col = "black")

  # Highlight origin state if known
  if (!is.na(origin_state)) {
    origin_point <- first_appearances[state == origin_state]
    if (nrow(origin_point) > 0) {
      points(origin_point$year, origin_point$n,
             col = "red", pch = 16, cex = 2)
      text(origin_point$year, origin_point$n,
           paste("ORIGIN:", origin_state),
           pos = 1, col = "red", cex = 0.8, font = 2)
    }
  }

  # Add trend line
  if (nrow(first_appearances) > 2) {
    trend_line <- loess(n ~ year, data = first_appearances, span = 0.7)
    years_smooth <- seq(min(first_appearances$year), max(first_appearances$year), by = 1)
    trend_values <- predict(trend_line, years_smooth)
    lines(years_smooth, trend_values, col = "blue", lwd = 2, lty = 2)
  }

  grid(col = "gray", lty = 3)
}

#' Show adoption sequence by state
create_adoption_sequence <- function(plot_data, name_title, origin_state = NULL) {

  # Find adoption order
  first_appearances <- plot_data[, .(first_year = min(year),
                                    first_births = .SD[which.min(year)]$n),
                                by = state]
  setorder(first_appearances, first_year, -first_births)

  message("\n🗺️  ADOPTION SEQUENCE for ", name_title)
  message("=" %r% 50)

  cat(sprintf("%-4s %-8s %-4s %-8s %s\n",
              "Rank", "State", "Year", "Births", "Notes"))
  message("-" %r% 50)

  for (i in 1:min(nrow(first_appearances), 15)) {  # Show top 15
    state_info <- first_appearances[i]

    notes <- ""
    if (!is.na(origin_state) && state_info$state == origin_state) {
      notes <- "← ORIGIN"
    } else if (i <= 5) {
      notes <- "Early adopter"
    }

    cat(sprintf("%-4d %-8s %-4d %-8d %s\n",
                i,
                state_info$state,
                state_info$first_year,
                state_info$first_births,
                notes))
  }

  if (nrow(first_appearances) > 15) {
    message("... and ", nrow(first_appearances) - 15, " more states")
  }

  invisible(first_appearances)
}

# COMPARATIVE VISUALIZATION ====

#' Compare spread patterns of multiple names (FIXED VERSION)
#' @param names_to_compare Vector of names to compare
#' @param sex_filter Sex to analyze
compare_spread_patterns <- function(names_to_compare, sex_filter = "F") {

  # Don't run setup_visualization to avoid loading issues
  if (!exists("load_babynames_cached")) {
    source("R/core/data_cache_manager.R")
  }

  message("🔄 Comparing spread patterns: ", paste(names_to_compare, collapse = ", "))

  # Load data once
  full_data <- load_babynames_cached(include_state = TRUE)
  if (is.null(full_data)) {
    message("❌ Could not load data")
    return(invisible(NULL))
  }

  # Prepare comparison data more efficiently
  comparison_data <- data.table()

  # Process each name separately to avoid memory issues
  for (i in seq_along(names_to_compare)) {
    name <- stringr::str_to_title(names_to_compare[i])

    # Filter data for this specific name
    name_data <- full_data$state[name == name & sex == sex_filter]

    if (nrow(name_data) > 0) {
      message("  Processing ", name, ": ", nrow(name_data), " records")

      # Find first appearance in each state - more robust approach
      first_apps <- name_data[, {
        min_year_idx <- which.min(year)
        .(first_year = year[min_year_idx],
          first_births = n[min_year_idx],
          name = name)
      }, by = state]

      # Add to comparison data
      comparison_data <- rbind(comparison_data, first_apps)
    } else {
      message("  ⚠️ No data found for ", name, " (", sex_filter, ")")
    }
  }

  if (nrow(comparison_data) == 0) {
    message("❌ No data found for comparison")
    return(invisible(NULL))
  }

  message("✅ Creating comparison plot with ", nrow(comparison_data), " data points")

  # Create safe plotting ranges
  x_range <- range(comparison_data$first_year, na.rm = TRUE)
  y_range <- range(comparison_data$first_births, na.rm = TRUE)

  if (any(is.infinite(c(x_range, y_range)))) {
    message("❌ Invalid data ranges for plotting")
    return(invisible(comparison_data))
  }

  # Create comparison plot
  plot(x_range, y_range, type = "n",
       main = "Name Spread Comparison",
       xlab = "Year of First State Appearance",
       ylab = "Initial Births",
       las = 1)

  # Plot each name with different colors
  colors <- rainbow(length(names_to_compare))

  for (i in seq_along(names_to_compare)) {
    name <- stringr::str_to_title(names_to_compare[i])
    name_subset <- comparison_data[name == name]

    if (nrow(name_subset) > 0) {
      points(name_subset$first_year, name_subset$first_births,
             col = colors[i], pch = 16, cex = 0.8)
    }
  }

  # Add legend
  legend("topright", legend = names_to_compare,
         col = colors, pch = 16, cex = 0.8)

  grid(col = "gray", lty = 3)

  message("✅ Plot created successfully")

  invisible(comparison_data)
}

# REGIONAL ANALYSIS VISUALIZATION ====

#' Show regional adoption patterns
#' @param name_to_analyze Name to analyze
#' @param sex_filter Sex to analyze
show_regional_patterns <- function(name_to_analyze, sex_filter = "F") {

  setup_visualization()

  name_to_analyze <- stringr::str_to_title(name_to_analyze)

  message("🗺️  REGIONAL ANALYSIS: ", name_to_analyze, " (", sex_filter, ")")

  # Load data
  full_data <- load_babynames_cached(include_state = TRUE)
  if (is.null(full_data)) return(invisible(NULL))

  name_data <- full_data$state[name == name_to_analyze & sex == sex_filter]

  if (nrow(name_data) == 0) {
    message("❌ No data found")
    return(invisible(NULL))
  }

  # Add regional information (simplified mapping)
  US_REGIONS <- list(
    Northeast = c("CT", "ME", "MA", "NH", "NJ", "NY", "PA", "RI", "VT"),
    Midwest = c("IL", "IN", "IA", "KS", "MI", "MN", "MO", "NE", "ND", "OH", "SD", "WI"),
    South = c("AL", "AR", "DE", "FL", "GA", "KY", "LA", "MD", "MS", "NC", "OK", "SC", "TN", "TX", "VA", "WV"),
    West = c("AK", "AZ", "CA", "CO", "HI", "ID", "MT", "NV", "NM", "OR", "UT", "WA", "WY")
  )

  # Create region lookup
  region_lookup <- rbindlist(lapply(names(US_REGIONS), function(region) {
    data.table(state = US_REGIONS[[region]], region = region)
  }))

  # Add regions to data
  name_data_with_region <- region_lookup[name_data, on = "state", nomatch = 0]

  # Regional first appearances
  regional_firsts <- name_data_with_region[, .(
    first_year = min(year),
    total_early_births = sum(.SD[year <= (min(year) + 2)]$n),
    n_states_early = uniqueN(.SD[year <= (min(year) + 2)]$state)
  ), by = region]

  setorder(regional_firsts, first_year)

  message("\n📊 Regional Emergence Pattern:")
  message("-" %r% 40)

  cat(sprintf("%-12s %-6s %-8s %-8s\n",
              "Region", "Year", "Births", "States"))
  message("-" %r% 40)

  for (i in 1:nrow(regional_firsts)) {
    d <- regional_firsts[i]
    cat(sprintf("%-12s %-6d %-8d %-8d\n",
                d$region, d$first_year, d$total_early_births, d$n_states_early))
  }

  invisible(name_data_with_region)
}

# CONVENIENCE FUNCTIONS ====

#' Quick origin and spread analysis for a name
quick_origin_analysis <- function(name_input, sex_input = "F") {

  message("🚀 QUICK ORIGIN & SPREAD ANALYSIS")
  message("=" %r% 50)

  # Step 1: Find origin
  investigate_origin(name_input, sex_input)

  # Step 2: Show spread visualization
  visualize_name_spread(name_input, sex_input, min_births = 3)

  # Step 3: Regional patterns
  show_regional_patterns(name_input, sex_input)
}

# HELPER FUNCTIONS ====
`%r%` <- function(x, n) paste(rep(x, n), collapse = "")