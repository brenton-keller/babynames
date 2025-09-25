# INTERACTIVE NAME EXPLORER
# REPL-style interface for deep name investigation

# GLOBAL STATE ====
.explorer_env <- new.env()
.explorer_env$data <- NULL
.explorer_env$classifications <- NULL
.explorer_env$current_session <- list()

# MAIN INTERFACE ====

#' Start interactive name exploration session
#' @param auto_load Automatically load cached classification data
start_name_explorer <- function(auto_load = TRUE) {

  message("🚀 Starting Interactive Name Explorer")
  message("=====================================")

  if (auto_load) {
    message("📥 Loading cached classification data...")
    load_explorer_data()
  }

  message("\n🎯 Available Commands:")
  message("  explore(\"name\")           - Deep dive into a name")
  message("  compare(\"name1\", \"name2\") - Compare multiple names")
  message("  similar_to(\"name\")        - Find similar patterns")
  message("  plot_timeline(\"name\")     - Visualize trends")
  message("  show_states(\"name\")       - Geographic analysis")
  message("  verify(\"name\")            - Show classification logic")
  message("  help()                    - Show all commands")
  message("  exit_explorer()           - End session")

  message("\n💡 Example: explore(\"Brayden\")")
  message("Ready for exploration! 🔍")

  invisible(TRUE)
}

#' Load data for exploration
load_explorer_data <- function() {

  # Check for cached classification data
  class_file <- "data/processed/name_classifications.rds"

  if (file.exists(class_file)) {
    message("⚡ Loading from cache...")
    .explorer_env$classifications <- readRDS(class_file)
    .explorer_env$data <- .explorer_env$classifications$enhanced_data

    message("✅ Data loaded successfully!")
    message("📊 Available: ", nrow(.explorer_env$data), " name records")
    message("📈 Classifications: ", nrow(.explorer_env$classifications$classified_names), " names")

  } else {
    message("❌ No cached data found. Please run:")
    message("    source('tests/test_name_classification.R')")
    message("    to generate classification data first.")
    return(FALSE)
  }

  invisible(TRUE)
}

# CORE EXPLORATION FUNCTIONS ====

#' Deep dive exploration of a single name
#' @param name Name to explore (case insensitive)
#' @param sex Sex to analyze ("M", "F", or "both")
#' @param show_plot Whether to show timeline plot
explore <- function(name, sex = "both", show_plot = TRUE) {

  if (is.null(.explorer_env$data)) {
    message("❌ No data loaded. Run start_name_explorer() first.")
    return(invisible(NULL))
  }

  # Clean and validate input
  name <- stringr::str_to_title(name)

  message("\n" , paste(rep("=", 60), collapse = ""))
  message("🔍 EXPLORING: ", name)
  message(paste(rep("=", 60), collapse = ""))

  # Get classification info
  if (sex == "both") {
    classifications <- .explorer_env$classifications$classified_names[name == name]
  } else {
    classifications <- .explorer_env$classifications$classified_names[name == name & sex == sex]
  }

  if (nrow(classifications) == 0) {
    message("❌ Name '", name, "' not found in dataset")
    suggest_similar_names(name)
    return(invisible(NULL))
  }

  # Show summary for each sex
  for (i in 1:nrow(classifications)) {
    show_name_summary(classifications[i])
    message()
  }

  # Show historical timeline
  if (show_plot) {
    plot_timeline(name, sex)
  }

  # Store in session history
  .explorer_env$current_session$last_explored <- name
  .explorer_env$current_session$last_sex <- sex

  message("💡 Try: verify(\"", name, "\") to see classification logic")
  message("💡 Try: similar_to(\"", name, "\") to find related names")

  invisible(classifications)
}

