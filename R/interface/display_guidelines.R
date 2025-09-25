# DISPLAY GUIDELINES AND UTILITIES
# Common sense rules for showing data without overwhelming users

# CORE PRINCIPLES ====
#
# 1. NEVER show more than 10-15 rows of tabular data
# 2. ALWAYS limit massive results with "showing first X" messages
# 3. Provide guidance on how to narrow results
# 4. Use summary statistics instead of raw dumps
# 5. Give users control over detail level

# DISPLAY LIMITS ====

MAX_TABLE_ROWS <- 10
MAX_COMPARISON_ROWS <- 8
MAX_SUGGESTIONS <- 8
MAX_EXAMPLES <- 5
MAX_SIMILAR_NAMES <- 5

# UTILITY FUNCTIONS ====

#' Smart data display with automatic limiting
#' @param data data.table to display
#' @param max_rows Maximum rows to show
#' @param context Description of what's being shown
smart_display <- function(data, max_rows = MAX_TABLE_ROWS, context = "results") {

  if (nrow(data) == 0) {
    message("❌ No ", context, " found")
    return(invisible(NULL))
  }

  if (nrow(data) <= max_rows) {
    # Show all data
    return(data)
  } else {
    # Show limited data with warning
    message("⚠️ Found ", nrow(data), " ", context, " - showing first ", max_rows, " only")
    limited_data <- head(data, max_rows)

    # Add truncation message after display
    message("... (", nrow(data) - max_rows, " more ", context, " not shown)")
    message("💡 Use more specific search terms to narrow results")

    return(limited_data)
  }
}

#' Format large numbers for display
#' @param x Numeric value
format_number <- function(x) {
  if (is.na(x) || !is.numeric(x)) return("--")
  format(x, big.mark = ",", scientific = FALSE)
}

#' Format growth ratios sensibly
#' @param ratio Growth ratio value
format_growth <- function(ratio) {
  if (is.na(ratio) || !is.finite(ratio)) return("NEW")
  if (ratio == Inf) return("NEW")
  if (ratio == 0) return("0x")
  paste0(round(ratio, 1), "x")
}

#' Show summary instead of full data
#' @param data Data to summarize
#' @param group_col Column to group by
show_summary <- function(data, group_col = "classification") {

  if (nrow(data) == 0) {
    message("❌ No data to summarize")
    return(invisible(NULL))
  }

  # Create summary by group
  if (group_col %in% names(data)) {
    summary_data <- data[, .N, by = get(group_col)][order(-N)]
    setnames(summary_data, c("get", "N"), c(group_col, "count"))

    message("📊 Summary by ", group_col, ":")
    for (i in 1:min(nrow(summary_data), 8)) {  # Max 8 categories
      message("  ", summary_data[i, get(group_col)], ": ", format_number(summary_data[i, count]))
    }

    if (nrow(summary_data) > 8) {
      message("  ... (", nrow(summary_data) - 8, " more categories)")
    }

  } else {
    message("📊 Total records: ", format_number(nrow(data)))
  }

  invisible(summary_data)
}

# VALIDATION FUNCTIONS ====

#' Check if output would be too large
#' @param data Data to check
#' @param threshold Maximum acceptable size
is_output_too_large <- function(data, threshold = MAX_TABLE_ROWS) {
  nrow(data) > threshold
}

#' Warn about large output and suggest alternatives
suggest_alternatives <- function(data_size, context = "results") {
  if (data_size > 50) {
    message("⚠️ Large dataset (", data_size, " ", context, ") - consider:")
    message("  • Use more specific search terms")
    message("  • Filter by classification type")
    message("  • Use summary functions instead")
  } else if (data_size > MAX_TABLE_ROWS) {
    message("💡 Tip: Use more specific search for focused results")
  }
}

# EXAMPLE USAGE ====
#
# Instead of:
#   print(huge_data_table)  # BAD - might print thousands of rows
#
# Use:
#   display_data <- smart_display(huge_data_table, max_rows = 10, context = "name matches")
#   # Shows only first 10 with clear messaging
#
# Or for summaries:
#   show_summary(huge_data_table, "classification")
#   # Shows counts by category instead of raw data