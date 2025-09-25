# DATA VALIDATION AND QUALITY CONTROL
# Ensures data integrity and classification accuracy

# VALIDATION TEST CASES ====

# Known examples for testing classification accuracy
VALIDATION_CASES <- list(
  ESTABLISHED = list(
    # These should definitely be classified as established (popular before 1990)
    male = c("Michael", "Christopher", "Matthew", "Joshua", "David", "Daniel", "James", "John"),
    female = c("Ashley", "Jessica", "Amanda", "Jennifer", "Sarah", "Melissa", "Amy", "Lisa")
  ),

  TRULY_NEW = list(
    # These should be classified as truly new (didn't exist before 1990s)
    unisex = c("Nevaeh"),  # Heaven backwards, created ~2001
    male = c("Jayceon", "Braxton", "Jaxon", "Kyler"),  # Modern inventions
    female = c("Ximena", "Aaliyah", "Zoe")  # Names that became popular post-1990
  ),

  EMERGING = list(
    # Names that existed but were rare before 1990, then grew
    male = c("Aiden", "Jayden", "Austin", "Trevor"),
    female = c("Brittany", "Kayla", "Kaitlyn", "Madison")
  )
)

# Expected problematic cases that should be caught
PROBLEMATIC_CASES <- list(
  # Small state anomalies - these shouldn't show as origins
  small_state_origins = c("VT", "WY", "ND", "AK", "DE"),

  # Names that might get misclassified due to data limitations
  likely_misclassified = c("Aaron", "Adam", "Brian")  # Popular in 1970s-80s
)

# VALIDATION FUNCTIONS ====

#' Validate data quality and completeness
#' @param dt Baby names dataset
#' @return List of validation results
validate_data_quality <- function(dt) {

  validation_results <- list()

  message("🔍 Running data quality validation...")

  # Basic structure validation
  required_cols <- c("year", "sex", "name", "n")
  missing_cols <- setdiff(required_cols, names(dt))

  validation_results$structure <- list(
    has_required_columns = length(missing_cols) == 0,
    missing_columns = missing_cols,
    total_rows = nrow(dt),
    year_range = c(min(dt$year), max(dt$year)),
    unique_names = dt[, uniqueN(name)],
    total_births = sum(dt$n)
  )

  # Year coverage validation
  year_gaps <- find_year_gaps(dt)
  validation_results$temporal <- list(
    year_gaps = year_gaps,
    continuous_coverage = length(year_gaps) == 0
  )

  # State coverage validation (if state column exists)
  if ("state" %in% names(dt)) {
    state_coverage <- validate_state_coverage(dt)
    validation_results$geographic <- state_coverage
  } else {
    validation_results$geographic <- list(
      note = "State column not present in national dataset"
    )
  }

  # Data consistency checks
  validation_results$consistency <- validate_data_consistency(dt)

  message("✅ Data quality validation complete")

  validation_results
}

#' Find gaps in year coverage
#' @param dt Dataset with year column
#' @return Vector of missing years
find_year_gaps <- function(dt) {
  available_years <- sort(unique(dt$year))
  full_range <- min(available_years):max(available_years)
  missing_years <- setdiff(full_range, available_years)
  missing_years
}

#' Validate state coverage and identify issues
#' @param dt Dataset with state column
#' @return List of state validation results
validate_state_coverage <- function(dt) {

  # Expected US states + DC
  expected_states <- c(
    state.abb, "DC"  # All 50 states plus District of Columbia
  )

  available_states <- unique(dt$state)
  missing_states <- setdiff(expected_states, available_states)
  unexpected_states <- setdiff(available_states, expected_states)

  # Check for suspicious patterns
  state_birth_totals <- dt[, .(total_births = sum(n)), by = state][order(-total_births)]

  # Very small states that might cause statistical issues
  small_states <- state_birth_totals[total_births < quantile(total_births, 0.1), state]

  list(
    expected_states = length(expected_states),
    available_states = length(available_states),
    missing_states = missing_states,
    unexpected_states = unexpected_states,
    small_states_flagged = small_states,
    state_birth_totals = head(state_birth_totals, 10)
  )
}

#' Validate data consistency and detect anomalies
#' @param dt Dataset to validate
#' @return List of consistency check results
validate_data_consistency <- function(dt) {

  # Check for negative or zero birth counts
  invalid_counts <- dt[n <= 0, .N]

  # Check for unrealistic birth counts (very high outliers)
  birth_quantiles <- quantile(dt$n, c(0.95, 0.99, 0.999))
  extreme_outliers <- dt[n > birth_quantiles[["99.9%"]], .(year, sex, name, n)][order(-n)]

  # Check for duplicate records
  if ("state" %in% names(dt)) {
    duplicates <- dt[, .N, by = .(year, sex, name, state)][N > 1]
  } else {
    duplicates <- dt[, .N, by = .(year, sex, name)][N > 1]
  }

  # Check sex code consistency
  valid_sex_codes <- c("M", "F")
  invalid_sex_codes <- dt[!sex %in% valid_sex_codes, unique(sex)]

  list(
    invalid_birth_counts = invalid_counts,
    extreme_outliers = head(extreme_outliers, 5),
    birth_count_quantiles = birth_quantiles,
    duplicate_records = nrow(duplicates),
    invalid_sex_codes = invalid_sex_codes
  )
}