#' Show summary info for a single name-sex combination
show_name_summary <- function(name_data) {

  d <- name_data[1]  # Should be single row

  message("📊 ", d$name, " (", d$sex, ") - ", d$classification)
  message("🔒 Confidence: ", d$classification_confidence)

  # Historical stats
  message("📈 Historical (1980-1989):")
  message("  Total births: ", format(d$baseline_total_births, big.mark = ","))
  message("  Years present: ", d$baseline_years_present, "/10")
  message("  Average annual: ", format(round(d$baseline_avg_annual, 1), big.mark = ","))

  # Modern stats
  message("🆕 Modern (1990-2024):")
  message("  Total births: ", format(d$modern_total_births, big.mark = ","))
  message("  Years present: ", d$modern_years_present, "/35")
  message("  Average annual: ", format(round(d$modern_avg_annual, 1), big.mark = ","))

  # Growth analysis
  if (is.finite(d$growth_ratio) && d$growth_ratio != Inf) {
    message("📊 Growth: ", round(d$growth_ratio, 1), "x")
  } else if (d$baseline_total_births == 0) {
    message("📊 Growth: NEW NAME (no historical data)")
  }

  # Why this classification?
  message("🎯 Why ", d$classification, "?")
  explain_classification_briefly(d)
}

#' Brief explanation of why a name got its classification
explain_classification_briefly <- function(name_data) {
  d <- name_data

  switch(d$classification,
    "ESTABLISHED" = message("  ✓ High baseline popularity (", format(d$baseline_total_births, big.mark = ","), " births pre-1990)"),
    "TRULY_NEW" = message("  ✓ No historical presence + modern popularity (", format(d$modern_total_births, big.mark = ","), " births post-1990)"),
    "EMERGING" = message("  ✓ Low baseline (", d$baseline_total_births, ") + high growth (", round(d$growth_ratio, 1), "x)"),
    "RISING" = message("  ✓ Established name with accelerating growth (", round(d$growth_ratio, 1), "x)"),
    "OTHER" = message("  ⚠️ Doesn't fit standard patterns")
  )
}

# COMPARISON FUNCTIONS ====

#' Compare multiple names side by side
#' @param names Vector of names to compare
#' @param sex Sex to analyze
compare <- function(names, sex = "M") {

  if (is.null(.explorer_env$data)) {
    message("❌ No data loaded. Run start_name_explorer() first.")
    return(invisible(NULL))
  }

  names <- stringr::str_to_title(names)

  message("\n🔬 COMPARING NAMES")
  message("==================")
  message("Names: ", paste(names, collapse = ", "))
  message("Sex: ", sex)

  # Get data for all names
  comparison_data <- data.table()

  for (name in names) {
    name_info <- .explorer_env$classifications$classified_names[name == name & sex == sex]
    if (nrow(name_info) > 0) {
      comparison_data <- rbind(comparison_data, name_info)
    } else {
      message("⚠️ ", name, " not found")
    }
  }

  if (nrow(comparison_data) == 0) {
    message("❌ No names found for comparison")
    return(invisible(NULL))
  }

  # Show comparison table
  show_comparison_table(comparison_data)

  # Plot comparison
  plot_comparison(names, sex)

  invisible(comparison_data)
}

#' Show comparison table (SMART LIMITING)
show_comparison_table <- function(comp_data) {

  # NEVER show more than 8 rows for interactive comparison
  if (nrow(comp_data) > 8) {
    message("⚠️ Found ", nrow(comp_data), " names - showing first 8 only")
    comp_data <- head(comp_data, 8)
    show_truncated <- TRUE
  } else {
    show_truncated <- FALSE
  }

  message("\n📊 COMPARISON TABLE")
  message(paste(rep("-", 80), collapse = ""))

  # Header
  cat(sprintf("%-12s %-12s %-10s %-10s %-10s %-8s\n",
              "Name", "Classification", "Baseline", "Modern", "Growth", "Eligible"))
  message(paste(rep("-", 80), collapse = ""))

  # Data rows
  for (i in 1:nrow(comp_data)) {
    d <- comp_data[i]
    growth_str <- if (is.finite(d$growth_ratio) && d$growth_ratio != Inf) {
      paste0(round(d$growth_ratio, 1), "x")
    } else {
      "NEW"
    }

    eligible <- ifelse(d$classification %in% c("TRULY_NEW", "EMERGING"), "YES", "NO")

    cat(sprintf("%-12s %-12s %-10s %-10s %-10s %-8s\n",
                d$name,
                d$classification,
                format(d$baseline_total_births, big.mark = ","),
                format(d$modern_total_births, big.mark = ","),
                growth_str,
                eligible))
  }

  if (show_truncated) {
    message("... (showing only first 8 names)")
    message("💡 Be more specific to get focused results")
  }

  message("")
}

