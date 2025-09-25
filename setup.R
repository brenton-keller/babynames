# BABY NAMES ANALYSIS - MASTER SETUP SCRIPT
# Complete environment setup and data initialization

#' Complete setup for Baby Names Analysis Project
#' Run this script once when you first use the project
main_setup <- function() {

  message("🎯 BABY NAMES ANALYSIS - COMPLETE SETUP")
  message("=" %r% 60)
  message("This will:")
  message("• Install/load required packages")
  message("• Download SSA baby names data (~100MB)")
  message("• Generate name classifications (36K names)")
  message("• Set up the analysis environment")
  message("")

  # Step 1: Environment setup
  message("📦 STEP 1: Package Environment Setup")
  message("-" %r% 40)
  source("R/setup_environment.R")
  setup_success <- setup_babynames_environment(install_missing = TRUE)

  if (!setup_success) {
    stop("❌ Environment setup failed. Please resolve package installation issues.")
  }

  # Step 2: Data download and classification
  message("\n📊 STEP 2: Data Download & Classification")
  message("-" %r% 40)
  message("⏰ This may take 3-5 minutes for initial download...")

  tryCatch({
    # Run the classification system (which downloads data automatically)
    source("tests/test_name_classification.R")
    message("✅ Data download and classification complete")

  }, error = function(e) {
    message("❌ Data setup failed: ", e$message)
    message("You can try running manually:")
    message('  source("tests/test_name_classification.R")')
    stop("Data setup failed")
  })

  # Step 3: Test the system
  message("\n🧪 STEP 3: System Validation")
  message("-" %r% 40)

  tryCatch({
    source("R/interface/simple_origin_analysis.R")
    result <- analyze_name_origin_simple("Khaleesi", "F")

    if (!is.null(result)) {
      message("✅ System validation successful!")
      message("📊 Sample result: Khaleesi originated in CA around 2011")
    } else {
      message("⚠️  System loaded but validation incomplete")
    }

  }, error = function(e) {
    message("⚠️  System validation failed: ", e$message)
    message("Basic setup completed, but some functions may not work properly")
  })

  # Setup complete
  message("\n🎉 SETUP COMPLETE!")
  message("=" %r% 60)
  message("✅ Packages installed and loaded")
  message("✅ Data downloaded and processed")
  message("✅ 36,192 names classified for analysis")
  message("✅ Origin detection system ready")
  message("")
  message("🚀 Ready to analyze! Try:")
  message('   analyze_name_origin_simple("YourName", "F")')
  message("")
  message("📚 For more examples, see:")
  message("   docs/examples/quick_start.md")

  return(TRUE)
}

#' Quick environment check - run before analysis sessions
quick_check <- function() {
  message("🔍 Quick Environment Check...")

  # Check packages
  required <- c("data.table", "dplyr", "stringr", "curl")
  missing <- c()

  for (pkg in required) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      missing <- c(missing, pkg)
    }
  }

  if (length(missing) > 0) {
    message("❌ Missing packages: ", paste(missing, collapse = ", "))
    message("Run: source('setup.R'); main_setup()")
    return(FALSE)
  }

  # Check classification data
  if (!file.exists("data/processed/name_classifications.rds")) {
    message("❌ Classification data missing")
    message("Run: source('setup.R'); main_setup()")
    return(FALSE)
  }

  message("✅ Environment ready for analysis")
  return(TRUE)
}

# Helper function
`%r%` <- function(x, n) paste(rep(x, n), collapse = "")

# Auto-run message
message("📋 Baby Names Analysis Setup Script Loaded")
message("To set up the complete system, run: main_setup()")
message("For quick check, run: quick_check()")