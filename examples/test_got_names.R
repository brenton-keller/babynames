# TEST: Game of Thrones Names Analysis
setwd('C:\\4Summer\\babynames')

suppressPackageStartupMessages({
  library(data.table)
  library(stringr)
})

source("R/interface/quick_analysis.R")
source("R/interface/pop_culture_analysis.R")

message("🐉 Testing Game of Thrones Names")
message("================================")

# Test 1: Individual investigations
message("\n🔍 Individual Name Analysis:")
investigate_name("Khaleesi", sex = "F", show_plot = FALSE)
investigate_name("Daenerys", sex = "F", show_plot = FALSE)

# Test 2: Fixed comparison (should work now)
message("\n🔬 Comparison Test:")
quick_compare("Khaleesi", "Daenerys", sex = "F")

# Test 3: Alternative syntax
message("\n🔬 Alternative Comparison Syntax:")
quick_compare(c("Khaleesi", "Daenerys"), sex = "F")

# Test 4: Pop culture analysis
message("\n🎬 Pop Culture Analysis:")
analyze_got_names()

message("\n✅ Game of Thrones analysis complete!")
message("These names are perfect examples of TRULY_NEW names with clear cultural origins.")