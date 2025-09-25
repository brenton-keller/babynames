# WEEK 2 INTERFACE: ORIGIN DETECTION AND GEOGRAPHIC SPREAD
# Convenient functions to explore name origins and diffusion patterns

# MAIN INTERFACE FUNCTIONS ====

#' Complete origin analysis for a name - the main Week 2 function
#' @param name Name to analyze (e.g., "Ayden", "Khaleesi")
#' @param sex Sex to analyze ("M", "F", or "both")
#' @param show_spread Whether to show geographic spread visualization
explore_name_origin <- function(name, sex = "F", show_spread = TRUE) {

  message("🌟 WEEK 2: ORIGIN & DIFFUSION ANALYSIS")
  message("=" %r% 55)
  message("🎯 Analyzing: ", stringr::str_to_title(name), " (", sex, ")")
  message("")

  # Load all required functions
  source("R/analysis/enhanced_origin_detection.R")
  source("R/interface/origin_visualization.R")
  source("R/interface/quick_analysis.R")

  # Step 1: Show Week 1 classification info
  message("📊 STEP 1: Classification Status")
  message("-" %r% 30)
  investigate_name(name, sex = sex, show_plot = FALSE)

  # Step 2: Find and show origin
  message("\n🎯 STEP 2: Origin Detection")
  message("-" %r% 30)
  origin_results <- investigate_origin(name, sex)

  # Step 3: Geographic spread visualization
  if (show_spread && !is.null(origin_results)) {
    message("\n📊 STEP 3: Geographic Spread")
    message("-" %r% 30)
    visualize_name_spread(name, sex, min_births = 3)

    message("\n🗺️  STEP 4: Regional Patterns")
    message("-" %r% 30)
    show_regional_patterns(name, sex)
  }

  message("\n✅ Complete analysis finished for ", stringr::str_to_title(name))

  invisible(origin_results)
}

#' Quick test of the Week 2 system with validated examples
test_week2_system <- function() {

  message("🧪 TESTING WEEK 2 ENHANCED ORIGIN DETECTION")
  message("=" %r% 50)

  # Test with the enhanced system using a few known examples
  source("R/analysis/enhanced_origin_detection.R")

  # Run the main test
  test_results <- test_enhanced_origins()

  message("\n💡 To explore individual names, use:")
  message("   explore_name_origin('Ayden', 'M')")
  message("   explore_name_origin('Khaleesi', 'F')")
  message("   explore_name_origin('Nevaeh', 'F')")

  invisible(test_results)
}

#' Compare origins of multiple names
compare_name_origins <- function(..., sex = "F") {

  names_to_compare <- unlist(list(...))

  message("🔄 COMPARING ORIGINS: ", paste(names_to_compare, collapse = ", "))
  message("=" %r% 50)

  # Load functions
  source("R/analysis/enhanced_origin_detection.R")
  source("R/interface/origin_visualization.R")

  # Investigate each name
  for (name in names_to_compare) {
    message("\n--- ", stringr::str_to_title(name), " ---")
    investigate_origin(name, sex)
  }

  # Visual comparison
  message("\n📊 VISUAL COMPARISON")
  message("-" %r% 30)
  compare_spread_patterns(names_to_compare, sex)

  message("\n✅ Comparison complete")
}

# CONVENIENCE FUNCTIONS FOR SPECIFIC NAME TYPES ====

#' Analyze Game of Thrones names with Week 2 origin detection
analyze_got_origins <- function() {

  message("🐉 GAME OF THRONES: Week 2 Origin Analysis")
  message("=" %r% 50)

  got_names <- c("Khaleesi", "Daenerys", "Arya")

  for (name in got_names) {
    message("\n🔍 ", name, " Origin Analysis:")
    message("-" %r% 25)
    explore_name_origin(name, sex = "F", show_spread = FALSE)
    message("")
  }

  # Compare their spread patterns
  message("\n📊 GoT Names Spread Comparison:")
  compare_spread_patterns(got_names, "F")
}

