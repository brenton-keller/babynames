# TEST AYDEN ORIGIN ANALYSIS
# Week 2 testing script for name origin detection

# LOAD THE WEEK 2 SYSTEM ====
message("Loading Week 2 Origin Detection System...")
source("R/interface/week2_interface.R")

# TEST 1: Validate Week 2 Fixes ====
message("\n" %r% 60)
message("TEST 1: Validating Week 2 System")
message("" %r% 60)

validate_week2_fixes()

# TEST 2: Analyze Ayden Origin ====
message("\n" %r% 60)
message("TEST 2: Ayden Origin Analysis")
message("" %r% 60)

explore_name_origin("Ayden", sex = "M")

# TEST 3: Quick System Test ====
message("\n" %r% 60)
message("TEST 3: System Overview")
message("" %r% 60)

test_week2_system()

# HELPER ====
`%r%` <- function(x, n) paste(rep(x, n), collapse = "")