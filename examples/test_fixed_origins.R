# TEST FIXED ORIGIN DETECTION SYSTEM
# Week 2 - Fixed version with improved confidence scoring

# Load the improved system
message("🚀 Loading Fixed Week 2 Origin Detection System...")
source("R/interface/simple_origin_analysis.R")

# Test 1: Ayden with improved algorithm
message("\n" %r% 60)
message("TEST 1: Ayden Origin (Improved Algorithm)")
message("" %r% 60)

analyze_name_origin_simple("Ayden", "M")

# Test 2: Khaleesi (should show CA 2011 with better confidence)
message("\n" %r% 60)
message("TEST 2: Khaleesi Origin (Game of Thrones)")
message("" %r% 60)

analyze_name_origin_simple("Khaleesi", "F")

# Test 3: Compare Aiden variants without hanging visualization
message("\n" %r% 60)
message("TEST 3: Aiden Variants Comparison (Fixed)")
message("" %r% 60)

compare_origins_simple("Aiden", "Ayden", "Jayden", sex = "M")

# Test 4: Quick batch analysis
message("\n" %r% 60)
message("TEST 4: Quick Batch Analysis")
message("" %r% 60)

quick_batch_analysis()

# Helper
`%r%` <- function(x, n) paste(rep(x, n), collapse = "")