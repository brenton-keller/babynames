# VISUAL EXPLORATION FUNCTIONS
# Timeline plots, comparison charts, and trust-building visualizations

# TIMELINE VISUALIZATION ====

#' Plot historical timeline for a name with classification context
#' @param name Name to plot
#' @param sex Sex to analyze ("M", "F", or "both")
#' @param start_year Starting year for plot
#' @param end_year Ending year for plot
#' @param show_thresholds Show classification threshold lines
plot_timeline <- function(name, sex = "both", start_year = 1880, end_year = 2024, show_thresholds = TRUE) {

  if (is.null(.explorer_env$data)) {
    message("❌ No data loaded. Run start_name_explorer() first.")
    return(invisible(NULL))
  }

  # Load required library for plotting
  if (!requireNamespace("graphics", quietly = TRUE)) {
    message("❌ Graphics package required for plotting")
    return(invisible(NULL))
  }

  name <- stringr::str_to_title(name)

  # Get historical data from the full dataset
  source("R/core/data_cache_manager.R")
  full_data <- load_babynames_cached(include_state = FALSE)

  if (sex == "both") {
    plot_data <- full_data$national[name == name & year >= start_year & year <= end_year]
  } else {
    plot_data <- full_data$national[name == name & sex == sex & year >= start_year & year <= end_year]
  }

  if (nrow(plot_data) == 0) {
    message("❌ No data found for ", name, " in specified years")
    return(invisible(NULL))
  }

  # Calculate proportions
  plot_data[, prop := n / sum(n) * 100, by = .(year, sex)]

  # Get classification info
  class_info <- .explorer_env$classifications$classified_names[name == name]

  # Create the plot
  if (sex == "both" && length(unique(plot_data$sex)) > 1) {
    plot_timeline_both_sexes(plot_data, name, class_info, show_thresholds)
  } else {
    plot_timeline_single_sex(plot_data, name, class_info, show_thresholds)
  }

  invisible(plot_data)
}

#' Plot timeline for both sexes
plot_timeline_both_sexes <- function(plot_data, name, class_info, show_thresholds) {

  # Set up plotting area
  par(mfrow = c(2, 1), mar = c(4, 4, 3, 2))

  for (current_sex in c("M", "F")) {
    sex_data <- plot_data[sex == current_sex]

    if (nrow(sex_data) == 0) next

    # Get classification for this sex
    sex_class <- class_info[sex == current_sex]

    plot_single_timeline(sex_data, name, current_sex, sex_class, show_thresholds)
  }

  # Reset plotting parameters
  par(mfrow = c(1, 1))
}

#' Plot timeline for single sex
plot_timeline_single_sex <- function(plot_data, name, class_info, show_thresholds) {

  current_sex <- unique(plot_data$sex)[1]
  sex_class <- class_info[sex == current_sex]

  plot_single_timeline(plot_data, name, current_sex, sex_class, show_thresholds)
}

#' Core timeline plotting function
plot_single_timeline <- function(sex_data, name, current_sex, sex_class, show_thresholds) {

  # Determine y-axis: use raw counts for better interpretability
  y_values <- sex_data$n
  y_label <- "Annual Births"

  # Create the basic plot
  plot(sex_data$year, y_values,
       type = "l", lwd = 2, col = ifelse(current_sex == "M", "blue", "red"),
       main = paste(name, "(", current_sex, ")", if (nrow(sex_class) > 0) paste("-", sex_class$classification) else ""),
       xlab = "Year", ylab = y_label,
       las = 1)

  # Add points for better visibility
  points(sex_data$year, y_values,
         pch = 16, cex = 0.5, col = ifelse(current_sex == "M", "blue", "red"))

  # Add vertical lines for key periods
  abline(v = 1980, col = "orange", lty = 2, lwd = 2)  # Baseline start
  abline(v = 1990, col = "darkgreen", lty = 2, lwd = 2)  # Modern period start

  # Add period labels
  if (max(sex_data$year) > 1990) {
    text(1985, max(y_values) * 0.9, "Baseline\n(1980-1989)", col = "orange", cex = 0.8)
    text(2000, max(y_values) * 0.9, "Modern\n(1990+)", col = "darkgreen", cex = 0.8)
  }

  # Add classification info
  if (nrow(sex_class) > 0) {
    class_text <- paste0("Classification: ", sex_class$classification,
                        "\nConfidence: ", sex_class$classification_confidence,
                        "\nBaseline: ", format(sex_class$baseline_total_births, big.mark = ","),
                        "\nModern: ", format(sex_class$modern_total_births, big.mark = ","))

    # Add text box with classification info
    legend("topleft", legend = class_text, bty = "n", cex = 0.7, text.col = "black")
  }

  # Add threshold lines if requested
  if (show_thresholds && nrow(sex_class) > 0) {
    add_threshold_indicators(sex_class, sex_data)
  }
}

