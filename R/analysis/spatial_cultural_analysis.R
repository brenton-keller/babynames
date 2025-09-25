# SPATIAL AND CULTURAL ANALYSIS FUNCTIONS
# Optimized for data.table performance with strategic vectorization

# CONFIGURATION AND UTILITIES ====

# US Census regions mapping for cultural clustering
US_REGIONS <- list(
  Northeast = c("CT", "ME", "MA", "NH", "NJ", "NY", "PA", "RI", "VT"),
  Midwest = c("IL", "IN", "IA", "KS", "MI", "MN", "MO", "NE", "ND", "OH", "SD", "WI"),
  South = c("AL", "AR", "DE", "FL", "GA", "KY", "LA", "MD", "MS", "NC", "OK", "SC", "TN", "TX", "VA", "WV"),
  West = c("AK", "AZ", "CA", "CO", "HI", "ID", "MT", "NV", "NM", "OR", "UT", "WA", "WY")
)

# Create region lookup table for fast joins
create_region_lookup <- function() {
  region_dt <- rbindlist(lapply(names(US_REGIONS), function(region) {
    data.table(state = US_REGIONS[[region]], region = region)
  }))
  setkey(region_dt, state)
  region_dt
}

# NAME VARIANT GROUPING SYSTEM ====

#' Create and manage name variant groups
#' @param variant_list Named list where each element contains variant spellings
#' @return data.table with name-to-group mappings
create_name_variants <- function(variant_list = NULL) {
  if (is.null(variant_list)) {
    # Default example groups - can be extended
    variant_list <- list(
      "Jayden_group" = c("Jayden", "Jaiden", "Jaden", "Jaydon", "Jaeden", "Jaidyn"),
      "Michael_group" = c("Michael", "Mikael", "Mikhail", "Miguel"),
      "Catherine_group" = c("Catherine", "Katherine", "Kathryn", "Catherine", "Katharine"),
      "Christopher_group" = c("Christopher", "Kristopher", "Christoph")
    )
  }

  # Convert to data.table for fast lookups
  variant_dt <- rbindlist(lapply(names(variant_list), function(group_name) {
    data.table(name = variant_list[[group_name]], name_group = group_name)
  }))

  setkey(variant_dt, name)
  variant_dt
}

# DATA PREPARATION ====

#' Prepare and enhance state-level data for spatial analysis
#' @param state_dt Raw state data from babynames$state
#' @param variant_dt Name variant mappings (optional)
#' @param min_threshold Minimum births to consider for origin analysis
#' @return Enhanced data.table with spatial metadata
prepare_state_data <- function(state_dt, variant_dt = NULL, min_threshold = 10) {

  # Create working copy to avoid modifying original
  dt <- copy(state_dt)

  # Add regional information
  region_lookup <- create_region_lookup()
  dt <- region_lookup[dt, on = "state"]

  # Filter minimum threshold early for performance
  dt <- dt[n >= min_threshold]

  # Add name groups if variants provided
  if (!is.null(variant_dt)) {
    dt <- variant_dt[dt, on = "name"]
    # For names without groups, use the name itself as group
    dt[is.na(name_group), name_group := name]
  } else {
    dt[, name_group := name]
  }

  # Calculate proportions by state-year-sex (vectorized)
  dt[, prop_state := n / sum(n), by = .(year, state, sex)]

  # Calculate national proportions for same year-sex-name_group
  national_totals <- dt[, .(total_n = sum(n)), by = .(year, sex, name_group)]
  year_totals <- dt[, .(year_total = sum(n)), by = .(year, sex)]

  # Merge totals for proportion calculation
  dt <- national_totals[dt, on = .(year, sex, name_group)]
  dt <- year_totals[dt, on = .(year, sex)]
  dt[, prop_national := total_n / year_total]

  # Clean up intermediate columns
  dt[, c("total_n", "year_total") := NULL]

  setkey(dt, year, sex, name_group, state)
  dt
}

# ORIGIN DETECTION ====

