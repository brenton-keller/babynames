# QUICK ANALYSIS FUNCTIONS
# Immediate investigation tools without full interactive setup

# QUICK SETUP ====

#' Quick setup for immediate name analysis
#' @param reload_data Force reload of classification data
#' @return TRUE if successful, FALSE otherwise
quick_setup <- function(reload_data = FALSE) {

  message("⚡ Quick Analysis Setup")
  message("======================")

  # Load required functions
  if (!exists("CLASSIFICATION_CONFIG")) {
    source("R/analysis/name_classifier.R")
  }

  # Load cached data if not already loaded
  class_file <- "data/processed/name_classifications.rds"

  if (file.exists(class_file) && !reload_data) {
    data <- readRDS(class_file)
    message("✅ Loaded cached classification data")
    return(data)
  } else {
    message("❌ No cached data found. Run:")
    message("    source('tests/test_name_classification.R')")
    message("    to generate classification data first.")
    return(NULL)
  }
}

# CORE QUICK FUNCTIONS ====

#' Quick investigation of a single name
#' @param name Name to investigate
#' @param sex Sex to analyze ("M", "F", or "both")
#' @param show_plot Whether to create a plot
investigate_name <- function(name, sex = "both", show_plot = TRUE) {

  # Quick setup
  data <- quick_setup()
  if (is.null(data)) return(invisible(NULL))

  name <- stringr::str_to_title(name)

  message("\n🔍 QUICK INVESTIGATION: ", name)
  message(paste(rep("=", 40), collapse = ""))

  # Get classification info - EXACT MATCH ONLY to avoid spam
  # Fix variable name conflict: use explicit column referencing
  search_name <- name
  if (sex == "both") {
    classifications <- data$classified_names[data$classified_names$name == search_name]
  } else {
    classifications <- data$classified_names[data$classified_names$name == search_name & data$classified_names$sex == sex]
  }

  if (nrow(classifications) == 0) {
    message("❌ Name '", name, "' not found in dataset")
    suggest_similar_spellings(name, data, sex)
    return(invisible(NULL))
  }

  # Show summary for each sex found (but limit output)
  if (nrow(classifications) <= 3) {
    # If 3 or fewer results, show all
    for (i in 1:nrow(classifications)) {
      show_quick_summary(classifications[i])
    }
  } else {
    # If many results, show just the first 3 and summarize
    message("Found ", nrow(classifications), " variants. Showing top 3:")
    for (i in 1:3) {
      show_quick_summary(classifications[i])
    }
    remaining <- nrow(classifications) - 3
    message("... and ", remaining, " more variants (", paste(classifications[4:min(nrow(classifications), 8), name], collapse = ", "),
           if(nrow(classifications) > 8) ", ..." else "", ")")
  }

  if (show_plot) {
    quick_plot_name(name, sex)
  }

  invisible(classifications)
}

#' Show quick summary for a name (ROBUST VERSION)
show_quick_summary <- function(name_data) {

  if (nrow(name_data) == 0) {
    message("❌ No data to display")
    return(invisible(NULL))
  }

  d <- name_data[1,]  # Get first row more safely

  # Check for NULL values and provide defaults
  name_val <- if (is.null(d$name)) "UNKNOWN" else d$name
  sex_val <- if (is.null(d$sex)) "UNKNOWN" else d$sex
  class_val <- if (is.null(d$classification)) "UNKNOWN" else d$classification
  conf_val <- if (is.null(d$classification_confidence)) "UNKNOWN" else d$classification_confidence

  cat("\n📊", name_val, "(", sex_val, ") →", class_val, "\n")
  cat("🔒 Confidence:", conf_val, "\n")

  # Key stats with NULL checking
  baseline_births <- if (is.null(d$baseline_total_births)) 0 else d$baseline_total_births
  modern_births <- if (is.null(d$modern_total_births)) 0 else d$modern_total_births
  growth_val <- if (is.null(d$growth_ratio)) NA else d$growth_ratio

  cat("📈 1980s:", format(baseline_births, big.mark = ","), "births")
  cat(" | 1990s+:", format(modern_births, big.mark = ","), "births")

  if (!is.null(growth_val) && is.finite(growth_val) && growth_val != Inf) {
    cat(" | Growth:", round(growth_val, 1), "x")
  }
  cat("\n")

  # Eligible for origin analysis?
  eligible <- class_val %in% c("TRULY_NEW", "EMERGING")
  cat("🎯 Origin Analysis:", ifelse(eligible, "✅ Eligible", "❌ Not suitable"), "\n")
}

