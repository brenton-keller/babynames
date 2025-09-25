# NAME CLASSIFICATION SYSTEM
# Distinguishes between established, emerging, and truly new names

# CLASSIFICATION CONSTANTS ====

# Define classification thresholds and criteria
CLASSIFICATION_CONFIG <- list(
  # Historical cutoff - names popular before this are "established"
  emergence_cutoff_year = 1990,

  # Years to look back for baseline calculation
  baseline_years = 10,  # 1980-1989 for 1990 cutoff

  # Thresholds for classification
  thresholds = list(
    established_min_births = 5000,    # Must have 5K+ births in baseline period
    established_min_years = 5,        # Must appear in 5+ years of baseline
    emerging_min_births = 50,         # 50-5000 births in baseline = emerging
    rising_growth_factor = 3.0        # Post/pre ratio for "rising" classification
  ),

  # Special handling for known categories
  known_modern_names = c(
    # Truly new names that definitely emerged post-1990
    "Nevaeh", "Neveah", "Nevaya",    # Heaven backwards
    "Jayceon", "Jaxon", "Braxton",   # Modern inventions
    "Maddox", "Zayden", "Kyler"      # Contemporary creations
  ),

  known_established_names = c(
    # Definitely established before 1990 - Male names
    "Michael", "Christopher", "Matthew", "Joshua", "David", "Daniel", "James",
    "Robert", "John", "William", "Richard", "Thomas", "Charles", "Mark",
    "Steven", "Paul", "Andrew", "Kenneth", "Brian", "Kevin", "Edward",
    "Oliver", "Henry", "Alexander", "Benjamin", "Samuel", "Nicholas",

    # Definitely established before 1990 - Female names
    "Ashley", "Jessica", "Amanda", "Jennifer", "Sarah", "Melissa", "Amy",
    "Lisa", "Michelle", "Kimberly", "Angela", "Tiffany", "Crystal",
    "Stephanie", "Nicole", "Heather", "Elizabeth", "Emily", "Rebecca",
    "Rachel", "Catherine", "Katherine", "Laura", "Susan", "Linda"
  )
)

# CORE CLASSIFICATION FUNCTIONS ====

#' Calculate baseline statistics for all names
#' @param dt Full historical baby names data (1880+)
#' @param cutoff_year Year that defines "modern" vs historical
#' @param baseline_years Number of years before cutoff to analyze
#' @return data.table with baseline statistics
calculate_baseline_stats <- function(dt,
                                   cutoff_year = 1990,
                                   baseline_years = 10) {

  # Define periods
  baseline_start <- cutoff_year - baseline_years
  baseline_end <- cutoff_year - 1

  baseline_period <- baseline_start:baseline_end
  modern_period_start <- cutoff_year

  message("📊 Calculating baseline statistics...")
  message("Baseline period: ", baseline_start, "-", baseline_end)
  message("Modern period: ", modern_period_start, "+")

  # Calculate baseline (pre-cutoff) statistics
  baseline_data <- dt[year %in% baseline_period]
  baseline_stats <- baseline_data[, .(
    baseline_total_births = sum(n),
    baseline_years_present = uniqueN(year),
    baseline_avg_annual = mean(n),
    baseline_peak_year = year[which.max(n)],
    baseline_peak_births = max(n),
    baseline_first_year = min(year),
    baseline_last_year = max(year)
  ), by = .(sex, name)]

  # Calculate modern (post-cutoff) statistics
  modern_data <- dt[year >= modern_period_start]
  modern_stats <- modern_data[, .(
    modern_total_births = sum(n),
    modern_years_present = uniqueN(year),
    modern_avg_annual = mean(n),
    modern_peak_year = year[which.max(n)],
    modern_peak_births = max(n),
    modern_first_year = min(year)
  ), by = .(sex, name)]

  # Merge baseline and modern stats
  all_stats <- merge(baseline_stats, modern_stats,
                     by = c("sex", "name"), all = TRUE)

  # Handle NAs (names that don't appear in one period)
  numeric_cols <- c("baseline_total_births", "baseline_years_present", "baseline_avg_annual",
                   "baseline_peak_births", "modern_total_births", "modern_years_present",
                   "modern_avg_annual", "modern_peak_births")

  for (col in numeric_cols) {
    all_stats[is.na(get(col)), (col) := 0]
  }

  # Calculate derived metrics
  all_stats[, growth_ratio := ifelse(baseline_avg_annual > 0,
                                    modern_avg_annual / baseline_avg_annual,
                                    Inf)]

  all_stats[, total_historical := baseline_total_births + modern_total_births]

  # SANITY CHECKS for baseline calculation
  message("\n🔍 BASELINE CALCULATION SANITY CHECKS:")
  message("Total name-sex combinations: ", nrow(all_stats))

  # Check some known names
  test_names <- c("Michael", "Ashley", "Nevaeh", "Aiden")
  for (test_name in test_names) {
    test_stats <- all_stats[name == test_name & sex == "M"]  # Check male version
    if (nrow(test_stats) > 0) {
      s <- test_stats[1]
      message("✓ ", test_name, " (M): baseline=", s$baseline_total_births,
             ", modern=", s$modern_total_births,
             ", growth=", if(is.finite(s$growth_ratio)) round(s$growth_ratio, 1) else "NEW")
    } else {
      message("⚠️  ", test_name, " (M): NOT FOUND")
    }
  }

  # Check for potential duplicates
  duplicates <- all_stats[, .N, by = .(sex, name)][N > 1]
  if (nrow(duplicates) > 0) {
    message("❌ CRITICAL: Found ", nrow(duplicates), " duplicate name-sex combinations!")
  } else {
    message("✅ No duplicate name-sex combinations")
  }

  setkey(all_stats, sex, name)
  all_stats
}

