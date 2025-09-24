# VISUALIZATION ====

plot_name <- function(name_input, years = 1970:2024, sex_input = c("M","F")) {
  
  # Your text box function
  add_text_box <- function(x, y, text, cex = 0.8, col = "black", 
                          size_multiplier_x = 1.0, size_multiplier_y = 1.5,
                          glass_effect = TRUE, glass_style = "clean",
                          font = 1, adj = c(0.5, 0.5), xpd = TRUE) {
    
    text_width <- strwidth(text, cex = cex, font = font)
    text_height <- strheight(text, cex = cex, font = font)
    
    base_padding_x <- text_width * 0.075
    base_padding_y <- text_height * 0.4
    padding_x <- base_padding_x * size_multiplier_x
    padding_y <- base_padding_y * size_multiplier_y
    
    if(adj[1] == 0.5) {
      left <- x - (text_width / 2) - padding_x
      right <- x + (text_width / 2) + padding_x
    } else if(adj[1] == 0) {
      left <- x - padding_x
      right <- x + text_width + padding_x
    } else {
      left <- x - text_width - padding_x
      right <- x + padding_x
    }
    
    bottom <- y - (text_height / 2) - padding_y
    top <- y + (text_height / 2) + padding_y
    
    if(glass_effect && glass_style == "clean") {
      rect(left, bottom, right, top, 
           col = rgb(1, 1, 1, 0.8),
           border = NA, xpd = xpd)
    }
    
    text(x, y, text, cex = cex, col = col, font = font, adj = adj, xpd = xpd)
  }
  
  # Handle input and create group mapping
  if (is.list(name_input)) {
    group_mapping <- rbindlist(lapply(seq_along(name_input), function(i) {
      data.table(name = name_input[[i]], group = i)
    }))
    name_vec <- unlist(name_input)
  } else {
    group_mapping <- data.table(name = name_input, group = 1)
    name_vec <- name_input
  }
  
  cat("=== INPUT MAPPING ===\n")
  print(group_mapping)
  
  # CORRECT: Calculate percentage first, then filter
  d <- copy(babynames$national)[, n_prop := round(n/sum(n)*100, 3), by=.(year, sex)][
    name %in% name_vec & year %in% years & sex %in% sex_input]
  
  if (!nrow(d)) stop("No data found for specified criteria")
  
  # Add group info to data
  d <- group_mapping[d, on = "name"]
  
  # FIXED: Calculate individual name popularity properly FIRST
  name_popularity <- d[, .(max_pop = max(n_prop)), by = .(sex, name, group)]
  cat("\n=== NAME POPULARITY (before ranking) ===\n")
  print(name_popularity[order(group, -max_pop)])
  
  # Calculate group popularity and rankings
  group_peaks <- name_popularity[, .(group_peak = sum(max_pop)), by = .(sex, group)][
    order(sex, -group_peak)
  ][, group_rank := seq_len(.N), by = sex]
  
  cat("\n=== GROUP RANKINGS ===\n")
  print(group_peaks)
  
  # Merge group rankings to name popularity
  name_popularity <- group_peaks[name_popularity, on = .(sex, group)]
  
  # FIXED: Rank names within groups by their actual max popularity
  name_popularity[, name_rank := frank(-max_pop, ties.method = "first"), by = .(sex, group)]
  
  cat("\n=== NAME RANKINGS WITHIN GROUPS ===\n")
  print(name_popularity[order(group_rank, name_rank)])
  
  # Merge all rankings back to main data
  d <- name_popularity[d, on = .(sex, name, group)]
  
  # FIXED: Predefined color ramps
  group_color_ramps <- list(
    M = list(
      c("#08519c", "#3182bd", "#6baed6", "#c6dbef"),  # Blue ramp (dark to light)
      c("#d94701", "#fd8d3c", "#fdae6b", "#fdd0a2"),  # Orange ramp
      c("#238b45", "#41ab5d", "#74c476", "#a1d99b"),  # Green ramp
      c("#a50f15", "#de2d26", "#fb6a4a", "#fc9272")   # Red ramp
    ),
    F = list(
      c("#7a0177", "#c51b8a", "#f768a1", "#fbb4b9"),  # Pink ramp
      c("#8c2d04", "#cc4c02", "#ec7014", "#fe9929"),  # Brown/orange ramp
      c("#4a1486", "#6a51a3", "#9e9ac8", "#cbc9e2"),  # Purple ramp
      c("#045a8d", "#2b8cbe", "#74a9cf", "#bdc9e1")   # Cyan ramp
    )
  )
  
  # FIXED: Assign colors with debugging
  color_assignments <- unique(d[, .(sex, name, group, group_rank, name_rank, max_pop)])
  color_assignments[, col := {
    sex_ramps <- group_color_ramps[[sex[1]]]
    group_ramp_idx <- ((group_rank[1] - 1) %% length(sex_ramps)) + 1
    color_idx <- min(name_rank[1], length(sex_ramps[[group_ramp_idx]]))
    assigned_color <- sex_ramps[[group_ramp_idx]][color_idx]
    cat(sprintf("Name: %s, Group: %d, GroupRank: %d, NameRank: %d, GroupRampIdx: %d, ColorIdx: %d, Color: %s\n", 
               name[1], group[1], group_rank[1], name_rank[1], group_ramp_idx, color_idx, assigned_color))
    assigned_color
  }, by = .(sex, group, name)]
  
  cat("\n=== COLOR ASSIGNMENTS ===\n")
  print(color_assignments[order(group_rank, name_rank)])
  
  # Merge colors back to main data
  d <- color_assignments[, .(sex, name, col)][d, on = .(sex, name)]
  
  # Plot
  par(mar = c(5, 4, 4, 8), xpd = FALSE)
  
  plot(NA, xlim = range(d$year), ylim = c(0, max(d$n_prop) * 1.15),
       xlab = "Year", ylab = "Percentage of births (%)",
       main = "Name Popularity by Group",
       las = 1, frame.plot = FALSE)
  
  grid(col = "gray90", lty = 1)
  
  # FIXED: Plot lines using the reliable loop approach
  groups <- unique(d[, .(sex, name)])
  d_ordered <- d[order(year)]
  
  for(i in 1:nrow(groups)) {
    group_data <- d_ordered[sex == groups$sex[i] & name == groups$name[i]]
    line_color <- group_data$col[1]  # Use the first color for this group
    lines(group_data$year, group_data$n_prop, col = line_color, lwd = 2.6)
    points(group_data$year, group_data$n_prop, col = line_color, pch = 19, cex = 0.4)
  }
  
  # FIXED: Legend with proper ordering
  if (uniqueN(d[, .(sex, name)]) > 1) {
    par(xpd = TRUE)
    lg <- unique(d[, .(sex, name, col, group_rank, max_pop)])[order(group_rank, -max_pop)]
    
    cat("\n=== LEGEND ORDER ===\n")
    print(lg)
    
    legend(x = par("usr")[2] + diff(par("usr")[1:2]) * 0.02,
           y = par("usr")[4],
           legend = if(uniqueN(d$sex) > 1) paste0(lg$name, " (", lg$sex, ")") else lg$name,
           col = lg$col, lwd = 2.6, bty = "n", cex = 0.9)
  }
  
  # Get top peak from each group for labels
  group_peaks_for_labels <- d[, .SD[which.max(n_prop)], by = .(sex, name, group, group_rank, col)][
    , .SD[which.max(n_prop)], by = .(sex, group_rank)
  ][order(-n_prop)]
  
  n_peaks <- min(4, nrow(group_peaks_for_labels))
  peaks <- group_peaks_for_labels[1:n_peaks]
  
  if (nrow(peaks) > 0) {
    par(xpd = TRUE)
    for(i in 1:nrow(peaks)) {
      label <- paste(peaks$name[i], "-", paste0(round(peaks$n_prop[i], 1), "%"))
      
      x_pos <- peaks$year[i]
      y_pos <- peaks$n_prop[i] + max(d$n_prop) * 0.05
      
      add_text_box(x_pos, y_pos, label, 
                   cex = 0.75, col = peaks$col[i], font = 2,
                   size_multiplier_x = 1.2, size_multiplier_y = 1.6,
                   glass_effect = TRUE, glass_style = "clean")
    }
  }
}

