# This script demonstrates a full analysis workflow for baby name diversity
# using the project's core functions.

suppressPackageStartupMessages({
  library(data.table)
})

# --- 1. Setup: Load project functions ---

# Source all necessary functions from the R/ directory
source(file.path("R", "data_acquisition.R"))
source(file.path("R", "analysis_functions.R"))
source(file.path("R", "diversity_metrics.R"))

# --- 2. Data Loading ---

# Load SSA data, caching it in the global environment to avoid re-downloading
message("Loading SSA baby names data...")
babynames <- get_ssa_babynames(include_state = FALSE)

# --- 3. Analysis: Compute and Render the Diversity Story ---

# This script can be run non-interactively (e.g., via Rscript)
# The `if` block below will execute automatically when the script is run.

message("\nComputing diversity story for national data...")

# Use the high-level function to perform all diversity calculations
diversity_story <- compute_diversity_story(babynames$national)

message("Rendering diversity story report...")

# Use the high-level function to print summaries and plots
render_diversity_story(diversity_story)

message("\nAnalysis complete.")

# Keep the result available in the environment if run interactively
invisible(diversity_story)
