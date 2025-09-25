# POP CULTURE NAME ANALYSIS
# Special analysis for names that emerged from media/cultural events

# KNOWN POP CULTURE NAME GROUPS ====

POP_CULTURE_NAMES <- list(
  game_of_thrones = list(
    names = c("Khaleesi", "Daenerys", "Arya", "Tyrion", "Sansa"),
    debut_year = 2011,  # TV show started
    description = "Game of Thrones character names",
    expected_pattern = "Sharp spike after 2011"
  ),

  twilight = list(
    names = c("Bella", "Edward", "Emmett", "Jasper", "Cullen"),
    debut_year = 2008,  # Movie series started
    description = "Twilight character names",
    expected_pattern = "Growth around 2008-2012"
  ),

  disney_modern = list(
    names = c("Elsa", "Anna", "Moana", "Rapunzel"),
    debut_year = 2010,  # Frozen era
    description = "Modern Disney princess names",
    expected_pattern = "Spikes after movie releases"
  )
)

# ANALYSIS FUNCTIONS ====

#' Analyze a pop culture name group
#' @param group_name Name of the pop culture group to analyze
#' @param show_plots Whether to create visualizations
analyze_pop_culture_group <- function(group_name, show_plots = TRUE) {

  if (!group_name %in% names(POP_CULTURE_NAMES)) {
    message("❌ Unknown pop culture group. Available: ", paste(names(POP_CULTURE_NAMES), collapse = ", "))
    return(invisible(NULL))
  }

  group_info <- POP_CULTURE_NAMES[[group_name]]

  message("🎬 ANALYZING POP CULTURE GROUP: ", toupper(group_name))
  message(paste(rep("=", 50), collapse = ""))
  message("📺 ", group_info$description)
  message("🗓️ Debut year: ", group_info$debut_year)
  message("📈 Expected pattern: ", group_info$expected_pattern)
  message("")

  # Analyze each name in the group
  source("R/interface/quick_analysis.R")

  for (name in group_info$names) {
    message("🔍 ", name, ":")

    # Quick investigation without plot to save space
    result <- investigate_name(name, sex = "both", show_plot = FALSE)

    if (!is.null(result)) {
      # Check if pattern matches expectation
      validate_pop_culture_pattern(result, group_info, name)
    }

    message("")
  }

  if (show_plots) {
    plot_pop_culture_group(group_info$names, group_info$debut_year)
  }

  message("✅ Pop culture analysis complete for ", group_name)
}

#' Validate if name follows expected pop culture pattern
validate_pop_culture_pattern <- function(name_data, group_info, name) {

  # Check if name shows expected emergence pattern
  for (i in 1:nrow(name_data)) {
    data_row <- name_data[i]

    # Expected patterns for pop culture names
    is_truly_new <- data_row$classification == "TRULY_NEW"
    has_modern_births <- data_row$modern_total_births > 0
    debut_year <- group_info$debut_year

    pattern_match <- FALSE

    if (is_truly_new && has_modern_births) {
      # Check if timing makes sense
      # For Game of Thrones (2011), expect emergence around 2011-2015
      expected_emergence <- (data_row$modern_first_year >= debut_year - 2) &&
                           (data_row$modern_first_year <= debut_year + 5)

      if (expected_emergence) {
        pattern_match <- TRUE
        message("  ✅ Pattern matches: Emerged around ", data_row$modern_first_year,
               " (expected after ", debut_year, ")")
      }
    }

    if (!pattern_match) {
      message("  ⚠️ Pattern unusual for pop culture name")
    }
  }
}

#' Plot pop culture name group together
plot_pop_culture_group <- function(names, debut_year) {

  message("📊 Creating pop culture group plot...")

  # Use quick_plot_name instead of the interactive plot_comparison
  source("R/core/data_cache_manager.R")
  full_data <- load_babynames_cached(include_state = FALSE)

  if (is.null(full_data)) {
    message("❌ Cannot load data for plotting")
    return(invisible(NULL))
  }

  # Create simple comparison plot
  plot_data <- full_data$national[name %in% names & sex == "F" & year >= 2000 & year <= 2024]

  if (nrow(plot_data) == 0) {
    message("❌ No data found for plotting these names")
    return(invisible(NULL))
  }

  # Color palette
  colors <- c("red", "blue", "green", "purple", "orange")

  # Find plot bounds
  x_range <- range(plot_data$year)
  y_range <- range(plot_data$n)

  # Create plot
  plot(x_range, y_range, type = "n",
       main = "Game of Thrones Names Emergence",
       xlab = "Year", ylab = "Annual Births", las = 1)

  # Plot each name
  for (i in seq_along(names)) {
    name_data <- plot_data[name == names[i]]
    if (nrow(name_data) > 0) {
      lines(name_data$year, name_data$n, col = colors[i], lwd = 2)
      points(name_data$year, name_data$n, col = colors[i], pch = 16, cex = 0.4)
    }
  }

  # Add debut year line
  abline(v = debut_year, col = "black", lwd = 3, lty = 2)
  text(debut_year + 1, max(y_range) * 0.9, paste("GoT Debut:", debut_year), col = "black", cex = 0.8)

  # Add legend
  legend("topright", legend = names, col = colors[1:length(names)], lwd = 2, cex = 0.8)

  message("✅ Plot created successfully!")
}

# GAME OF THRONES SPECIFIC ANALYSIS ====

#' Quick Game of Thrones names analysis
analyze_got_names <- function() {
  message("🐉 GAME OF THRONES NAMES ANALYSIS")
  message("=================================")

  analyze_pop_culture_group("game_of_thrones", show_plots = TRUE)

  # Additional insights
  message("\n💡 INSIGHTS:")
  message("• Khaleesi: Title meaning 'Queen' in Dothraki")
  message("• Daenerys: Character's actual name")
  message("• Both should show emergence after 2011 TV debut")
  message("• Likely geographic clustering in areas with higher TV viewership")
}

# CONVENIENCE FUNCTIONS ====

#' Quick comparison of Game of Thrones names
got_compare <- function() {
  quick_compare("Khaleesi", "Daenerys", "Arya", sex = "F")
}

#' Investigate specific Game of Thrones name
got_investigate <- function(name) {
  investigate_name(name, sex = "F", show_plot = TRUE)
}