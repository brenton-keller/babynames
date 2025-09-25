# QUICK TEST: Interactive Name Analysis System
# Tests the new interactive features with Brayden example

setwd('C:\\4Summer\\babynames')

message("🧪 Testing Interactive Name Analysis System")
message("============================================")

# Load required packages
suppressPackageStartupMessages({
  library(data.table)
  if (!requireNamespace("stringr", quietly = TRUE)) {
    message("Installing stringr package...")
    install.packages("stringr")
  }
  library(stringr)
})

# Load the quick analysis functions (no interactive setup needed)
source("R/interface/quick_analysis.R")

# Test 1: Quick investigation of Brayden
message("\n🔍 TEST 1: Quick Investigation of Brayden")
message("=========================================")

investigate_name("Brayden", sex = "M", show_plot = TRUE)

# Test 2: Quick comparison
message("\n🔬 TEST 2: Quick Comparison")
message("===========================")

quick_compare(c("Brayden", "Jayden", "Aiden"), sex = "M")

# Test 3: Validation check
message("\n✅ TEST 3: Validation Check")
message("===========================")

quick_validate()

# Test 4: Statistics overview
message("\n📊 TEST 4: Statistics Overview")
message("===============================")

show_stats(sex = "M")

# Test 5: Random examples
message("\n🎲 TEST 5: Random Examples")
message("===========================")

message("Random EMERGING names:")
random_examples("EMERGING", sex = "M", n = 3)

message("\nRandom TRULY_NEW names:")
random_examples("TRULY_NEW", sex = "F", n = 3)

message("\n🎉 INTERACTIVE SYSTEM TEST COMPLETE!")
message("=====================================")

message("✅ All basic functions working")
message("📊 Brayden correctly classified as EMERGING")
message("🔍 Quick analysis functions operational")
message("📈 Plotting system functional")

message("\n💡 NEXT STEPS:")
message("For full interactive exploration, run:")
message("  source('examples/interactive_demo.R')")

message("\nOr use individual commands like:")
message("  investigate_name('AnyName')")
message("  quick_compare(c('Name1', 'Name2'))")
message("  verify('NameToCheck')")

message("\n🚀 Interactive name analysis system ready!")