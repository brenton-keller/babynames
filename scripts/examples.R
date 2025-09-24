#' Data acquisition functions for SSA baby names
library(data.table)
library(dplyr)
library(curl)

# Download data
babynames <- get_ssa_babynames(include_state = TRUE)

# Find era winners  
winners <- get_era_winners(babynames$national, 1980)

# Plot specific names
# plot_name("Amiri",sex_input = "M")
# plot_name(c("Lucas","Aiden"),sex_input = "M")
# plot_name(c("Michael", "Jennifer"), years = 1970:2020)
# plot_name(c("Randolph"),sex_input = "M", years = 1930:2020)
plot_name(list(c("Jalen", "Jaylon", "Jaylen"),c('Brenton','Brent', 'Brendan'),c('Randy')), 
          sex_input = "M", years = 1970:2020)
          
# Detect trend changes

# Single name with positioned segment labels
detect_breakpoints(babynames$national, "Jalen", "M", years = 1980:2024)

# Multiple names with intelligent label positioning
detect_breakpoints(babynames$national, c("Chad", "Brad"), "M", years = 1945:2024)

# Turn off segment labels if too crowded
detect_breakpoints(babynames$national, c("Chad", "Brad", "Todd"), "M", 
                  years = 1945:2024, show_segment_labels = FALSE)

# Usage
name_stability(min_year = 1970) |> tail(10)