#' Classify names into categories based on historical patterns
#' @param baseline_stats Results from calculate_baseline_stats()
#' @param config Classification configuration list
#' @return data.table with classifications added
classify_names <- function(baseline_stats, config = CLASSIFICATION_CONFIG) {

  dt <- copy(baseline_stats)
  thresholds <- config$thresholds

  message("🏷️  Classifying names into categories...")

  # Apply classification rules
  dt[, classification := "OTHER"]  # Default

  # 1. ESTABLISHED: High baseline popularity
  dt[baseline_total_births >= thresholds$established_min_births &
     baseline_years_present >= thresholds$established_min_years,
     classification := "ESTABLISHED"]

  # 2. TRULY_NEW: No baseline presence, substantial modern presence
  dt[baseline_total_births == 0 & modern_total_births >= 100,
     classification := "TRULY_NEW"]

  # 3. EMERGING: Some baseline presence but low, growing in modern period
  dt[baseline_total_births > 0 &
     baseline_total_births < thresholds$established_min_births &
     modern_total_births >= thresholds$emerging_min_births,
     classification := "EMERGING"]

  # 4. RISING: Established but growing significantly
  dt[classification == "ESTABLISHED" &
     growth_ratio >= thresholds$rising_growth_factor,
     classification := "RISING"]

  # 5. Override with known classifications
  dt[name %in% config$known_established_names, classification := "ESTABLISHED"]
  dt[name %in% config$known_modern_names, classification := "TRULY_NEW"]

  # Add classification metadata
  dt[, classification_confidence := fcase(
    name %in% c(config$known_established_names, config$known_modern_names), "HIGH",
    classification == "TRULY_NEW" & baseline_total_births == 0, "HIGH",
    classification == "ESTABLISHED" & baseline_total_births >= 10000, "HIGH",
    classification %in% c("EMERGING", "RISING"), "MEDIUM",
    default = "LOW"
  )]

  # Summary statistics
  classification_summary <- dt[, .N, by = classification][order(-N)]
  message("\n📈 Classification Results:")
  for (i in 1:nrow(classification_summary)) {
    cat(sprintf("  %s: %d names (%.1f%%)\n",
                classification_summary[i, classification],
                classification_summary[i, N],
                classification_summary[i, N] / nrow(dt) * 100))
  }

  # SANITY CHECKS
  message("\n🔍 SANITY CHECKS:")

  # Check for known names in correct categories
  known_established <- c("Michael", "Ashley", "Christopher", "Jessica")
  known_new <- c("Nevaeh", "Jayceon")
  known_emerging <- c("Aiden", "Jayden")

  message("✓ Checking known ESTABLISHED names:")
  for (name in known_established) {
    classifications <- dt[name == name, unique(classification)]
    if (length(classifications) == 0) {
      message("  ❌ ", name, ": NOT_FOUND")
    } else {
      status <- ifelse("ESTABLISHED" %in% classifications, "✅", "❌")
      message("  ", status, " ", name, ": ", paste(classifications, collapse = ", "))
    }
  }

  message("✓ Checking known TRULY_NEW names:")
  for (name in known_new) {
    classifications <- dt[name == name, unique(classification)]
    if (length(classifications) == 0) {
      message("  ⚠️  ", name, ": NOT_FOUND (might be too rare)")
    } else {
      status <- ifelse("TRULY_NEW" %in% classifications, "✅", "❌")
      message("  ", status, " ", name, ": ", paste(classifications, collapse = ", "))
    }
  }

  message("✓ Checking known EMERGING names:")
  for (name in known_emerging) {
    classifications <- dt[name == name, unique(classification)]
    if (length(classifications) == 0) {
      message("  ❌ ", name, ": NOT_FOUND")
    } else {
      status <- ifelse("EMERGING" %in% classifications, "✅", "❌")
      message("  ", status, " ", name, ": ", paste(classifications, collapse = ", "))
    }
  }

  # Check for duplicate classifications (shouldn't exist)
  duplicates <- dt[, .N, by = .(sex, name)][N > 1]
  if (nrow(duplicates) > 0) {
    message("❌ CRITICAL: Found ", nrow(duplicates), " names with duplicate classifications!")
    message("   Examples: ", paste(head(duplicates[, paste(sex, name)], 5), collapse = ", "))
  } else {
    message("✅ No duplicate classifications found")
  }

  setkey(dt, sex, name)
  dt
}