# VERIFICATION FUNCTIONS ====

#' Show detailed classification logic for a name
#' @param name Name to verify
#' @param sex Sex to check
verify <- function(name, sex = "M") {

  if (is.null(.explorer_env$data)) {
    message("❌ No data loaded. Run start_name_explorer() first.")
    return(invisible(NULL))
  }

  name <- stringr::str_to_title(name)

  message("\n🔍 CLASSIFICATION VERIFICATION: ", name, " (", sex, ")")
  message(paste(rep("=", 60), collapse = ""))

  # Get classification data
  class_data <- .explorer_env$classifications$classified_names[name == name & sex == sex]

  if (nrow(class_data) == 0) {
    message("❌ Name not found")
    return(invisible(NULL))
  }

  d <- class_data[1]
  config <- CLASSIFICATION_CONFIG$thresholds

  message("📋 STEP-BY-STEP LOGIC:")
  message("")

  # Step 1: Data check
  message("1️⃣ DATA AVAILABILITY:")
  message("  ✓ Baseline births (1980-1989): ", format(d$baseline_total_births, big.mark = ","))
  message("  ✓ Modern births (1990-2024): ", format(d$modern_total_births, big.mark = ","))
  message("  ✓ Growth ratio: ", if (is.finite(d$growth_ratio)) round(d$growth_ratio, 1) else "N/A")
  message("")

  # Step 2: Classification rules
  message("2️⃣ CLASSIFICATION RULES:")

  # Test ESTABLISHED
  established_test1 <- d$baseline_total_births >= config$established_min_births
  established_test2 <- d$baseline_years_present >= config$established_min_years
  message("  ESTABLISHED test:")
  message("    Baseline ≥ ", config$established_min_births, ": ", d$baseline_total_births, " ", ifelse(established_test1, "✅", "❌"))
  message("    Years ≥ ", config$established_min_years, ": ", d$baseline_years_present, " ", ifelse(established_test2, "✅", "❌"))
  message("    Result: ", ifelse(established_test1 & established_test2, "ESTABLISHED", "Not established"))
  message("")

  # Test TRULY_NEW
  truly_new_test1 <- d$baseline_total_births == 0
  truly_new_test2 <- d$modern_total_births >= 100
  message("  TRULY_NEW test:")
  message("    Baseline = 0: ", d$baseline_total_births, " ", ifelse(truly_new_test1, "✅", "❌"))
  message("    Modern ≥ 100: ", d$modern_total_births, " ", ifelse(truly_new_test2, "✅", "❌"))
  message("    Result: ", ifelse(truly_new_test1 & truly_new_test2, "TRULY_NEW", "Not truly new"))
  message("")

  # Test EMERGING
  emerging_test1 <- d$baseline_total_births > 0
  emerging_test2 <- d$baseline_total_births < config$established_min_births
  emerging_test3 <- d$modern_total_births >= config$emerging_min_births
  message("  EMERGING test:")
  message("    Baseline > 0: ", d$baseline_total_births, " ", ifelse(emerging_test1, "✅", "❌"))
  message("    Baseline < ", config$established_min_births, ": ", d$baseline_total_births, " ", ifelse(emerging_test2, "✅", "❌"))
  message("    Modern ≥ ", config$emerging_min_births, ": ", d$modern_total_births, " ", ifelse(emerging_test3, "✅", "❌"))
  message("    Result: ", ifelse(emerging_test1 & emerging_test2 & emerging_test3, "EMERGING", "Not emerging"))
  message("")

  # Final result
  message("3️⃣ FINAL CLASSIFICATION: ", d$classification, " (", d$classification_confidence, " confidence)")

  # Suggest related analysis
  message("\n💡 RELATED ANALYSIS:")
  message("  similar_to(\"", name, "\") - Find similar patterns")
  message("  plot_timeline(\"", name, "\") - See historical trend")

  invisible(class_data)
}