#' Quick plot for a name
quick_plot_name <- function(name, sex = "both", years = 1970:2024) {

  # Load full data for plotting
  source("R/core/data_cache_manager.R")
  full_data <- load_babynames_cached(include_state = FALSE)

  name <- stringr::str_to_title(name)

  if (sex == "both") {
    plot_data <- full_data$national[name == name & year %in% years]
  } else {
    plot_data <- full_data$national[name == name & sex == sex & year %in% years]
  }

  if (nrow(plot_data) == 0) {
    message("❌ No plot data available")
    return(invisible(NULL))
  }

  # Simple plot
  if (length(unique(plot_data$sex)) > 1) {
    # Both sexes
    create_quick_dual_plot(plot_data, name)
  } else {
    # Single sex
    create_quick_single_plot(plot_data, name)
  }

  invisible(plot_data)
}

#' Create quick plot for single sex
create_quick_single_plot <- function(plot_data, name) {

  current_sex <- unique(plot_data$sex)[1]
  sex_color <- ifelse(current_sex == "M", "blue", "red")

  plot(plot_data$year, plot_data$n,
       type = "l", lwd = 2, col = sex_color,
       main = paste(name, "(", current_sex, ")"),
       xlab = "Year", ylab = "Annual Births", las = 1)

  points(plot_data$year, plot_data$n, pch = 16, cex = 0.5, col = sex_color)

  # Add reference lines
  abline(v = 1980, col = "gray", lty = 2)
  abline(v = 1990, col = "gray", lty = 2)

  # Add period labels
  if (max(plot_data$year) > 1990) {
    text(1985, max(plot_data$n) * 0.1, "Baseline", col = "gray", cex = 0.8)
    text(2005, max(plot_data$n) * 0.1, "Modern", col = "gray", cex = 0.8)
  }
}

#' Create quick plot for both sexes
create_quick_dual_plot <- function(plot_data, name) {

  par(mfrow = c(2, 1), mar = c(3, 4, 2, 2))

  for (current_sex in c("M", "F")) {
    sex_data <- plot_data[sex == current_sex]
    if (nrow(sex_data) == 0) next

    sex_color <- ifelse(current_sex == "M", "blue", "red")

    plot(sex_data$year, sex_data$n,
         type = "l", lwd = 2, col = sex_color,
         main = paste(name, "(", current_sex, ")"),
         xlab = if (current_sex == "F") "Year" else "",
         ylab = "Births", las = 1)

    points(sex_data$year, sex_data$n, pch = 16, cex = 0.4, col = sex_color)

    # Reference lines
    abline(v = 1980, col = "gray", lty = 2)
    abline(v = 1990, col = "gray", lty = 2)
  }

  par(mfrow = c(1, 1))
}

# BATCH ANALYSIS FUNCTIONS ====

#' Quick comparison of multiple names
#' @param ... Names to compare (can be passed as separate arguments or vector)
#' @param sex Sex to analyze
quick_compare <- function(..., sex = "F") {

  # Handle flexible input: both quick_compare("A", "B") and quick_compare(c("A", "B"))
  args <- list(...)

  if (length(args) == 1 && length(args[[1]]) > 1) {
    # Called as quick_compare(c("Name1", "Name2"))
    names <- args[[1]]
  } else {
    # Called as quick_compare("Name1", "Name2")
    names <- unlist(args)
  }

  data <- quick_setup()
  if (is.null(data)) return(invisible(NULL))

  names <- stringr::str_to_title(names)

  message("\n🔬 QUICK COMPARISON")
  message("===================")

  # Get comparison data - EXACT MATCHES ONLY
  comparison_data <- data.table()

  for (search_name in names) {
    # Ensure exact string matching with proper title case
    search_name <- stringr::str_to_title(search_name)
    name_info <- data$classified_names[data$classified_names$name == search_name & data$classified_names$sex == sex]

    if (nrow(name_info) > 0) {
      comparison_data <- rbind(comparison_data, name_info)
    } else {
      message("⚠️ ", search_name, " not found (exact match required)")
      # Suggest alternatives
      suggest_similar_spellings(search_name, data, sex)
    }
  }

  if (nrow(comparison_data) == 0) {
    message("❌ No names found for comparison")
    return(invisible(NULL))
  }

  # Show comparison
  show_quick_comparison(comparison_data)

  invisible(comparison_data)
}

