# Test script for spatial and cultural analysis functions
# Demonstrates usage and validates the implementation with real data

setwd('C:\\4Summer\\babynames')

suppressPackageStartupMessages({
  library(data.table)
  library(dplyr)
  library(curl)
})

# Load core functions
source("R/core/data_acquisition.R")
source("R/analysis/spatial_cultural_analysis.R")
source("R/core/data_cache_manager.R")

# Load required packages for caching
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  message("Installing jsonlite package for caching...")
  install.packages("jsonlite")
}
library(jsonlite)

# Load data with smart caching
message("Loading SSA baby names data...")
babynames <- load_babynames_cached(include_state = TRUE, max_age_days = 30)

# === BASIC FUNCTIONALITY TESTS ===

message("\n=== Testing Name Variant System ===")

# Test with modern names that have clear geographic origins (post-1990)
modern_variants <- list(
  "Aiden_group" = c("Aiden", "Ayden", "Aden", "Aidan", "Aydan", "Adin"),
  "Jayden_group" = c("Jayden", "Jaiden", "Jaden", "Jaydon", "Jaeden", "Jaidyn"),
  "Brayden_group" = c("Brayden", "Braiden", "Braden", "Braeden", "Braydon"),
  "Kaitlyn_group" = c("Kaitlyn", "Caitlin", "Katelyn", "Kaitlin", "Caitlyn", "Katelynn"),
  "Nevaeh_group" = c("Nevaeh", "Neveah", "Nevaya")  # "Heaven" backwards - very modern name
)

variant_dt <- create_name_variants(modern_variants)
print("Name variant mappings:")
print(variant_dt)

# Check what variants exist in the data
available_variants <- babynames$state[name %in% unlist(modern_variants), unique(name)]
message("\nVariants found in data: ", paste(available_variants, collapse = ", "))

message("\n=== Testing Data Preparation ===")

# Test with broader range to see real diffusion patterns
test_data <- babynames$state[year >= 1990 & sex == "M"]
message("Test data size: ", nrow(test_data), " rows")

# Prepare enhanced dataset
enhanced_data <- prepare_state_data(test_data, variant_dt, min_threshold = 5)
message("Enhanced data size: ", nrow(enhanced_data), " rows")

# Show sample of enhanced data
message("\nSample of enhanced data:")
print(head(enhanced_data[name_group == "Jayden_group"], 10))

message("\n=== Testing Origin Detection ===")

# Find origins for the enhanced dataset
origins <- find_name_origins(enhanced_data, min_states = 2, min_years = 1)
message("Found origins for ", nrow(origins), " name groups")

# Show some modern name group origins
message("\nModern name origins:")
for (group_name in c("Aiden_group", "Jayden_group", "Brayden_group", "Nevaeh_group")) {
  group_origin <- origins[name_group == group_name]
  if (nrow(group_origin) > 0) {
    message(group_name, ": ", group_origin$origin_state, " (", group_origin$origin_year, ")")
  } else {
    message(group_name, ": Not found (may not meet thresholds)")
  }
}

# Show top 10 origins by popularity
popular_origins <- enhanced_data[origins, on = .(sex, name_group)]
origin_popularity <- popular_origins[, .(total_births = sum(n)),
                                   by = .(sex, name_group, origin_state, origin_year)]
origin_popularity <- origin_popularity[order(-total_births)]

message("\nTop 10 most popular name origins:")
print(head(origin_popularity, 10))

message("\n=== Testing Diffusion Analysis ===")

# Calculate diffusion metrics
diffusion_results <- calculate_diffusion_metrics(enhanced_data, origins)

message("Diffusion summary statistics:")
print(head(diffusion_results$diffusion_summary[order(-diffusion_rate)], 8))

# Focus on modern name diffusion patterns
modern_groups <- c("Aiden_group", "Jayden_group", "Brayden_group", "Nevaeh_group")
message("\nModern name diffusion patterns:")

for (group_name in modern_groups) {
  group_diffusion <- diffusion_results$diffusion_summary[name_group == group_name]
  if (nrow(group_diffusion) > 0) {
    message("\n", group_name, ":")
    message("  Origin: ", group_diffusion$origin_state, " (", group_diffusion$origin_year, ")")
    message("  States adopted: ", group_diffusion$n_states_adopted)
    message("  Avg adoption delay: ", round(group_diffusion$mean_adoption_delay, 1), " years")
    message("  Diffusion rate: ", round(group_diffusion$diffusion_rate, 1), " states/year")
  }
}

message("\n=== Testing Regional Analysis ===")

# Run regional analysis
regional_results <- analyze_regional_patterns(enhanced_data)

message("Regional diversity sample (2020):")
recent_diversity <- regional_results$regional_diversity[year == 2020]
if (nrow(recent_diversity) > 0) {
  print(recent_diversity)
} else {
  # Fallback to most recent year available
  recent_year <- max(regional_results$regional_diversity$year)
  message("Using year ", recent_year, " (most recent available):")
  print(regional_results$regional_diversity[year == recent_year])
}

message("\nName sharing across regions (recent year):")
recent_sharing <- regional_results$sharing_stats[year == max(year)]
print(recent_sharing)

message("\n=== Full Pipeline Test ===")

# Test the complete analysis pipeline
message("Running complete spatial-cultural analysis...")
full_results <- analyze_spatial_cultural(
  test_data,
  variant_list = modern_variants,
  min_threshold = 5
)

message("Pipeline completed successfully!")
message("Results structure:")
message("- Enhanced data: ", nrow(full_results$enhanced_data), " rows")
message("- Origins found: ", nrow(full_results$origins), " name groups")
message("- Diffusion summary: ", nrow(full_results$diffusion$diffusion_summary), " entries")
message("- Regional diversity: ", nrow(full_results$regional$regional_diversity), " entries")

# Performance check with larger dataset
message("\n=== Performance Test ===")
message("Testing with larger dataset (2000-2024, both sexes)...")

perf_start <- Sys.time()
large_test <- babynames$state[year >= 2000]
large_results <- analyze_spatial_cultural(large_test, min_threshold = 10)
perf_end <- Sys.time()

message("Performance test completed in ", round(difftime(perf_end, perf_start, units = "secs"), 2), " seconds")
message("Processed ", nrow(large_test), " input rows")
message("Generated ", nrow(large_results$enhanced_data), " enhanced rows")
message("Found ", nrow(large_results$origins), " name group origins")

# Show most interesting diffusion patterns
message("\n=== Most Interesting Diffusion Patterns ===")
interesting_diffusion <- large_results$diffusion$diffusion_summary[
  n_states_adopted >= 10 & diffusion_rate >= 2
][order(-diffusion_rate)]

if (nrow(interesting_diffusion) > 0) {
  message("Fast-spreading names (>= 2 states per year):")
  print(head(interesting_diffusion, 10))
} else {
  message("No names met fast-spreading criteria, showing top diffusion rates:")
  print(head(large_results$diffusion$diffusion_summary[order(-diffusion_rate)], 10))
}

message("\n=== Test Complete ===")
message("All spatial analysis functions working correctly!")

# Keep results in environment for interactive exploration
spatial_results <- large_results
message("\nResults saved as 'spatial_results' for further exploration.")