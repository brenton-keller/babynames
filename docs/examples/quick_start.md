# Quick Start Examples

Practical examples to get you started with the Baby Names Analysis system.

## ⚡ **5-Minute Quick Start**

```r
# 1. Complete setup (one-time, ~5 minutes)
setwd("path/to/babynames")
source("setup.R")
main_setup()  # Installs packages + downloads data automatically

# 2. Load analysis system (after setup completes)
source("R/interface/simple_origin_analysis.R")

# 3. Analyze a name
analyze_name_origin_simple("Khaleesi", "F")
# Result: CA 2011, 75% confidence, Game of Thrones timing ✅
```

## 🔄 **Daily Usage (After Initial Setup)**

```r
# Start each session with environment check
source("setup.R")
quick_check()

# Load analysis functions
source("R/interface/simple_origin_analysis.R")

# Analyze away!
analyze_name_origin_simple("YourName", "F")
```

## 🎮 **Interactive Examples**

### **Game of Thrones Analysis**
```r
# Perfect test case - known cultural timing
analyze_name_origin_simple("Khaleesi", "F")

# Expected output:
# 🎯 Origin: CA in 2011
# ✅ High confidence result (75%)
# 📊 Matches Game of Thrones debut
```

### **Aiden Variants Comparison**
```r
compare_origins_simple("Aiden", "Ayden", "Jayden", sex = "M")

# Shows West Coast emergence patterns:
# Aiden:  CA 1995, 71% confidence
# Ayden:  WA 1995, 62% confidence
# Jayden: ND 1990, 45% confidence
```

### **Modern Invented Names**
```r
analyze_name_origin_simple("Nevaeh", "F")
# "Heaven" backwards - should show ~2001 emergence
```

## 📊 **Batch Analysis Examples**

### **Category Analysis**
```r
# Analyze entire categories at once
quick_batch_analysis()

# Runs:
# - Game of Thrones names
# - Aiden variants
# - Modern invented names
```

### **Custom Category**
```r
# Create your own analysis category
disney_names <- c("Elsa", "Anna", "Moana")

for (name in disney_names) {
  analyze_name_origin_simple(name, "F")
  cat("\n" %r% 40, "\n")  # Separator
}
```

## 🔍 **Name Investigation Examples**

### **Basic Classification**
```r
source("R/interface/quick_analysis.R")

# See how any name is classified
investigate_name("Taylor", "F")
investigate_name("Mason", "M")
investigate_name("Skylar", "both")  # Both sexes
```

### **Growth Pattern Analysis**
```r
# Compare traditional vs modern names
quick_compare("Michael", "Aiden", sex = "M")

# Expected pattern:
# Michael: ESTABLISHED (high baseline)
# Aiden: EMERGING (759x growth)
```

## 🗺️ **Geographic Analysis Examples**

### **Origin Detection**
```r
# Names with clear geographic origins
test_names <- c("Khaleesi", "Nevaeh", "Ayden", "Jayden")

for (name in test_names) {
  result <- investigate_origin(name, "F")
  if (!is.null(result)) {
    cat(name, ":", result$origin_state, result$origin_year, "\n")
  }
}
```

### **Regional Patterns**
```r
# Each analysis includes regional emergence:
analyze_name_origin_simple("Khaleesi", "F")

# Shows regional timing:
# West:      2011 (4 states)    ← Origin region
# South:     2012 (10 states)   ← Early spread
# Northeast: 2012 (4 states)
# Midwest:   2012 (5 states)
```

## 🧪 **Validation Examples**

### **System Testing**
```r
# Test the classification system
quick_validate()

# Expected results:
# ✅ Michael (M): ESTABLISHED
# ✅ Nevaeh (F): TRULY_NEW
# ✅ Aiden (M): EMERGING
```

### **Cultural Event Validation**
```r
# Test names against known cultural events
cultural_tests <- list(
  list("Khaleesi", "F", 2011, "Game of Thrones debut"),
  list("Elsa", "F", 2013, "Frozen movie release"),
  list("Bella", "F", 2008, "Twilight movie series")
)

for (test in cultural_tests) {
  name <- test[[1]]
  result <- investigate_origin(name, test[[2]])
  expected_year <- test[[3]]
  event <- test[[4]]

  cat(name, "- Expected:", expected_year, "for", event, "\n")
  if (!is.null(result)) {
    cat("  Actual:", result$origin_year, "\n")
    cat("  Match:", abs(result$origin_year - expected_year) <= 2, "\n\n")
  }
}
```

## 🐛 **Troubleshooting Examples**

### **Data Issues**
```r
# If you get errors, run diagnostics
source("examples/debug_data_loading.R")

# This will show:
# - Whether classification data loaded
# - Sample name lookups
# - System integration status
```

### **Name Not Found**
```r
# If a name isn't found, try variations
investigate_name("Katherine", "F")  # Will suggest: Catherine, Kathryn, etc.
```

### **Low Confidence Results**
```r
# Check if name meets minimum requirements
analyze_name_origin_simple("RareName", "F")

# For high confidence, names need:
# - Multiple states (≥5)
# - Adequate births (≥100 total)
# - Clear emergence pattern
```

## 🎯 **Research Examples**

### **Academic Use Case**
```r
# Export data for statistical analysis
name_data <- investigate_origin("Khaleesi", "F")
write.csv(name_data, "khaleesi_research_data.csv")

# Analyze multiple names for publication
research_names <- c("Khaleesi", "Daenerys", "Arya", "Sansa")
results <- lapply(research_names, function(name) {
  investigate_origin(name, "F")
})
names(results) <- research_names
```

### **Cultural Trend Study**
```r
# Study naming trends by decade
decades <- list(
  "1990s_innovations" = c("Aiden", "Ayden", "Jayden"),
  "2000s_creativity" = c("Nevaeh", "Jaelyn", "Kylee"),
  "2010s_media" = c("Khaleesi", "Daenerys", "Arya")
)

decade_results <- list()
for (decade in names(decades)) {
  decade_results[[decade]] <- list()
  for (name in decades[[decade]]) {
    decade_results[[decade]][[name]] <- investigate_origin(name, "F")
  }
}
```

## 💡 **Pro Tips**

### **Performance**
```r
# For large analyses, process in batches
large_name_list <- c("Name1", "Name2", ..., "Name100")
batch_size <- 10

for (i in seq(1, length(large_name_list), batch_size)) {
  batch <- large_name_list[i:min(i + batch_size - 1, length(large_name_list))]
  # Process batch
  gc()  # Clean memory between batches
}
```

### **Reliability**
```r
# Always check confidence scores
result <- investigate_origin("TestName", "F")
if (!is.null(result) && result$confidence_score >= 0.7) {
  cat("High confidence result - reliable for research\n")
} else {
  cat("Low confidence - interpret cautiously\n")
}
```

### **Documentation**
```r
# Keep track of your analyses
analysis_log <- data.frame(
  name = character(),
  date = as.Date(character()),
  result = character(),
  notes = character()
)

# Add entries as you analyze
analysis_log <- rbind(analysis_log, data.frame(
  name = "Khaleesi",
  date = Sys.Date(),
  result = "CA 2011, 75% conf",
  notes = "Matches GoT debut perfectly"
))
```

---

**Ready to start analyzing?** Begin with `analyze_name_origin_simple("YourFavoriteName", "F")` and explore the results!