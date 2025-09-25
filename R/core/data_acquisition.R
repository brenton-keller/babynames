# SSA BABY NAMES DATA ACQUISITION
# Downloads and processes Social Security Administration baby names data

#' Download SSA baby names data with automatic package loading
#' @param include_state Include state-level data (larger download)
#' @param temp_dir Temporary directory for downloads
#' @return List with national (and state) data.table objects
get_ssa_babynames <- function(include_state = FALSE, temp_dir = tempdir()) {

  # Ensure required packages are loaded
  required_packages <- c("data.table", "curl", "dplyr")
  for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop("Package '", pkg, "' is required but not installed. ",
           "Please run: install.packages('", pkg, "')")
    }
  }

  # Load packages
  library(data.table, quietly = TRUE)
  library(curl, quietly = TRUE)
  library(dplyr, quietly = TRUE)
  process_zip <- function(url, pattern, col_names) {
    zip_file <- file.path(temp_dir, basename(url))
    extract_dir <- file.path(temp_dir, tools::file_path_sans_ext(basename(url)))
    
    curl::curl_download(url, zip_file)
    dir.create(extract_dir, showWarnings = FALSE)
    unzip(zip_file, exdir = extract_dir)
    
    files <- list.files(extract_dir, pattern, full.names = TRUE)
    dt <- rbindlist(lapply(files, function(f) {
      data <- fread(f, col.names = col_names)
      if (!"year" %in% col_names) 
        data[, year := as.integer(gsub(".*?(\\d{4}).*", "\\1", basename(f)))]
      data
    }))
    
    unlink(c(zip_file, extract_dir), recursive = TRUE)
    dt[]
  }
  
  result <- list(
    national = process_zip(
      "https://www.ssa.gov/oact/babynames/names.zip",
      "^yob\\d{4}\\.txt$",
      c("name", "sex", "n")
    )[, .(year, sex, name, n)]
  )
  
  if (include_state) {
    result$state <- process_zip(
      "https://www.ssa.gov/oact/babynames/state/namesbystate.zip",
      "\\.TXT$", 
      c("state", "sex", "year", "name", "n")
    )[, .(year, sex, state, name, n)]
  }
  
  result
}
