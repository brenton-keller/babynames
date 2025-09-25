# DATA CACHE MANAGEMENT SYSTEM
# Handles smart downloading, caching, and validation of SSA baby names data

# CACHE DIRECTORY SETUP ====

#' Set up cache directory structure
#' @param cache_dir Base directory for cached data (default: data/)
#' @return Path to cache directory
setup_cache_directory <- function(cache_dir = "data") {

  # Create directory structure
  raw_dir <- file.path(cache_dir, "raw")
  processed_dir <- file.path(cache_dir, "processed")
  cache_results_dir <- file.path(cache_dir, "cache")

  dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(processed_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(cache_results_dir, recursive = TRUE, showWarnings = FALSE)

  cache_dir
}

#' Check if cached data exists and is fresh
#' @param cache_dir Cache directory path
#' @param max_age_days Maximum age in days before data is considered stale
#' @return List with existence and freshness info
check_cache_status <- function(cache_dir = "data", max_age_days = 30) {

  national_file <- file.path(cache_dir, "raw", "national_data.rds")
  state_file <- file.path(cache_dir, "raw", "state_data.rds")
  metadata_file <- file.path(cache_dir, "raw", "download_metadata.json")

  # Check if files exist
  national_exists <- file.exists(national_file)
  state_exists <- file.exists(state_file)
  metadata_exists <- file.exists(metadata_file)

  # Check freshness if metadata exists
  fresh <- FALSE
  last_download <- NULL

  if (metadata_exists) {
    tryCatch({
      metadata <- jsonlite::fromJSON(metadata_file)
      last_download <- as.Date(metadata$download_date)
      days_old <- as.numeric(Sys.Date() - last_download)
      fresh <- days_old <= max_age_days
    }, error = function(e) {
      fresh <<- FALSE
    })
  }

  list(
    national_exists = national_exists,
    state_exists = state_exists,
    metadata_exists = metadata_exists,
    data_fresh = fresh,
    last_download = last_download,
    cache_dir = cache_dir
  )
}

# SMART DATA LOADING ====

#' Load babynames data with smart caching
#' @param cache_dir Cache directory path
#' @param include_state Whether to include state-level data
#' @param force_refresh Force re-download even if cache exists
#' @param max_age_days Maximum cache age before refresh
#' @return List with national and optionally state data
load_babynames_cached <- function(cache_dir = "data",
                                  include_state = TRUE,
                                  force_refresh = FALSE,
                                  max_age_days = 30) {

  # Ensure cache directory exists
  setup_cache_directory(cache_dir)

  # Check cache status
  cache_status <- check_cache_status(cache_dir, max_age_days)

  national_file <- file.path(cache_dir, "raw", "national_data.rds")
  state_file <- file.path(cache_dir, "raw", "state_data.rds")
  metadata_file <- file.path(cache_dir, "raw", "download_metadata.json")

  # Determine if we need to download
  need_download <- force_refresh ||
                   !cache_status$national_exists ||
                   (include_state && !cache_status$state_exists) ||
                   !cache_status$data_fresh

  if (need_download) {
    message("📥 Downloading fresh data from SSA...")

    # Load the original data acquisition function
    if (!exists("get_ssa_babynames")) {
      source("R/data_acquisition.R")
    }

    # Download fresh data
    start_time <- Sys.time()
    babynames <- get_ssa_babynames(include_state = include_state)
    download_time <- difftime(Sys.time(), start_time, units = "secs")

    # Save to cache
    message("💾 Caching data for future use...")
    saveRDS(babynames$national, national_file)

    if (include_state && !is.null(babynames$state)) {
      saveRDS(babynames$state, state_file)
    }

    # Save metadata
    metadata <- list(
      download_date = as.character(Sys.Date()),
      download_time_seconds = as.numeric(download_time),
      national_rows = nrow(babynames$national),
      state_rows = if (include_state && !is.null(babynames$state)) nrow(babynames$state) else 0,
      include_state = include_state,
      r_version = R.version.string,
      package_versions = list(
        data.table = as.character(packageVersion("data.table")),
        curl = as.character(packageVersion("curl"))
      )
    )

    jsonlite::write_json(metadata, metadata_file, pretty = TRUE)

    message("✅ Data cached successfully!")
    message("📊 National data: ", nrow(babynames$national), " rows")
    if (include_state && !is.null(babynames$state)) {
      message("📊 State data: ", nrow(babynames$state), " rows")
    }

    return(babynames)

  } else {
    # Load from cache
    message("⚡ Loading data from cache...")
    message("📅 Last downloaded: ", cache_status$last_download)

    start_time <- Sys.time()

    national_data <- readRDS(national_file)
    state_data <- NULL

    if (include_state && cache_status$state_exists) {
      state_data <- readRDS(state_file)
    }

    load_time <- difftime(Sys.time(), start_time, units = "secs")

    message("✅ Cache loaded in ", round(load_time, 2), " seconds")
    message("📊 National data: ", nrow(national_data), " rows")
    if (!is.null(state_data)) {
      message("📊 State data: ", nrow(state_data), " rows")
    }

    babynames <- list(
      national = national_data,
      state = state_data
    )

    return(babynames)
  }
}

# CACHE MANAGEMENT UTILITIES ====

#' Clear cached data
#' @param cache_dir Cache directory path
#' @param confirm Require confirmation before clearing
clear_cache <- function(cache_dir = "data", confirm = TRUE) {

  if (confirm) {
    response <- readline("Are you sure you want to clear all cached data? [y/N]: ")
    if (!tolower(response) %in% c("y", "yes")) {
      message("Cache clearing cancelled.")
      return(invisible(FALSE))
    }
  }

  # Remove cache files
  raw_dir <- file.path(cache_dir, "raw")
  processed_dir <- file.path(cache_dir, "processed")
  cache_results_dir <- file.path(cache_dir, "cache")

  if (dir.exists(raw_dir)) unlink(raw_dir, recursive = TRUE)
  if (dir.exists(processed_dir)) unlink(processed_dir, recursive = TRUE)
  if (dir.exists(cache_results_dir)) unlink(cache_results_dir, recursive = TRUE)

  message("🗑️  Cache cleared successfully!")
  invisible(TRUE)
}

#' Display cache status information
#' @param cache_dir Cache directory path
show_cache_status <- function(cache_dir = "data") {

  status <- check_cache_status(cache_dir)

  message("📋 Cache Status Report")
  message("==================")
  message("Cache Directory: ", normalizePath(cache_dir, mustWork = FALSE))
  message("National Data: ", if (status$national_exists) "✅ Exists" else "❌ Missing")
  message("State Data: ", if (status$state_exists) "✅ Exists" else "❌ Missing")
  message("Metadata: ", if (status$metadata_exists) "✅ Exists" else "❌ Missing")

  if (!is.null(status$last_download)) {
    days_old <- as.numeric(Sys.Date() - status$last_download)
    message("Last Download: ", status$last_download, " (", days_old, " days ago)")
    message("Data Freshness: ", if (status$data_fresh) "✅ Fresh" else "⚠️  Stale")
  } else {
    message("Last Download: Unknown")
    message("Data Freshness: ❌ Unknown")
  }

  # File sizes if they exist
  if (status$national_exists) {
    national_file <- file.path(cache_dir, "raw", "national_data.rds")
    size_mb <- round(file.size(national_file) / 1024^2, 1)
    message("National Data Size: ", size_mb, " MB")
  }

  if (status$state_exists) {
    state_file <- file.path(cache_dir, "raw", "state_data.rds")
    size_mb <- round(file.size(state_file) / 1024^2, 1)
    message("State Data Size: ", size_mb, " MB")
  }
}

#' Get cache directory size
#' @param cache_dir Cache directory path
#' @return Size in MB
get_cache_size <- function(cache_dir = "data") {
  if (!dir.exists(cache_dir)) return(0)

  files <- list.files(cache_dir, recursive = TRUE, full.names = TRUE)
  total_size <- sum(file.size(files), na.rm = TRUE)
  round(total_size / 1024^2, 1)  # Convert to MB
}