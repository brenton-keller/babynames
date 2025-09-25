# FIX OLIVER CLASSIFICATION ISSUE
# Regenerate classifications with expanded established names list

message("🔧 FIXING OLIVER CLASSIFICATION ISSUE")
message("=" %r% 50)

# Step 1: Clear old classification cache
message("Step 1: Clearing old classification cache...")
if (file.exists("data/processed/name_classifications.rds")) {
  file.remove("data/processed/name_classifications.rds")
  message("✅ Old classification cache cleared")
}

# Step 2: Regenerate classifications with updated established names list
message("\nStep 2: Regenerating classifications...")
source("tests/test_name_classification.R")
message("✅ Classifications regenerated")

# Step 3: Test Oliver specifically
message("\nStep 3: Testing Oliver classification...")
source("R/interface/quick_analysis.R")
result <- investigate_name("Oliver", "M", show_plot = FALSE)

if (!is.null(result)) {
  oliver_class <- result[sex == "M"]$classification[1]
  message("📊 Oliver (M) classification: ", oliver_class)

  if (oliver_class == "ESTABLISHED") {
    message("✅ FIXED: Oliver is now correctly classified as ESTABLISHED")
  } else {
    message("❌ ISSUE PERSISTS: Oliver still classified as ", oliver_class)
  }
} else {
  message("❌ Could not retrieve Oliver classification")
}

# Step 4: Test the simple origin analysis
message("\nStep 4: Testing simple origin analysis...")
source("R/interface/simple_origin_analysis.R")

tryCatch({
  analyze_name_origin_simple("Oliver", "M")
}, error = function(e) {
  message("❌ Error in analysis: ", e$message)
})

message("\n✅ Fix attempt complete")

# Helper function
`%r%` <- function(x, n) paste(rep(x, n), collapse = "")