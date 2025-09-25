# DEBUG DATA LOADING ISSUES
# Simple test to see what's happening with the classification data

message("🔍 DEBUGGING DATA LOADING ISSUES")
message("=" %r% 50)

# Step 1: Test basic data loading
message("Step 1: Loading classification data...")
source("R/analysis/enhanced_origin_detection.R")

tryCatch({
  suitable_data <- load_suitable_names()

  if (!is.null(suitable_data)) {
    message("✅ Data loaded successfully")
    message("📊 Suitable names: ", nrow(suitable_data$suitable_names))

    # Check structure
    message("📋 Column names:", paste(names(suitable_data$suitable_names), collapse = ", "))

    # Test a simple lookup
    message("\nStep 2: Testing Ayden lookup...")
    ayden_data <- suitable_data$suitable_names[suitable_data$suitable_names$name == "Ayden" & suitable_data$suitable_names$sex == "M"]
    message("Found ", nrow(ayden_data), " records for Ayden (M)")

    if (nrow(ayden_data) > 0) {
      message("✅ Ayden found in classifications")
      message("   Classification: ", ayden_data$classification[1])
      message("   Baseline births: ", ayden_data$baseline_total_births[1])
      message("   Modern births: ", ayden_data$modern_total_births[1])
    } else {
      message("❌ Ayden not found")

      # Check what names are similar
      similar_names <- suitable_data$suitable_names[grepl("Ayden|Aiden", suitable_data$suitable_names$name, ignore.case = TRUE)]
      message("Similar names found: ", nrow(similar_names))
      if (nrow(similar_names) > 0) {
        for (i in 1:min(nrow(similar_names), 5)) {
          message("  ", similar_names$name[i], " (", similar_names$sex[i], ")")
        }
      }
    }

  } else {
    message("❌ Failed to load data")
  }

}, error = function(e) {
  message("❌ Error loading data: ", e$message)
})

# Step 3: Test simple quick_analysis loading
message("\nStep 3: Testing quick_analysis function...")
tryCatch({
  source("R/interface/quick_analysis.R")
  data <- quick_setup()

  if (!is.null(data)) {
    message("✅ Quick setup successful")
    message("📊 Total classified names: ", nrow(data$classified_names))

    # Test simple lookup
    test_lookup <- data$classified_names[data$classified_names$name == "Ayden" & data$classified_names$sex == "M"]
    message("Quick lookup found ", nrow(test_lookup), " Ayden records")

  } else {
    message("❌ Quick setup failed")
  }

}, error = function(e) {
  message("❌ Error in quick setup: ", e$message)
})

message("\n✅ Debug complete")

# Helper
`%r%` <- function(x, n) paste(rep(x, n), collapse = "")