#' Find the origin state and year for each name/name_group using proportional analysis
#' @param dt Enhanced state data from prepare_state_data()
#' @param min_states Minimum number of states name must appear in
#' @param min_years Minimum number of years name must be present
#' @param early_years_window Number of years from first appearance to consider for origin
#' @return data.table with origin information
find_name_origins <- function(dt, min_states = 3, min_years = 2, early_years_window = 3) {

  # Filter names that meet minimum requirements first
  name_stats <- dt[, .(
    n_states = uniqueN(state),
    n_years = uniqueN(year),
    total_births = sum(n),
    first_year = min(year)
  ), by = .(sex, name_group)]

  qualified_names <- name_stats[n_states >= min_states & n_years >= min_years]

  # Work only with qualified names for efficiency
  qualified_dt <- dt[qualified_names, on = .(sex, name_group), nomatch = 0]

  # For each qualified name, find the true origin using proportional analysis
  origins <- qualified_dt[, {
    first_year <- min(year)
    early_years <- first_year:(first_year + early_years_window - 1)

    # Get data from early years only
    early_data <- .SD[year %in% early_years]

    if (nrow(early_data) == 0) {
      # Fallback if no early data
      early_data <- .SD[year == first_year]
    }

    # For each state in early years, calculate significance score
    state_scores <- early_data[, {
      # Calculate multiple metrics for origin determination
      total_births_state <- sum(n)
      years_present <- uniqueN(year)
      avg_prop_state <- mean(prop_state, na.rm = TRUE)  # Average within-state proportion
      max_prop_state <- max(prop_state, na.rm = TRUE)   # Peak within-state proportion
      first_year_state <- min(year)

      # Origin score: combines early appearance, high state proportion, and consistency
      # Higher score = more likely to be origin
      years_early_bonus <- max(0, 5 - (first_year_state - first_year))  # Earlier = better
      prop_score <- avg_prop_state * 1000  # Scale up proportions
      consistency_score <- years_present * 2  # Multiple years = better
      total_births_bonus <- log1p(total_births_state)  # Log scale for births

      origin_score <- years_early_bonus + prop_score + consistency_score + total_births_bonus

      list(
        total_births = total_births_state,
        years_present = years_present,
        avg_prop_state = avg_prop_state,
        max_prop_state = max_prop_state,
        first_year_state = first_year_state,
        origin_score = origin_score
      )
    }, by = state]

    # Select state with highest origin score as the origin
    origin_state_info <- state_scores[which.max(origin_score)]

    list(
      origin_state = origin_state_info$state,
      origin_year = origin_state_info$first_year_state,
      origin_score = origin_state_info$origin_score,
      origin_prop_state = origin_state_info$avg_prop_state,
      n_candidate_states = nrow(state_scores)
    )
  }, by = .(sex, name_group)]

  setkey(origins, sex, name_group)
  origins
}

# DIFFUSION TRACKING ====

#' Calculate diffusion metrics for names across states
#' @param dt Enhanced state data
#' @param origins_dt Results from find_name_origins()
#' @return data.table with diffusion metrics by name
calculate_diffusion_metrics <- function(dt, origins_dt) {

  # Add origin info to main dataset
  dt_with_origins <- origins_dt[dt, on = .(sex, name_group)]

  # Calculate years since origin for each state adoption
  dt_with_origins[, years_since_origin := year - origin_year]

  # Find first appearance in each state
  state_adoptions <- dt_with_origins[, .SD[which.min(year)],
                                     by = .(sex, name_group, state)]

  # Calculate diffusion metrics by name_group
  diffusion_stats <- state_adoptions[, {
    max_delay <- max(years_since_origin, na.rm = TRUE)
    # Handle cases where max_delay is -Inf (no valid years_since_origin)
    if (is.infinite(max_delay)) max_delay <- 0L

    mean_delay <- mean(years_since_origin, na.rm = TRUE)
    if (is.nan(mean_delay)) mean_delay <- 0.0

    rate <- .N / (max_delay + 1L)
    if (is.infinite(rate)) rate <- 0.0

    list(
      origin_state = first(origin_state),
      origin_year = as.integer(first(origin_year)),
      n_states_adopted = as.integer(.N),
      mean_adoption_delay = as.numeric(mean_delay),
      max_adoption_delay = as.integer(max_delay),
      diffusion_rate = as.numeric(rate),
      total_births = as.integer(sum(n))
    )
  }, by = .(sex, name_group)]

  # Add adoption rank (order of state adoption)
  state_adoptions <- state_adoptions[order(sex, name_group, year)]
  state_adoptions[, adoption_rank := seq_len(.N), by = .(sex, name_group)]

  list(
    diffusion_summary = diffusion_stats,
    state_adoptions = state_adoptions
  )
}

