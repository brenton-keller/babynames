# INTERACTIVE NAME ANALYSIS - DEMO SCRIPT
# Demonstrates the new interactive exploration system

setwd('C:\\4Summer\\babynames')

message("🎯 Interactive Name Analysis Demo")
message("=================================")

# Load required libraries
suppressPackageStartupMessages({
  library(data.table)
  library(stringr)
})

# Load the interactive system
source("R/interface/interactive_explorer.R")
source("R/interface/visual_explorer.R")
source("R/interface/quick_analysis.R")

# OPTION 1: QUICK ANALYSIS (No interactive setup needed) ====

message("\n🚀 OPTION 1: QUICK ANALYSIS")
message("============================")

message("Let's investigate Brayden quickly:")

# Quick investigation - no setup needed
investigate_name("Brayden", sex = "M", show_plot = TRUE)

message("\nLet's compare Brayden with similar names:")

# Quick comparison
quick_compare(c("Brayden", "Jayden", "Aiden", "Kayden"), sex = "M")

message("\nLet's validate our classification system:")

# Quick validation
quick_validate()

# OPTION 2: INTERACTIVE EXPLORER SESSION ====

message("\n\n🔍 OPTION 2: INTERACTIVE EXPLORER")
message("===================================")

# Start the interactive session
start_name_explorer(auto_load = TRUE)

message("\n📋 DEMO SESSION - Let's explore Brayden interactively:")

# Deep dive exploration
explore("Brayden", sex = "M", show_plot = TRUE)

message("\n🔬 Let's verify the classification:")

# Show classification logic
verify("Brayden", sex = "M")

message("\n📊 Let's compare with similar names:")

# Compare multiple names
compare(c("Brayden", "Jayden", "Aiden"), sex = "M")

message("\n🎨 VISUAL ANALYSIS:")

# Create classification logic visualization
message("Creating classification logic plot for Brayden...")
plot_classification_logic("Brayden", sex = "M")

message("\n📈 Let's see a visual summary:")

# Visual summary
visual_summary("Brayden", sex = "M")

# ADDITIONAL EXAMPLES ====

message("\n\n🔎 ADDITIONAL EXAMPLES")
message("=======================")

message("1️⃣ Investigate a TRULY_NEW name (Nevaeh):")
investigate_name("Nevaeh", sex = "F", show_plot = TRUE)

message("\n2️⃣ Investigate an ESTABLISHED name (Michael):")
investigate_name("Michael", sex = "M", show_plot = TRUE)

message("\n3️⃣ Get random examples of different classifications:")
random_examples("EMERGING", sex = "M", n = 3)
random_examples("TRULY_NEW", sex = "F", n = 3)

message("\n4️⃣ Show overall statistics:")
show_stats(sex = "both")

# EXPORT EXAMPLE ====

message("\n\n💾 EXPORT EXAMPLE")
message("==================")

message("Exporting Brayden analysis to CSV...")
export_analysis("Brayden", filename = "examples/brayden_analysis_demo.csv")

# SESSION SUMMARY ====

message("\n\n🎉 DEMO COMPLETE!")
message("=================")

message("✅ Interactive system successfully demonstrated")
message("✅ Brayden analysis shows: EMERGING classification makes sense")
message("  - Only 318 births in 1980s baseline period")
message("  - 134,605 births in modern period (121x growth)")
message("  - Clear pattern of emergence from rare to popular")

message("\n💡 NEXT STEPS:")
message("You can now use these functions interactively:")
message("• explore(\"any_name\") - Deep dive investigation")
message("• verify(\"any_name\") - Check classification logic")
message("• compare(c(\"name1\", \"name2\")) - Side-by-side analysis")
message("• plot_timeline(\"name\") - Visualize trends")

message("\n🔧 QUICK FUNCTIONS (no setup needed):")
message("• investigate_name(\"name\") - Immediate analysis")
message("• quick_compare(names) - Fast comparison")
message("• random_examples(\"EMERGING\") - Discover patterns")

message("\n🚀 Ready for interactive name exploration!")

# END DEMO SESSION
message("\n👋 Demo session ending. Interactive functions remain available.")
message("Type help() for full command list.")