#' Show quick comparison table (SMART LIMITING)
show_quick_comparison <- function(comp_data) {

  # NEVER show more than 10 rows to prevent spam
  if (nrow(comp_data) > 10) {
    message("⚠️ Found ", nrow(comp_data), " results - showing first 10 only")
    comp_data <- head(comp_data, 10)
    show_truncated <- TRUE
  } else {
    show_truncated <- FALSE
  }

  message("\n", paste(rep("-", 60), collapse = ""))
  cat(sprintf("%-12s %-12s %-10s %-10s %-8s\n",
              "Name", "Class", "Baseline", "Modern", "Growth"))
  message(paste(rep("-", 60), collapse = ""))

  for (i in 1:nrow(comp_data)) {
    d <- comp_data[i]
    growth_str <- if (is.finite(d$growth_ratio) && d$growth_ratio != Inf) {
      paste0(round(d$growth_ratio, 1), "x")
    } else {
      "NEW"
    }

    cat(sprintf("%-12s %-12s %-10s %-10s %-8s\n",
                d$name,
                d$classification,
                format(d$baseline_total_births, big.mark = ","),
                format(d$modern_total_births, big.mark = ","),
                growth_str))
  }

  if (show_truncated) {
    message("... (showing only first 10 results)")
    message("💡 Use more specific search terms to narrow results")
  }

  message("")
}

# DISCOVERY FUNCTIONS ====

#' Get random example of a classification type
#' @param classification Classification type to sample from
#' @param sex Sex to filter by
#' @param n Number of examples to show
random_examples <- function(classification = "EMERGING", sex = "M", n = 5) {

  data <- quick_setup()
  if (is.null(data)) return(invisible(NULL))

  examples <- data$classified_names[data$classified_names$classification == classification & data$classified_names$sex == sex]

  if (nrow(examples) == 0) {
    message("❌ No examples found for ", classification, " (", sex, ")")
    return(invisible(NULL))
  }

  # Sample random examples
  sample_size <- min(n, nrow(examples))
  sampled <- examples[sample(.N, sample_size)]

  message("🎲 Random ", classification, " names (", sex, "):")
  for (i in 1:nrow(sampled)) {
    d <- sampled[i]
    growth <- if (is.finite(d$growth_ratio)) paste0(round(d$growth_ratio, 1), "x") else "NEW"
    message("  ", d$name, " (", format(d$baseline_total_births, big.mark = ","), " → ",
           format(d$modern_total_births, big.mark = ","), ", ", growth, ")")
  }

  invisible(sampled)
}

#' Show classification distribution
show_stats <- function(sex = "both") {

  data <- quick_setup()
  if (is.null(data)) return(invisible(NULL))

  message("📊 CLASSIFICATION STATISTICS")
  message("============================")

  if (sex == "both") {
    stats <- data$classified_names[, .N, by = .(classification, sex)][order(sex, -N)]
  } else {
    stats <- data$classified_names[sex == sex, .N, by = classification][order(-N)]
  }

  message("Classification breakdown:")

  # Limit to prevent spam - only show essential categories
  essential_stats <- stats[N > 100]  # Only show categories with substantial counts

  if (nrow(essential_stats) == 0) {
    essential_stats <- head(stats, 5)  # Fallback to top 5
  }

  for (i in 1:nrow(essential_stats)) {
    if ("sex" %in% names(essential_stats)) {
      message("  ", essential_stats[i, sex], " - ", essential_stats[i, classification], ": ", format(essential_stats[i, N], big.mark = ","))
    } else {
      message("  ", essential_stats[i, classification], ": ", format(essential_stats[i, N], big.mark = ","))
    }
  }

  if (nrow(stats) > nrow(essential_stats)) {
    message("  ... (", nrow(stats) - nrow(essential_stats), " smaller categories not shown)")
  }

  invisible(stats)
}