#' Add threshold indicator lines to plot
add_threshold_indicators <- function(sex_class, sex_data) {

  config <- CLASSIFICATION_CONFIG$thresholds

  # Show relevant thresholds based on classification
  if (sex_class$classification == "ESTABLISHED") {
    # Show baseline period average
    baseline_avg <- sex_class$baseline_avg_annual
    abline(h = baseline_avg, col = "purple", lty = 3)
    text(min(sex_data$year) + 5, baseline_avg * 1.1, paste("Baseline avg:", round(baseline_avg)), col = "purple", cex = 0.7)

  } else if (sex_class$classification == "EMERGING") {
    # Show growth trajectory
    baseline_avg <- sex_class$baseline_avg_annual
    modern_avg <- sex_class$modern_avg_annual

    abline(h = baseline_avg, col = "orange", lty = 3)
    abline(h = modern_avg, col = "green", lty = 3)

    text(min(sex_data$year) + 5, baseline_avg * 1.1, paste("Baseline:", round(baseline_avg)), col = "orange", cex = 0.7)
    text(max(sex_data$year) - 5, modern_avg * 1.1, paste("Modern:", round(modern_avg)), col = "green", cex = 0.7)
  }
}

# COMPARISON VISUALIZATION ====

#' Plot multiple names for comparison
#' @param names Vector of names to compare
#' @param sex Sex to analyze
#' @param start_year Starting year
#' @param end_year Ending year
plot_comparison <- function(names, sex = "M", start_year = 1980, end_year = 2024) {

  if (is.null(.explorer_env$data)) {
    message("❌ No data loaded. Run start_name_explorer() first.")
    return(invisible(NULL))
  }

  names <- stringr::str_to_title(names)

  # Load full historical data
  source("R/core/data_cache_manager.R")
  full_data <- load_babynames_cached(include_state = FALSE)

  # Get data for all names
  plot_data <- full_data$national[name %in% names & sex == sex & year >= start_year & year <= end_year]

  if (nrow(plot_data) == 0) {
    message("❌ No data found for comparison")
    return(invisible(NULL))
  }

  # Calculate proportions for better comparison
  plot_data[, prop := n / sum(n) * 100, by = .(year, sex)]

  # Create comparison plot
  create_comparison_plot(plot_data, names, sex)

  invisible(plot_data)
}

#' Create the actual comparison plot
create_comparison_plot <- function(plot_data, names, sex) {

  # Color palette for multiple names
  colors <- c("blue", "red", "green", "purple", "orange", "brown")

  # Find plot bounds
  x_range <- range(plot_data$year)
  y_range <- range(plot_data$n)

  # Create empty plot
  plot(x_range, y_range, type = "n",
       main = paste("Name Comparison (", sex, ")", sep = ""),
       xlab = "Year", ylab = "Annual Births", las = 1)

  # Plot each name
  for (i in seq_along(names)) {
    name_data <- plot_data[name == names[i]]

    if (nrow(name_data) > 0) {
      lines(name_data$year, name_data$n,
            col = colors[i], lwd = 2, type = "l")

      points(name_data$year, name_data$n,
             col = colors[i], pch = 16, cex = 0.4)
    }
  }

  # Add vertical reference lines
  abline(v = 1980, col = "gray", lty = 2)
  abline(v = 1990, col = "gray", lty = 2)

  # Add legend
  legend("topright", legend = names, col = colors[1:length(names)], lwd = 2, cex = 0.8)

  # Add period labels
  text(1985, max(y_range) * 0.9, "Baseline", col = "gray", cex = 0.8)
  text(2000, max(y_range) * 0.9, "Modern", col = "gray", cex = 0.8)
}

# CLASSIFICATION VISUALIZATION ====