# UTILITY FUNCTIONS ====

#' Suggest similar names when search fails
suggest_similar_names <- function(name) {
  # Simple suggestions based on edit distance
  all_names <- unique(.explorer_env$classifications$classified_names$name)

  # Find names with similar start
  similar_start <- all_names[startsWith(all_names, substr(name, 1, 2))]

  if (length(similar_start) > 0) {
    message("💡 Did you mean one of these?")
    message("  ", paste(head(similar_start, 5), collapse = ", "))
  }
}

#' Show help for all commands
help <- function() {
  message("\n🎯 INTERACTIVE NAME EXPLORER - HELP")
  message("====================================")
  message("")
  message("CORE COMMANDS:")
  message("  explore(\"name\", sex=\"both\")     - Deep dive into a name")
  message("  compare(c(\"name1\", \"name2\"))     - Compare multiple names")
  message("  verify(\"name\", sex=\"M\")          - Show classification logic")
  message("")
  message("VISUAL ANALYSIS:")
  message("  plot_timeline(\"name\")            - Historical trend plot")
  message("  plot_comparison(names, sex)      - Side-by-side comparison")
  message("")
  message("DISCOVERY:")
  message("  similar_to(\"name\")               - Find similar patterns")
  message("  random_name(classification)      - Get random example")
  message("")
  message("SESSION MANAGEMENT:")
  message("  load_explorer_data()            - Reload data")
  message("  show_session()                  - Show current session")
  message("  exit_explorer()                 - End session")
  message("")
  message("EXAMPLES:")
  message("  explore(\"Brayden\")               # Deep dive")
  message("  compare(c(\"Brayden\", \"Jayden\"))  # Compare trends")
  message("  verify(\"Nevaeh\")                 # Verify classification")
}

#' Exit explorer session
exit_explorer <- function() {
  message("👋 Ending Interactive Name Explorer session")
  message("Session summary:")

  if (!is.null(.explorer_env$current_session$last_explored)) {
    message("  Last explored: ", .explorer_env$current_session$last_explored)
  }

  message("Thanks for exploring! 🔍")
}

# INTEGRATION WITH OTHER MODULES ====

# These functions are implemented in visual_explorer.R
# They're loaded when the user sources that file

#' Find similar names (placeholder)
similar_to <- function(name) {
  if (is.null(.explorer_env$data)) {
    message("❌ No data loaded. Run start_name_explorer() first.")
    return(invisible(NULL))
  }

  name <- stringr::str_to_title(name)

  # Simple similarity based on name patterns
  all_names <- unique(.explorer_env$classifications$classified_names$name)

  # Names with same ending (but only show max 5)
  name_ending <- substr(name, nchar(name)-2, nchar(name))
  similar_ending <- all_names[endsWith(all_names, name_ending)]
  similar_ending <- similar_ending[similar_ending != name]  # Remove self

  # Names with same beginning (but only show max 5)
  name_start <- substr(name, 1, 2)
  similar_start <- all_names[startsWith(all_names, name_start)]
  similar_start <- similar_start[similar_start != name]  # Remove self

  message("🔍 Names similar to ", name, ":")

  if (length(similar_ending) > 0) {
    message("Similar ending (-", name_ending, "): ", paste(head(similar_ending, 5), collapse = ", "))
    if (length(similar_ending) > 5) {
      message("  ... and ", length(similar_ending) - 5, " more")
    }
  }

  if (length(similar_start) > 0) {
    message("Similar beginning (", name_start, "-): ", paste(head(similar_start, 5), collapse = ", "))
    if (length(similar_start) > 5) {
      message("  ... and ", length(similar_start) - 5, " more")
    }
  }

  invisible(list(similar_ending = similar_ending, similar_start = similar_start))
}