# CLASSIFICATION VALIDATION ====

#' Test classification system against known examples
#' @param classified_data Results from classify_names_for_analysis()
#' @return Validation report
validate_classification_accuracy <- function(classified_data) {

  message("🎯 Validating classification accuracy...")

  validation_report <- list()
  classified_names <- classified_data$classified_names

  # Test each category
  for (expected_class in names(VALIDATION_CASES)) {
    category_results <- list()

    for (sex_group in names(VALIDATION_CASES[[expected_class]])) {
      test_names <- VALIDATION_CASES[[expected_class]][[sex_group]]

      # Determine sex code
      sex_code <- switch(sex_group,
                        "male" = "M",
                        "female" = "F",
                        "unisex" = c("M", "F"))

      if (length(sex_code) == 1) {
        # Single sex test
        results <- test_classification_group(test_names, sex_code, expected_class, classified_names)
        category_results[[sex_group]] <- results
      } else {
        # Unisex - test both
        for (sc in sex_code) {
          results <- test_classification_group(test_names, sc, expected_class, classified_names)
          category_results[[paste0(sex_group, "_", sc)]] <- results
        }
      }
    }

    validation_report[[expected_class]] <- category_results
  }

  # Calculate overall accuracy
  validation_report$summary <- calculate_validation_summary(validation_report)

  message("📊 Classification validation complete")
  validation_report
}

#' Test a group of names for correct classification
#' @param test_names Vector of names to test
#' @param sex_code Sex code to test
#' @param expected_class Expected classification
#' @param classified_data Classified names dataset
#' @return Test results
test_classification_group <- function(test_names, sex_code, expected_class, classified_data) {

  results <- list()

  # Simplified testing without verbose output
  for (name in test_names) {
    matches <- classified_data[name == name & sex == sex_code]

    if (nrow(matches) == 0) {
      result <- "NOT_FOUND"
    } else if (nrow(matches) > 1) {
      # Multiple matches - this shouldn't happen, take first
      result <- paste0("MULTIPLE:", matches[1, classification])
    } else if (matches$classification == expected_class) {
      result <- "CORRECT"
    } else {
      result <- paste0("WRONG:", matches$classification)
    }

    results[[name]] <- result
  }

  # Summary for this group
  correct_count <- sum(sapply(results, function(x) x == "CORRECT"))
  total_count <- length(results)

  list(
    individual_results = results,
    correct_count = correct_count,
    total_count = total_count,
    accuracy_rate = correct_count / total_count
  )
}

#' Calculate overall validation summary
#' @param validation_report Full validation results
#' @return Summary statistics
calculate_validation_summary <- function(validation_report) {

  total_correct <- 0
  total_tested <- 0

  for (category in names(validation_report)) {
    if (category != "summary") {
      for (group in names(validation_report[[category]])) {
        total_correct <- total_correct + validation_report[[category]][[group]]$correct_count
        total_tested <- total_tested + validation_report[[category]][[group]]$total_count
      }
    }
  }

  overall_accuracy <- if (total_tested > 0) total_correct / total_tested else 0

  list(
    total_tested = total_tested,
    total_correct = total_correct,
    overall_accuracy = overall_accuracy,
    accuracy_percentage = round(overall_accuracy * 100, 1)
  )
}

# REPORTING FUNCTIONS ====

#' Generate a comprehensive validation report
#' @param validation_results Results from validate_classification_accuracy()
print_validation_report <- function(validation_results) {

  cat("📋 CLASSIFICATION VALIDATION REPORT\n")
  cat("=====================================\n\n")

  # Overall summary
  summary <- validation_results$summary
  cat("🎯 Overall Accuracy:", summary$accuracy_percentage, "%\n")
  cat("   (", summary$total_correct, "/", summary$total_tested, " correct)\n\n")

  # Category breakdown
  for (category in names(validation_results)) {
    if (category != "summary") {
      cat("📂", category, ":\n")

      for (group in names(validation_results[[category]])) {
        group_result <- validation_results[[category]][[group]]
        accuracy <- round(group_result$accuracy_rate * 100, 1)

        cat("   ", group, ":", accuracy, "%",
            "(", group_result$correct_count, "/", group_result$total_count, ")\n")

        # Show failures
        failures <- group_result$individual_results[sapply(group_result$individual_results,
                                                          function(x) x != "CORRECT")]
        if (length(failures) > 0) {
          cat("      Failures:", paste(names(failures), "=", failures, collapse = ", "), "\n")
        }
      }
      cat("\n")
    }
  }
}

#' Quick validation check for development
#' @param classified_data Results from classification
quick_validation_check <- function(classified_data) {
  message("🔥 Quick validation check...")

  # Check a few known cases
  test_cases <- list(
    c("Michael", "M", "ESTABLISHED"),
    c("Nevaeh", "F", "TRULY_NEW"),
    c("Aiden", "M", "EMERGING")
  )

  for (test_case in test_cases) {
    name <- test_case[1]
    sex <- test_case[2]
    expected <- test_case[3]

    actual <- classified_data$classified_names[name == name & sex == sex, classification]
    status <- ifelse(length(actual) > 0 && actual == expected, "✅", "❌")

    message(status, " ", name, " (", sex, "): expected ", expected,
           ", got ", ifelse(length(actual) > 0, actual, "NOT_FOUND"))
  }
}