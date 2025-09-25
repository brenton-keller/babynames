# PACKAGE SETUP FOR BABY NAMES ANALYSIS
# Load all required packages with proper error handling

#' Setup the analysis environment with all required packages
#' @param install_missing Automatically install missing packages
#' @return TRUE if successful, FALSE otherwise
setup_babynames_environment <- function(install_missing = TRUE) {

  message("🚀 Setting up Baby Names Analysis Environment")
  message("=" %r% 50)

  # Required packages
  required_packages <- c(
    "data.table",    # Fast data manipulation
    "dplyr",         # Data processing
    "stringr",       # String operations
    "curl"           # Data download
  )

  # Optional packages (for enhanced features)
  optional_packages <- c(
    "scales"         # Plot formatting
  )

  # Check and load required packages
  missing_packages <- c()

  for (pkg in required_packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      missing_packages <- c(missing_packages, pkg)
    } else {
      message("✅ ", pkg, " loaded successfully")
    }
  }

  # Handle missing packages
  if (length(missing_packages) > 0) {
    message("❌ Missing required packages: ", paste(missing_packages, collapse = ", "))

    if (install_missing) {
      message("📦 Installing missing packages...")
      tryCatch({
        install.packages(missing_packages)

        # Try loading again
        for (pkg in missing_packages) {
          if (require(pkg, character.only = TRUE, quietly = TRUE)) {
            message("✅ ", pkg, " installed and loaded")
          } else {
            message("❌ Failed to load ", pkg, " after installation")
            return(FALSE)
          }
        }
      }, error = function(e) {
        message("❌ Installation failed: ", e$message)
        message("Please install manually: install.packages(c('", paste(missing_packages, collapse = "', '"), "'))")
        return(FALSE)
      })
    } else {
      message("Please install missing packages:")
      message("install.packages(c('", paste(missing_packages, collapse = "', '"), "'))")
      return(FALSE)
    }
  }

  # Load optional packages (don't fail if missing)
  for (pkg in optional_packages) {
    if (require(pkg, character.only = TRUE, quietly = TRUE)) {
      message("✅ ", pkg, " (optional) loaded")
    } else {
      message("ℹ️  ", pkg, " (optional) not available")
    }
  }

  message("✅ Environment setup complete!")
  message("📊 Ready for baby names analysis")

  # Test core functionality
  tryCatch({
    # Test data.table
    test_dt <- data.table(x = 1:3, y = letters[1:3])
    # Test dplyr
    test_df <- data.frame(a = 1:3) %>% mutate(b = a * 2)
    # Test stringr
    test_str <- str_to_title("test string")

    message("🧪 Core functionality verified")
    return(TRUE)

  }, error = function(e) {
    message("❌ Functionality test failed: ", e$message)
    return(FALSE)
  })
}

#' Quick setup - loads packages without prompts
quick_setup <- function() {
  suppressMessages(setup_babynames_environment(install_missing = FALSE))
}

# Helper function
`%r%` <- function(x, n) paste(rep(x, n), collapse = "")