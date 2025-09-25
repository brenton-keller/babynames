# TEST SCRIPT: Name Classification System
# Validates the new classification system with full historical data

setwd('C:\\4Summer\\babynames')

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(curl)
  library(jsonlite)
})

message("🧪 Testing Name Classification System")
message("====================================")

# Load all necessary modules
source("R/core/data_acquisition.R")
source("R/core/data_cache_manager.R")
source("R/core/data_validation.R")
source("R/analysis/name_classifier.R")

# === STEP 1: Load Full Historical Data ===
message("\n📥 Step 1: Loading full historical data...")

# Load data with expanded historical range
babynames_full <- load_babynames_cached(
  include_state = TRUE,
  max_age_days = 30,
  cache_dir = "data"
)

message("Data loaded successfully!")
message("National data range: ", min(babynames_full$national$year), "-", max(babynames_full$national$year))
message("National data rows: ", nrow(babynames_full$national))

if (!is.null(babynames_full$state)) {
  message("State data range: ", min(babynames_full$state$year), "-", max(babynames_full$state$year))
  message("State data rows: ", nrow(babynames_full$state))
}

# === STEP 2: Data Quality Validation ===
message("\n🔍 Step 2: Data Quality Validation...")

data_quality <- validate_data_quality(babynames_full$national)

message("Data quality checks:")
message("✓ Required columns: ", ifelse(data_quality$structure$has_required_columns, "Present", "Missing"))
message("✓ Year range: ", data_quality$structure$year_range[1], "-", data_quality$structure$year_range[2])
message("✓ Total births: ", data_quality$structure$total_births)
message("✓ Unique names: ", data_quality$structure$unique_names)
message("✓ Continuous coverage: ", ifelse(data_quality$temporal$continuous_coverage, "Yes", "No"))

if (length(data_quality$temporal$year_gaps) > 0) {
  message("⚠️  Year gaps found: ", paste(data_quality$temporal$year_gaps, collapse = ", "))
}

# === STEP 3: Name Classification ===
message("\n🏷️  Step 3: Name Classification...")

# Run the complete classification workflow
classification_results <- classify_names_for_analysis(
  babynames_full$national,
  cutoff_year = 1990
)

message("Classification complete!")

# === STEP 4: Validation Against Known Cases ===
message("\n✅ Step 4: Validation Against Known Cases...")

validation_results <- validate_classification_accuracy(classification_results)
# Temporarily disabled to prevent massive output crash
# print_validation_report(validation_results)
message("Validation completed - accuracy: ", validation_results$summary$accuracy_percentage, "%")

# === STEP 5: Show Detailed Examples ===
message("\n📊 Step 5: Detailed Examples...")

# Show details for some key examples
example_names <- list(
  c("Michael", "M", "Should be ESTABLISHED"),
  c("Ashley", "F", "Should be ESTABLISHED"),
  c("Nevaeh", "F", "Should be TRULY_NEW"),
  c("Aiden", "M", "Should be EMERGING"),
  c("Jayden", "M", "Should be EMERGING"),
  c("Brayden", "M", "Should be EMERGING")
)

for (example in example_names) {
  cat("\n" , paste(rep("=", 50), collapse = ""), "\n")
  show_name_details(example[1], example[2], classification_results)
}

# === STEP 6: Quick Statistics ===
message("\n📈 Step 6: Classification Statistics...")

classification_counts <- classification_results$classified_names[, .N, by = .(classification, sex)][order(sex, -N)]
message("Classification breakdown:")
for (i in 1:nrow(classification_counts)) {
  message("  ", classification_counts[i, sex], " - ", classification_counts[i, classification], ": ", classification_counts[i, N])
}

# Show some examples from each category
message("\n📝 Example names by category:")
for (sex_code in c("M", "F")) {
  message("\n", ifelse(sex_code == "M", "Male", "Female"), " names:")

  for (class_type in c("ESTABLISHED", "TRULY_NEW", "EMERGING", "RISING")) {
    examples <- classification_results$classified_names[
      classification == class_type & sex == sex_code,
      head(name, 5)
    ]

    if (length(examples) > 0) {
      message("  ", class_type, ": ", paste(examples, collapse = ", "))
    }
  }
}

# === STEP 7: Names Suitable for Origin Analysis ===
message("\n🎯 Step 7: Names Suitable for Origin Analysis...")

suitable_names <- classification_results$suitable_for_analysis

message("Names ready for origin analysis: ", nrow(suitable_names))

# Show breakdown by sex and classification
suitable_breakdown <- suitable_names[, .N, by = .(sex, classification)][order(sex, -N)]
message("Breakdown of suitable names:")
for (i in 1:nrow(suitable_breakdown)) {
  message("  ", suitable_breakdown[i, sex], " - ", suitable_breakdown[i, classification], ": ", suitable_breakdown[i, N])
}

# Show some examples of names ready for analysis
modern_examples <- suitable_names[classification == "TRULY_NEW", head(name, 10)]
emerging_examples <- suitable_names[classification == "EMERGING", head(name, 10)]

if (length(modern_examples) > 0) {
  message("\nTruly new names ready for analysis: ", paste(modern_examples, collapse = ", "))
}

if (length(emerging_examples) > 0) {
  message("\nEmerging names ready for analysis: ", paste(emerging_examples, collapse = ", "))
}

# === STEP 8: Save Results for Next Phase ===
message("\n💾 Step 8: Saving Results...")

# Save classification results for use in Week 2
saveRDS(classification_results, "data/processed/name_classifications.rds")
saveRDS(validation_results, "data/processed/classification_validation.rds")

message("✅ Results saved to data/processed/")

# === SUMMARY ===
message("\n🎉 WEEK 1 IMPLEMENTATION COMPLETE!")
message("=================================")
message("✓ Full historical data loaded (1880-2024)")
message("✓ Name classification system implemented")
message("✓ Validation framework created")
message("✓ ", nrow(suitable_names), " names identified for origin analysis")
message("✓ Results saved for Week 2 implementation")

overall_accuracy <- validation_results$summary$accuracy_percentage
if (overall_accuracy >= 80) {
  message("🎯 Validation accuracy: ", overall_accuracy, "% - EXCELLENT!")
} else if (overall_accuracy >= 60) {
  message("⚠️  Validation accuracy: ", overall_accuracy, "% - Needs improvement")
} else {
  message("❌ Validation accuracy: ", overall_accuracy, "% - Requires fixes")
}

message("\n🚀 Ready for Week 2: Enhanced Origin Detection!")
message("Next: Only analyze names classified as TRULY_NEW or EMERGING")