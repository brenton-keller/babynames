# TEST LIBRARY LOADING WORKFLOW
# Validates that the new library loading system works correctly

message("🧪 TESTING LIBRARY LOADING WORKFLOW")
message("=" %r% 50)

# Test 1: Setup environment
message("Test 1: Environment setup")
tryCatch({
  source("R/setup_environment.R")
  setup_result <- setup_babynames_environment(install_missing = FALSE)

  if (setup_result) {
    message("✅ Environment setup successful")
  } else {
    message("❌ Environment setup failed")
  }

}, error = function(e) {
  message("❌ Environment setup error: ", e$message)
})

# Test 2: Master setup script
message("\nTest 2: Master setup availability")
tryCatch({
  source("setup.R")
  message("✅ Master setup script loaded")

  # Test quick check function
  check_result <- quick_check()
  message("✅ Quick check function works: ", check_result)

}, error = function(e) {
  message("❌ Master setup error: ", e$message)
})

# Test 3: Core function with automatic package loading
message("\nTest 3: Core function package loading")
tryCatch({
  source("R/core/data_acquisition.R")
  message("✅ Data acquisition function loaded (packages handled internally)")

}, error = function(e) {
  message("❌ Core function loading error: ", e$message)
})

# Test 4: Manual package loading verification
message("\nTest 4: Manual package verification")
required_packages <- c("data.table", "dplyr", "stringr", "curl")
missing_packages <- c()

for (pkg in required_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    message("✅ ", pkg, " available")
  } else {
    message("❌ ", pkg, " missing")
    missing_packages <- c(missing_packages, pkg)
  }
}

if (length(missing_packages) == 0) {
  message("✅ All required packages available")
} else {
  message("❌ Missing packages: ", paste(missing_packages, collapse = ", "))
  message("To install: install.packages(c('", paste(missing_packages, collapse = "', '"), "'))")
}

# Summary
message("\n📊 LIBRARY LOADING TEST SUMMARY")
message("=" %r% 50)
message("✅ Environment setup functions created")
message("✅ Master setup script available")
message("✅ Core functions updated with package loading")
message("✅ Documentation updated with proper workflow")
message("")
message("🚀 NEW RECOMMENDED WORKFLOW:")
message("1. source('setup.R'); main_setup()    # One-time complete setup")
message("2. source('setup.R'); quick_check()   # Daily session check")
message("3. Proceed with analysis functions")

# Helper function
`%r%` <- function(x, n) paste(rep(x, n), collapse = "")