# ADVANCED ANALYTICS ====

detect_breakpoints <- function(dt, name_input, sex_param = "M", years = 1970:2024, 
                              h = 0.15, plot = TRUE, verbose = TRUE,
                              return_data = TRUE, style = "modern",
                              comparison_mode = FALSE, show_segment_labels = TRUE) {
  
  # Enhanced text box function
  add_text_box <- function(x, y, text, cex = 0.8, col = "black", 
                          size_multiplier_x = 1.0, size_multiplier_y = 1.5,
                          glass_effect = TRUE, glass_style = "clean",
                          font = 1, adj = c(0.5, 0.5), xpd = TRUE) {
    
    text_width <- strwidth(text, cex = cex, font = font)
    text_height <- strheight(text, cex = cex, font = font)
    
    base_padding_x <- text_width * 0.075
    base_padding_y <- text_height * 0.4
    padding_x <- base_padding_x * size_multiplier_x
    padding_y <- base_padding_y * size_multiplier_y
    
    if(adj[1] == 0.5) {
      left <- x - (text_width / 2) - padding_x
      right <- x + (text_width / 2) + padding_x
    } else if(adj[1] == 0) {
      left <- x - padding_x
      right <- x + text_width + padding_x
    } else {
      left <- x - text_width - padding_x
      right <- x + padding_x
    }
    
    bottom <- y - (text_height / 2) - padding_y
    top <- y + (text_height / 2) + padding_y
    
    if(glass_effect && glass_style == "clean") {
      rect(left, bottom, right, top, 
           col = rgb(1, 1, 1, 0.85),
           border = rgb(0.7, 0.7, 0.7, 0.5), 
           lwd = 0.5, xpd = xpd)
    }
    
    text(x, y, text, cex = cex, col = col, font = font, adj = adj, xpd = xpd)
    
    # Return box boundaries for overlap detection
    return(invisible(list(left = left, right = right, bottom = bottom, top = top)))
  }
  
  # Smart positioning function for segment labels
  position_segment_labels <- function(all_results, plot_xlim, plot_ylim) {
    all_labels <- list()
    
    for (name_val in names(all_results)) {
      result <- all_results[[name_val]]
      
      if (length(result$segments) == 0) next
      
      cat("DIAGNOSTIC - Positioning labels for", name_val, "\n")
      
      name_labels <- list()
      
      for (seg in result$segments) {
        if (is.null(seg)) next
        
        # Calculate midpoint year
        mid_year <- (seg$start_year + seg$end_year) / 2
        
        # Get the actual data value at midpoint (interpolate if needed)
        seg_data_subset <- result$data[year >= seg$start_year & year <= seg$end_year]
        
        # Find closest year to midpoint
        closest_year_idx <- which.min(abs(seg_data_subset$year - mid_year))
        mid_pct <- seg_data_subset$pct[closest_year_idx]
        
        # If midpoint falls between years, interpolate
        if (abs(seg_data_subset$year[closest_year_idx] - mid_year) > 0.5) {
          before_idx <- max(1, closest_year_idx - 1)
          after_idx <- min(nrow(seg_data_subset), closest_year_idx + 1)
          
          if (before_idx != after_idx) {
            weight <- (mid_year - seg_data_subset$year[before_idx]) / 
                     (seg_data_subset$year[after_idx] - seg_data_subset$year[before_idx])
            mid_pct <- seg_data_subset$pct[before_idx] * (1 - weight) + 
                      seg_data_subset$pct[after_idx] * weight
          }
        }
        
        # Create label text (two lines)
        label_line1 <- sprintf("Segment %d (%d-%d)", seg$segment_num, seg$start_year, seg$end_year)
        label_line2 <- sprintf("%s %s (%.3f%%/decade, R²=%.2f)", 
                              seg$trend_symbol, seg$trend, seg$slope_per_decade, seg$r_squared)
        label_text <- paste(label_line1, label_line2, sep = "\n")
        
        # Determine if label should go above or below line
        # Strategy: alternate above/below, but also consider line slope and available space
        plot_height <- diff(plot_ylim)
        
        # Start with alternating pattern
        base_above <- (seg$segment_num %% 2 == 1)
        
        # Adjust based on line position relative to plot
        line_position_ratio <- mid_pct / max(plot_ylim)
        
        # If line is in top 40% of plot, prefer below
        if (line_position_ratio > 0.6) {
          above_line <- FALSE
        } else if (line_position_ratio < 0.3) {
          # If line is in bottom 30% of plot, prefer above
          above_line <- TRUE
        } else {
          # Use alternating pattern in middle range
          above_line <- base_above
        }
        
        # Calculate vertical offset
        base_offset <- plot_height * 0.08  # 8% of plot height
        
        if (above_line) {
          label_y <- mid_pct + base_offset
        } else {
          label_y <- mid_pct - base_offset
        }
        
        # Ensure label stays within plot bounds
        label_y <- max(plot_ylim[1] + plot_height * 0.05, 
                      min(plot_ylim[2] - plot_height * 0.05, label_y))
        
        cat(sprintf("  Segment %d: mid_year=%.1f, mid_pct=%.3f, label_y=%.3f, %s\n",
                   seg$segment_num, mid_year, mid_pct, label_y, 
                   ifelse(above_line, "above", "below")))
        
        name_labels[[length(name_labels) + 1]] <- list(
          x = mid_year,
          y = label_y,
          text = label_text,
          color = result$color,
          above_line = above_line,
          segment_num = seg$segment_num,
          name = name_val
        )
      }
      
      all_labels[[name_val]] <- name_labels
    }
    
    return(all_labels)
  }
  
  # Overlap resolution function
  resolve_label_overlaps <- function(all_labels, plot_xlim, plot_ylim) {
    # Flatten all labels into single list for overlap detection
    flat_labels <- list()
    for (name_val in names(all_labels)) {
      for (label in all_labels[[name_val]]) {
        flat_labels[[length(flat_labels) + 1]] <- label
      }
    }
    
    if (length(flat_labels) <= 1) return(all_labels)
    
    cat("DIAGNOSTIC - Resolving", length(flat_labels), "label overlaps\n")
    
    # Sort by x position
    flat_labels <- flat_labels[order(sapply(flat_labels, function(l) l$x))]
    
    plot_height <- diff(plot_ylim)
    min_vertical_separation <- plot_height * 0.12  # Minimum 12% separation
    
    # Adjust overlapping labels
    for (i in 2:length(flat_labels)) {
      curr_label <- flat_labels[[i]]
      prev_label <- flat_labels[[i-1]]
      
      # Check horizontal overlap (labels need some x-separation too)
      x_overlap <- abs(curr_label$x - prev_label$x) < diff(plot_xlim) * 0.08
      
      if (x_overlap) {
        y_diff <- abs(curr_label$y - prev_label$y)
        
        if (y_diff < min_vertical_separation) {
          # Push current label away from previous
          if (curr_label$y > prev_label$y) {
            # Current is above, push it higher
            curr_label$y <- prev_label$y + min_vertical_separation
          } else {
            # Current is below, push it lower
            curr_label$y <- prev_label$y - min_vertical_separation
          }
          
          # Keep within bounds
          curr_label$y <- max(plot_ylim[1] + plot_height * 0.05,
                             min(plot_ylim[2] - plot_height * 0.05, curr_label$y))
          
          flat_labels[[i]] <- curr_label
          
          cat(sprintf("  Adjusted label at x=%.1f, new y=%.3f\n", 
                     curr_label$x, curr_label$y))
        }
      }
    }
    
    # Reconstruct nested structure
    adjusted_labels <- list()
    for (name_val in names(all_labels)) {
      adjusted_labels[[name_val]] <- list()
    }
    
    for (label in flat_labels) {
      name_val <- label$name
      adjusted_labels[[name_val]][[length(adjusted_labels[[name_val]]) + 1]] <- label
    }
    
    return(adjusted_labels)
  }
  
  if (!requireNamespace("strucchange", quietly = TRUE)) {
    stop("Package 'strucchange' required: install.packages('strucchange')")
  }
  if (!requireNamespace("data.table", quietly = TRUE)) {
    stop("Package 'data.table' required: install.packages('data.table')")
  }
  
  # Convert name_input to vector
  if (is.list(name_input)) {
    names_vec <- unlist(name_input)
  } else {
    names_vec <- name_input
  }
  
  if (verbose) cat("=== BREAKPOINT ANALYSIS ===\n")
  if (verbose) cat("Names:", paste(names_vec, collapse=", "), "\n")
  if (verbose) cat("Sex:", sex_param, "| Years:", min(years), "-", max(years), "\n\n")
  
  # Input validation
  if (verbose) {
    cat("DIAGNOSTIC - Input validation:\n")
    cat("  Dataset rows:", nrow(dt), "\n")
    cat("  Years available:", min(dt$year), "-", max(dt$year), "\n")
    cat("  Sex values:", paste(unique(dt$sex), collapse=", "), "\n")
    cat("  Names requested:", paste(names_vec, collapse=", "), "\n")
  }
  
  available_years <- intersect(years, unique(dt$year))
  if (length(available_years) == 0) {
    stop("No data available for requested years")
  }
  
  if (length(available_years) < length(years) && verbose) {
    cat("  WARNING: Only", length(available_years), "of", length(years), "requested years available\n")
  }
  
  name_colors <- c("#08519c", "#d94701", "#238b45", "#a50f15", "#6a51a3", "#8c2d04")
  all_results <- list()
  
  # Data processing (keeping your existing logic)
  for (idx in seq_along(names_vec)) {
    name_val <- names_vec[idx]
    name_color <- name_colors[((idx - 1) %% length(name_colors)) + 1]
    
    if (verbose) cat("\n", idx, ". Processing:", name_val, "\n")
    
    if (verbose) cat("DIAGNOSTIC - Data extraction:\n")
    
    data <- dt[sex == sex_param & year %in% available_years, 
               .(n_total = sum(n),
                 n_name = sum(n * (name == name_val))), 
               by = year]
    
    data[, `:=`(
      n = n_name,
      pct = ifelse(n_total > 0, (n_name / n_total) * 100, 0),
      name = name_val,
      sex = sex_param
    )]
    
    data[, n_name := NULL]
    
    complete_years <- data.table(year = available_years)
    data <- merge(complete_years, data, by = "year", all.x = TRUE)
    data[is.na(n), `:=`(n = 0, n_total = 0, pct = 0, name = name_val, sex = sex_param)]
    
    data <- data[order(year)]
    
    # Validation
    if (verbose) {
      cat("DIAGNOSTIC - Final data validation:\n")
      cat("  Final rows:", nrow(data), "\n")
      cat("  Expected rows:", length(available_years), "\n")
      cat("  Year range:", range(data$year), "\n")
      cat("  Unique years:", length(unique(data$year)), "\n")
    }
    
    year_counts <- data[, .N, by = year]
    duplicates <- year_counts[N > 1]
    
    if (nrow(duplicates) > 0) {
      cat("  ERROR: Found duplicates!\n")
      print(duplicates)
      print(data[year %in% duplicates$year])
      stop("Data preparation failed - duplicates found")
    } else if (verbose) {
      cat("  ✓ No duplicates found\n")
    }
    
    if (verbose) {
      cat("  Percentage range:", sprintf("%.4f%% - %.4f%%", min(data$pct), max(data$pct)), "\n")
      cat("  Non-zero years:", sum(data$pct > 0), "\n")
    }
    
    if (nrow(data) < 10) {
      warning(paste("Insufficient data for", name_val))
      next
    }
    
    # Breakpoint detection
    data_for_bp <- data[pct > 0]
    if (nrow(data_for_bp) < 10) {
      if (verbose) cat("  Not enough non-zero data points for breakpoint analysis\n")
      all_results[[name_val]] <- list(
        data = data, breakpoints = numeric(0), segments = list(), 
        bp_test = NULL, color = name_color
      )
      next
    }
    
    if (verbose) {
      cat("DIAGNOSTIC - Breakpoint detection:\n")
      cat("  Non-zero data points:", nrow(data_for_bp), "\n")
    }
    
    ts_data <- ts(data_for_bp$pct, start = min(data_for_bp$year))
    bp_test <- tryCatch({
      strucchange::breakpoints(ts_data ~ 1, h = h)
    }, error = function(e) {
      if (verbose) cat("  Breakpoint detection error:", e$message, "\n")
      return(NULL)
    })
    
    if (is.null(bp_test)) {
      all_results[[name_val]] <- list(
        data = data, breakpoints = numeric(0), segments = list(),
        bp_test = NULL, color = name_color
      )
      next
    }
    
    bp_indices <- if(!is.na(bp_test$breakpoints[1])) bp_test$breakpoints else numeric(0)
    bp_years <- if (length(bp_indices) > 0) data_for_bp$year[bp_indices] else numeric(0)
    
    if (verbose) {
      cat("  Breakpoints found:", length(bp_years), "\n")
      if (length(bp_years) > 0) {
        cat("  Breakpoint years:", paste(bp_years, collapse=", "), "\n")
      }
    }
    
    # Segment analysis
    segments_list <- list()
    if (length(bp_years) > 0) {
      bp_indices_full <- match(bp_years, data$year)
      segment_indices <- c(1, bp_indices_full, nrow(data))
    } else {
      segment_indices <- c(1, nrow(data))
    }
    
    overall_sd <- sd(data$pct[data$pct > 0])
    slope_threshold <- overall_sd * 0.01
    
    for (i in 1:(length(segment_indices) - 1)) {
      start_idx <- segment_indices[i]
      end_idx <- segment_indices[i + 1]
      seg_data <- data[start_idx:end_idx]
      
      if (nrow(seg_data) >= 3) {
        lm_fit <- lm(pct ~ year, data = seg_data)
        slope <- coef(lm_fit)[2]
        r_squared <- summary(lm_fit)$r.squared
        p_value <- summary(lm_fit)$coefficients[2, 4]
        
        conf_int <- tryCatch(confint(lm_fit, "year", level = 0.95), 
                           error = function(e) matrix(c(-Inf, Inf), nrow = 1))
        
        if (slope > slope_threshold && conf_int[1] > 0) {
          trend <- "Rising"; trend_symbol <- "↑"
        } else if (slope < -slope_threshold && conf_int[2] < 0) {
          trend <- "Declining"; trend_symbol <- "↓"
        } else {
          trend <- "Stable"; trend_symbol <- "→"
        }
        
        segments_list[[i]] <- list(
          segment_num = i, start_year = seg_data$year[1], end_year = seg_data$year[nrow(seg_data)],
          start_pct = seg_data$pct[1], end_pct = seg_data$pct[nrow(seg_data)],
          slope_per_decade = slope * 10, r_squared = r_squared, p_value = p_value,
          trend = trend, trend_symbol = trend_symbol
        )
        
        if (verbose) {
          cat(sprintf("    Segment %d (%d-%d): %s %s (%.3f%%/decade, R²=%.2f)\n",
                      i, seg_data$year[1], seg_data$year[nrow(seg_data)],
                      trend_symbol, trend, slope * 10, r_squared))
        }
      }
    }
    
    all_results[[name_val]] <- list(
      data = data, breakpoints = bp_years, segments = segments_list,
      bp_test = bp_test, color = name_color
    )
  }
  
  # ENHANCED PLOTTING with positioned segment labels
  if (plot && length(all_results) > 0) {
    # Only single plot mode (multiple names on same graph)
    par(mar = c(5, 4, 4, 8), xpd = FALSE)
    
    all_years_range <- range(unlist(lapply(all_results, function(r) range(r$data$year))))
    all_pcts_range <- range(unlist(lapply(all_results, function(r) range(r$data$pct))))
    
    plot(NA, xlim = all_years_range, ylim = c(0, max(all_pcts_range) * 1.15),
         xlab = "Year", ylab = "Percentage of births (%)",
         main = paste("Breakpoint Analysis:", paste(names(all_results), collapse=", ")),
         las = 1, frame.plot = FALSE)
    
    grid(col = "gray92", lty = 1, lwd = 0.5)
    
    # Plot all the lines and breakpoints first
    for (name_val in names(all_results)) {
      result <- all_results[[name_val]]
      
      # Plot line
      lines(result$data$year, result$data$pct, col = result$color, lwd = 2.8)
      points(result$data$year, result$data$pct, col = result$color, pch = 19, cex = 0.3)
      
      # Breakpoint markers
      if (length(result$breakpoints) > 0) {
        for (bp_year in result$breakpoints) {
          bp_row <- result$data[year == bp_year]
          if (nrow(bp_row) > 0) {
            abline(v = bp_year, col = result$color, lwd = 3, lty = 2, xpd = FALSE)
            points(bp_year, bp_row$pct, pch = 23, col = "white", 
                   bg = result$color, cex = 2.5, lwd = 3)
          }
        }
      }
    }
    
    # NOW ADD SEGMENT LABELS with intelligent positioning
    if (show_segment_labels) {
      cat("\nDIAGNOSTIC - Adding segment labels\n")
      
      # Calculate positions
      positioned_labels <- position_segment_labels(all_results, all_years_range, 
                                                   c(0, max(all_pcts_range) * 1.15))
      
      # Resolve overlaps
      final_labels <- resolve_label_overlaps(positioned_labels, all_years_range, 
                                            c(0, max(all_pcts_range) * 1.15))
      
      # Draw the labels
      par(xpd = TRUE)  # Allow drawing outside plot region
      
      for (name_val in names(final_labels)) {
        name_labels <- final_labels[[name_val]]
        
        for (label in name_labels) {
          # Draw connecting line from label to segment midpoint
          # Get actual line y-value at this x position
          result <- all_results[[name_val]]
          closest_data_idx <- which.min(abs(result$data$year - label$x))
          line_y <- result$data$pct[closest_data_idx]
          
          # Draw subtle connecting line
          segments(label$x, line_y, label$x, label$y, 
                  col = alpha(label$color, 0.4), lwd = 1, lty = 3)
          
          # Add the text box
          add_text_box(label$x, label$y, label$text,
                       cex = 0.65, col = label$color, font = 1,
                       adj = c(0.5, 0.5),
                       size_multiplier_x = 1.1, size_multiplier_y = 1.2,
                       glass_effect = TRUE, glass_style = "clean")
        }
      }
      
      par(xpd = FALSE)  # Reset
    }
    
    # Legend
    if (length(all_results) > 1) {
      par(xpd = TRUE)
      legend_items <- sapply(names(all_results), function(n) {
        n_bp <- length(all_results[[n]]$breakpoints)
        paste0(n, " (", n_bp, " BP)")
      })
      
      legend(x = par("usr")[2] + diff(par("usr")[1:2]) * 0.02, y = par("usr")[4],
             legend = legend_items, col = sapply(all_results, function(r) r$color),
             lwd = 2.8, lty = 1, bty = "n", cex = 0.85)
    }
  }
  
  if (return_data) invisible(all_results)
}