# VALIDATION FUNCTIONS ====

#' Quick validation of classification for known names
quick_validate <- function() {

  data <- quick_setup()
  if (is.null(data)) return(invisible(NULL))

  message("🔍 QUICK VALIDATION CHECK")
  message("=========================")

  # Test known cases
  test_cases <- list(
    list("Michael", "M", "ESTABLISHED", "Popular before 1990"),
    list("Ashley", "F", "ESTABLISHED", "Popular before 1990"),
    list("Nevaeh", "F", "TRULY_NEW", "Heaven backwards, emerged ~2000"),
    list("Aiden", "M", "EMERGING", "Rare before 1990, popular after"),
    list("Jayden", "M", "EMERGING", "Rare before 1990, popular after")
  )

  for (test_case in test_cases) {
    search_name <- test_case[[1]]
    search_sex <- test_case[[2]]
    expected <- test_case[[3]]
    reason <- test_case[[4]]

    actual_results <- data$classified_names[data$classified_names$name == search_name & data$classified_names$sex == search_sex, classification]

    if (length(actual_results) == 0) {
      status <- "❓ NOT_FOUND"
    } else if (length(actual_results) > 1) {
      # Multiple results - take the first one and warn
      actual <- actual_results[1]
      status <- paste0("⚠️ MULTIPLE (", length(actual_results), ") - first is ",
                      ifelse(actual == expected, "CORRECT", paste0("WRONG (", actual, ")")))
    } else {
      # Single result
      actual <- actual_results[1]
      if (actual == expected) {
        status <- "✅ CORRECT"
      } else {
        status <- paste0("❌ WRONG (got ", actual, ")")
      }
    }

    message(status, " ", search_name, " (", search_sex, "): ", reason)
  }
}

# HELPER FUNCTIONS ====

#' Suggest similar spellings when exact match fails
#' @param name The name that wasn't found
#' @param data Classification data
#' @param sex Sex to filter by
suggest_similar_spellings <- function(name, data, sex = "both") {

  all_names <- if (sex == "both") {
    unique(data$classified_names$name)
  } else {
    unique(data$classified_names[sex == sex, name])
  }

  # Find names that start with same letters
  similar_start <- all_names[startsWith(tolower(all_names), tolower(substr(name, 1, 3)))]

  # Find names that sound similar (same ending)
  if (nchar(name) > 3) {
    name_ending <- tolower(substr(name, nchar(name)-2, nchar(name)))
    similar_ending <- all_names[endsWith(tolower(all_names), name_ending)]
  } else {
    similar_ending <- character(0)
  }

  # Combine and limit suggestions
  suggestions <- unique(c(similar_start, similar_ending))
  suggestions <- suggestions[suggestions != name]  # Remove exact match

  if (length(suggestions) > 0) {
    message("💡 Did you mean one of these?")
    message("   ", paste(head(suggestions, 8), collapse = ", "))
    if (length(suggestions) > 8) {
      message("   ... (", length(suggestions) - 8, " more similar names)")
    }
  }
}

# EXPORT FUNCTIONS ====

#' Export analysis results for a name
#' @param name Name to export
#' @param filename Output filename (optional)
export_analysis <- function(name, filename = NULL) {

  data <- quick_setup()
  if (is.null(data)) return(invisible(NULL))

  name <- stringr::str_to_title(name)

  # Get all data for this name
  name_data <- data$classified_names[name == name]

  if (nrow(name_data) == 0) {
    message("❌ Name not found")
    return(invisible(NULL))
  }

  if (is.null(filename)) {
    filename <- paste0("analysis_", tolower(name), "_", Sys.Date(), ".csv")
  }

  # Export to CSV
  write.csv(name_data, filename, row.names = FALSE)

  message("✅ Analysis exported to: ", filename)
  message("📁 Columns: ", paste(names(name_data), collapse = ", "))

  invisible(name_data)
}