#' Filter names suitable for origin analysis
#' @param classified_names Results from classify_names()
#' @param include_categories Which classifications to include in origin analysis
#' @return Filtered data.table
filter_for_origin_analysis <- function(classified_names,
                                      include_categories = c("TRULY_NEW", "EMERGING")) {

  suitable_names <- classified_names[classification %in% include_categories]

  message("🎯 Names suitable for origin analysis:")
  message("Total names: ", nrow(suitable_names))

  # Show breakdown by category
  breakdown <- suitable_names[, .N, by = classification]
  for (i in 1:nrow(breakdown)) {
    message("  ", breakdown[i, classification], ": ", breakdown[i, N])
  }

  # Show some examples
  message("\n📝 Example names by category:")
  for (cat in include_categories) {
    examples <- suitable_names[classification == cat, head(name, 5)]
    if (length(examples) > 0) {
      message("  ", cat, ": ", paste(examples, collapse = ", "))
    }
  }

  setkey(suitable_names, sex, name)
  suitable_names
}

# HIGH-LEVEL WORKFLOW FUNCTION ====

#' Complete name classification workflow
#' @param historical_data Full baby names dataset (1880+)
#' @param cutoff_year Year dividing historical vs modern periods
#' @param config Classification configuration
#' @return List with baseline stats, classifications, and filtered names
classify_names_for_analysis <- function(historical_data,
                                       cutoff_year = 1990,
                                       config = CLASSIFICATION_CONFIG) {

  message("🚀 Starting name classification workflow...")
  message("Dataset size: ", nrow(historical_data), " rows")
  message("Year range: ", min(historical_data$year), "-", max(historical_data$year))

  # Step 1: Calculate baseline statistics
  baseline_stats <- calculate_baseline_stats(historical_data, cutoff_year, config$baseline_years)

  # Step 2: Classify names
  classified_names <- classify_names(baseline_stats, config)

  # Step 3: Filter for origin analysis
  suitable_for_analysis <- filter_for_origin_analysis(classified_names)

  message("\n✅ Classification workflow complete!")

  list(
    baseline_stats = baseline_stats,
    classified_names = classified_names,
    suitable_for_analysis = suitable_for_analysis,
    config = config,
    cutoff_year = cutoff_year
  )
}

# UTILITY FUNCTIONS ====

#' Show detailed information about a specific name's classification
#' @param name_to_check Name to analyze
#' @param sex_to_check Sex code ("M" or "F")
#' @param classified_data Results from classify_names_for_analysis()
show_name_details <- function(name_to_check, sex_to_check, classified_data) {

  details <- classified_data$classified_names[name == name_to_check & sex == sex_to_check]

  if (nrow(details) == 0) {
    message("❌ Name '", name_to_check, "' (", sex_to_check, ") not found in dataset")
    return(invisible(NULL))
  }

  d <- details[1]  # Should only be one row

  cat("📊 Analysis for:", name_to_check, "(", sex_to_check, ")\n")
  cat("Classification:", d$classification, "(confidence:", d$classification_confidence, ")\n\n")

  cat("📈 Historical Statistics (pre-", classified_data$cutoff_year, "):\n")
  cat("  Total births:", d$baseline_total_births, "\n")
  cat("  Years present:", d$baseline_years_present, "\n")
  cat("  Average annual:", round(d$baseline_avg_annual, 1), "\n")
  cat("  Peak year:", d$baseline_peak_year, "with", d$baseline_peak_births, "births\n\n")

  cat("🆕 Modern Statistics (", classified_data$cutoff_year, "+):\n")
  cat("  Total births:", d$modern_total_births, "\n")
  cat("  Years present:", d$modern_years_present, "\n")
  cat("  Average annual:", round(d$modern_avg_annual, 1), "\n")
  cat("  Growth ratio:", if (is.finite(d$growth_ratio)) round(d$growth_ratio, 1) else "New name", "\n")

  cat("\n🎯 Origin Analysis Eligible:",
      ifelse(d$classification %in% c("TRULY_NEW", "EMERGING"), "✅ YES", "❌ NO"), "\n")
}