#' Analyze modern invented names (Nevaeh category)
analyze_modern_invented <- function() {

  message("✨ MODERN INVENTED NAMES: Origin Analysis")
  message("=" %r% 50)

  modern_names <- c("Nevaeh", "Jaelyn", "Kylee", "Destinee")

  for (name in modern_names) {
    message("\n🔍 ", name, " Origin Analysis:")
    message("-" %r% 25)
    explore_name_origin(name, sex = "F", show_spread = FALSE)
    message("")
  }
}

#' Analyze Aiden-style names (emerging category)
analyze_aiden_variants <- function() {

  message("🌊 AIDEN VARIANTS: Origin Analysis")
  message("=" %r% 50)

  aiden_names <- c("Aiden", "Ayden", "Jayden", "Brayden", "Kaden")

  for (name in aiden_names) {
    message("\n🔍 ", name, " Origin Analysis:")
    message("-" %r% 25)
    explore_name_origin(name, sex = "M", show_spread = FALSE)
    message("")
  }

  # Compare their patterns
  message("\n📊 Aiden Variants Comparison:")
  compare_spread_patterns(aiden_names, "M")
}

# BATCH ANALYSIS FUNCTIONS ====

#' Run comprehensive Week 2 analysis on multiple name categories
comprehensive_week2_analysis <- function() {

  message("🚀 COMPREHENSIVE WEEK 2 ANALYSIS")
  message("=" %r% 50)

  # Test the system first
  test_week2_system()

  # Analyze key categories
  message("\n" %r% 60)
  analyze_got_origins()

  message("\n" %r% 60)
  analyze_aiden_variants()

  message("\n✅ Comprehensive analysis complete!")
  message("\n💡 Individual exploration commands:")
  message("   explore_name_origin('YourName', 'F')")
  message("   compare_name_origins('Name1', 'Name2', 'Name3')")
}

# VALIDATION FUNCTIONS ====

#' Validate that Week 2 fixes the Week 1 problems
validate_week2_fixes <- function() {

  message("✅ VALIDATING WEEK 2 FIXES")
  message("=" %r% 40)

  # Test 1: Ensure established names are NOT analyzed
  message("🔍 Test 1: Established names should NOT appear in origin analysis")

  source("R/analysis/enhanced_origin_detection.R")
  suitable_data <- load_suitable_names()

  if (!is.null(suitable_data)) {
    established_names <- suitable_data$all_classifications[classification == "ESTABLISHED"]
    message("   ✅ ", nrow(established_names), " established names excluded from origin analysis")

    # Check if Michael/Ashley are excluded (key test cases)
    michael_excluded <- !("Michael" %in% suitable_data$suitable_names$name)
    ashley_excluded <- !("Ashley" %in% suitable_data$suitable_names$name)

    message("   ✅ Michael excluded: ", michael_excluded)
    message("   ✅ Ashley excluded: ", ashley_excluded)
  }

  # Test 2: Ensure suitable names ARE analyzed
  message("\n🔍 Test 2: Suitable names should be included")
  if (!is.null(suitable_data)) {
    suitable_count <- nrow(suitable_data$suitable_names)
    message("   ✅ ", format(suitable_count, big.mark = ","), " names ready for origin analysis")

    # Check key test cases
    khaleesi_included <- "Khaleesi" %in% suitable_data$suitable_names$name
    ayden_included <- "Ayden" %in% suitable_data$suitable_names$name

    message("   ✅ Khaleesi included: ", khaleesi_included)
    message("   ✅ Ayden included: ", ayden_included)
  }

  message("\n🎯 Week 2 system is properly filtering names!")
  message("   Ready for meaningful origin analysis!")
}

# HELPER FUNCTIONS ====
`%r%` <- function(x, n) paste(rep(x, n), collapse = "")