# REGIONAL ANALYSIS ====

#' Calculate regional diversity and cultural exchange metrics
#' @param dt Enhanced state data with regional info
#' @return List with regional diversity metrics
analyze_regional_patterns <- function(dt) {

  # Regional name diversity by year-sex
  regional_diversity <- dt[, {
    props <- prop_state[prop_state > 0]
    list(
      total_births = sum(n),
      unique_names = uniqueN(name_group),
      shannon_entropy = -sum(props * log(props)),
      top1_share = max(props),
      top5_share = sum(sort(props, decreasing = TRUE)[1:min(5, .N)])
    )
  }, by = .(year, sex, region)]

  # Cross-regional name sharing
  # Names present in multiple regions in same year
  regional_sharing <- dt[, .(regions_present = uniqueN(region)),
                         by = .(year, sex, name_group)]

  sharing_stats <- regional_sharing[, .(
    names_1_region = sum(regions_present == 1),
    names_2_regions = sum(regions_present == 2),
    names_3_regions = sum(regions_present == 3),
    names_4_regions = sum(regions_present == 4),
    total_names = .N
  ), by = .(year, sex)]

  # Regional distinctiveness - names that are disproportionately popular in one region
  # Calculate national totals for comparison
  national_totals <- dt[, .(national_n = sum(n)), by = .(year, sex, name_group)]

  regional_distinctiveness <- dt[, {
    # Calculate regional share within this region
    regional_total <- sum(n)
    regional_shares <- n / regional_total

    # Get corresponding national data
    current_national <- national_totals[year == .BY$year & sex == .BY$sex]
    national_total <- sum(current_national$national_n)

    # Merge to get national shares for comparison
    regional_data <- data.table(name_group = name_group,
                               regional_n = n,
                               regional_share = regional_shares)

    result_data <- current_national[regional_data, on = "name_group"]

    # Calculate distinctiveness ratio: regional_share / national_share
    result_data[, distinctiveness_ratio := regional_share / (national_n / national_total)]

    result_data[, .(name_group, regional_share, distinctiveness_ratio)]
  }, by = .(year, sex, region)]

  list(
    regional_diversity = regional_diversity,
    sharing_stats = sharing_stats,
    distinctiveness = regional_distinctiveness
  )
}

# HIGH-LEVEL ANALYSIS WRAPPER ====

#' Complete spatial-cultural analysis pipeline
#' @param state_dt Raw state data
#' @param variant_list Optional name variant groupings
#' @param min_threshold Minimum births threshold
#' @return List containing all analysis results
analyze_spatial_cultural <- function(state_dt, variant_list = NULL, min_threshold = 10) {

  # Step 1: Prepare data
  variant_dt <- if (!is.null(variant_list)) create_name_variants(variant_list) else NULL
  enhanced_dt <- prepare_state_data(state_dt, variant_dt, min_threshold)

  # Step 2: Find origins
  origins <- find_name_origins(enhanced_dt)

  # Step 3: Calculate diffusion
  diffusion_results <- calculate_diffusion_metrics(enhanced_dt, origins)

  # Step 4: Regional analysis
  regional_results <- analyze_regional_patterns(enhanced_dt)

  # Return comprehensive results
  list(
    config = list(min_threshold = min_threshold,
                 variant_groups = !is.null(variant_list)),
    enhanced_data = enhanced_dt,
    origins = origins,
    diffusion = diffusion_results,
    regional = regional_results,
    region_lookup = create_region_lookup()
  )
}