#' Visualize why a name got its classification
#' @param name Name to analyze
#' @param sex Sex to check
plot_classification_logic <- function(name, sex = "M") {

  if (is.null(.explorer_env$data)) {
    message("❌ No data loaded. Run start_name_explorer() first.")
    return(invisible(NULL))
  }

  name <- stringr::str_to_title(name)

  # Get classification data
  class_data <- .explorer_env$classifications$classified_names[name == name & sex == sex]

  if (nrow(class_data) == 0) {
    message("❌ Name not found")
    return(invisible(NULL))
  }

  # Load full historical data for the complete timeline
  source("R/core/data_cache_manager.R")
  full_data <- load_babynames_cached(include_state = FALSE)
  historical_data <- full_data$national[name == name & sex == sex]

  # Create classification logic plot
  create_classification_plot(historical_data, class_data[1], name, sex)

  invisible(list(historical = historical_data, classification = class_data))
}

#' Create classification logic visualization
create_classification_plot <- function(historical_data, class_info, name, sex) {

  # Set up two-panel plot
  par(mfrow = c(2, 1), mar = c(4, 4, 3, 2))

  # Panel 1: Full historical timeline with periods highlighted
  plot(historical_data$year, historical_data$n,
       type = "l", lwd = 2, col = "black",
       main = paste(name, "(", sex, ") - Full Historical View"),
       xlab = "Year", ylab = "Annual Births", las = 1)

  points(historical_data$year, historical_data$n, pch = 16, cex = 0.5)

  # Highlight baseline period
  baseline_data <- historical_data[year >= 1980 & year <= 1989]
  if (nrow(baseline_data) > 0) {
    lines(baseline_data$year, baseline_data$n, col = "orange", lwd = 4)
    points(baseline_data$year, baseline_data$n, col = "orange", pch = 16, cex = 0.8)
  }

  # Highlight modern period
  modern_data <- historical_data[year >= 1990]
  if (nrow(modern_data) > 0) {
    lines(modern_data$year, modern_data$n, col = "green", lwd = 3)
    points(modern_data$year, modern_data$n, col = "green", pch = 16, cex = 0.6)
  }

  # Add period dividers
  abline(v = 1980, col = "orange", lty = 2, lwd = 2)
  abline(v = 1990, col = "green", lty = 2, lwd = 2)

  # Panel 2: Classification decision visualization
  create_decision_plot(class_info, name, sex)

  # Reset plotting parameters
  par(mfrow = c(1, 1))
}

#' Create classification decision visualization
create_decision_plot <- function(class_info, name, sex) {

  # Create bar plot showing the key metrics
  metrics <- c("Baseline Total", "Modern Total", "Growth Ratio")
  values <- c(class_info$baseline_total_births,
             class_info$modern_total_births,
             min(class_info$growth_ratio, 1000))  # Cap for visualization

  # Use log scale for better visualization
  log_values <- log10(pmax(values, 1))

  barplot(log_values, names.arg = metrics,
          main = paste("Classification Metrics (Log Scale) -", class_info$classification),
          ylab = "Log10(Count/Ratio)", las = 2, col = c("orange", "green", "blue"))

  # Add text labels with actual values
  text(0.7, log_values[1] + 0.1, format(values[1], big.mark = ","), cex = 0.8)
  text(1.9, log_values[2] + 0.1, format(values[2], big.mark = ","), cex = 0.8)
  text(3.1, log_values[3] + 0.1, paste0(round(class_info$growth_ratio, 1), "x"), cex = 0.8)

  # Add threshold lines
  config <- CLASSIFICATION_CONFIG$thresholds

  # Add reference lines for thresholds
  abline(h = log10(config$established_min_births), col = "red", lty = 2)
  text(0.5, log10(config$established_min_births) + 0.1, "Est. threshold", col = "red", cex = 0.7)
}

# UTILITY FUNCTIONS ====

#' Quick visual summary of a name
#' @param name Name to summarize
#' @param sex Sex to analyze
visual_summary <- function(name, sex = "M") {

  message("📊 Creating visual summary for ", name, " (", sex, ")...")

  # Create a comprehensive visual summary
  par(mfrow = c(2, 2), mar = c(4, 4, 2, 2))

  # 1. Timeline plot
  plot_timeline(name, sex, show_thresholds = FALSE)

  # 2. Classification logic
  plot_classification_logic(name, sex)

  # Reset
  par(mfrow = c(1, 1))

  message("✅ Visual summary complete!")
}