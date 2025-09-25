# API Reference - Baby Names Analysis Project

Complete documentation for all functions in the Baby Names Analysis system.

## 📚 **Table of Contents**

- [Core Functions](#core-functions)
- [Analysis Functions](#analysis-functions)
- [Interface Functions](#interface-functions)
- [Visualization Functions](#visualization-functions)
- [Utility Functions](#utility-functions)

---

## 🔧 **Core Functions**

### Data Management

#### `get_ssa_babynames(include_state = TRUE)`
Downloads SSA baby names data with smart caching.

**Parameters:**
- `include_state` (logical): Download state-level data in addition to national

**Returns:**
- List with `national` and `state` data.table objects

**Example:**
```r
source("R/core/data_acquisition.R")
data <- get_ssa_babynames(include_state = TRUE)
# National: 2.1M rows (1880-2024)
# State: 6.6M rows (1910-2024)
```

#### `load_babynames_cached(include_state = TRUE)`
Loads cached babynames data with freshness checking.

**Parameters:**
- `include_state` (logical): Include state data

**Returns:**
- List with cached data or NULL if cache unavailable

**Example:**
```r
source("R/core/data_cache_manager.R")
data <- load_babynames_cached(include_state = TRUE)
```

---

## 🧮 **Analysis Functions**

### Name Classification

#### `classify_names_for_analysis(babynames_list, ...)`
**Week 1 Core Function** - Classifies names into analysis categories.

**Parameters:**
- `babynames_list`: Output from `get_ssa_babynames()`
- `baseline_years`: Years for baseline (default: 1980:1989)
- `modern_start_year`: Start of modern period (default: 1990)

**Returns:**
- List with `classified_names` data.table and summary statistics

**Classifications:**
- **ESTABLISHED**: Popular before 1990 (Michael, Ashley)
- **TRULY_NEW**: Never existed before 1990 (Khaleesi, Nevaeh)
- **EMERGING**: Rare before 1990, popular after (Aiden, Jayden)
- **RISING**: Established but accelerating growth
- **OTHER**: Doesn't fit standard patterns

**Example:**
```r
source("R/analysis/name_classifier.R")
data <- get_ssa_babynames()
classifications <- classify_names_for_analysis(data)
# Result: 36,192 names suitable for origin analysis
```

### Origin Detection

#### `find_enhanced_origins(state_dt, min_total_births = 100, min_states = 5, confidence_threshold = 0.5)`
**Week 2 Core Function** - Detects geographic origins for suitable names.

**Parameters:**
- `state_dt`: State-level data.table
- `min_total_births`: Minimum total births to analyze
- `min_states`: Minimum states name must appear in
- `confidence_threshold`: Minimum confidence for reliable results

**Returns:**
- List with `all_origins`, `confident_origins`, and summary statistics

**Algorithm Features:**
- Population-weighted analysis prevents small-state bias
- Multi-factor confidence scoring (50-90% range)
- Early emergence detection with consistency weighting

**Example:**
```r
source("R/analysis/enhanced_origin_detection.R")
state_data <- load_babynames_cached(include_state = TRUE)$state
origins <- find_enhanced_origins(state_data)
```

#### `investigate_origin(name_to_investigate, sex_to_investigate = "both")`
Analyzes origin for a specific name with detailed output.

**Parameters:**
- `name_to_investigate`: Name to analyze
- `sex_to_investigate`: "M", "F", or "both"

**Returns:**
- data.table with origin details and confidence scores

**Example:**
```r
result <- investigate_origin("Khaleesi", "F")
# Expected: CA 2011, 75% confidence
```

---

## 🖥️ **Interface Functions**

### Week 1 Interactive Analysis

#### `investigate_name(name, sex = "both", show_plot = TRUE)`
Quick investigation of name classification and trends.

**Parameters:**
- `name`: Name to investigate
- `sex`: "M", "F", or "both"
- `show_plot`: Create visualization

**Returns:**
- Classification data with statistics

**Example:**
```r
source("R/interface/quick_analysis.R")
investigate_name("Ayden", "M")
# Shows: TRULY_NEW, 87,801 births, eligible for origin analysis
```

#### `quick_compare(..., sex = "F")`
Compare multiple names side-by-side.

**Parameters:**
- `...`: Names to compare (flexible input)
- `sex`: Sex to analyze

**Example:**
```r
quick_compare("Khaleesi", "Daenerys", "Arya", sex = "F")
```

#### `quick_validate()`
Validates classification system against known test cases.

**Returns:**
- Validation results for Michael, Ashley, Nevaeh, Aiden, etc.

### Week 2 Origin Analysis

#### `analyze_name_origin_simple(name, sex = "F")`
**Main Week 2 Function** - Complete origin analysis without problematic visualizations.

**Parameters:**
- `name`: Name to analyze
- `sex`: Sex to analyze

**Returns:**
- Origin data with confidence scoring

**Output Includes:**
- Classification status
- Origin state and year
- Confidence level (High/Moderate/Low)
- State adoption timeline
- Regional emergence patterns

**Example:**
```r
source("R/interface/simple_origin_analysis.R")
analyze_name_origin_simple("Ayden", "M")
# Result: WA 1995, 62% confidence, West Coast → National spread
```

#### `compare_origins_simple(..., sex = "F")`
Compare origins of multiple names safely.

**Parameters:**
- `...`: Names to compare
- `sex`: Sex filter

**Example:**
```r
compare_origins_simple("Aiden", "Ayden", "Jayden", sex = "M")
```

#### `quick_batch_analysis()`
Runs analysis on interesting name categories.

**Categories Analyzed:**
- Game of Thrones names (Khaleesi, Daenerys)
- Aiden variants (Aiden, Ayden, Jayden, Brayden)
- Modern invented names (Nevaeh, Jaelyn)

### Specialized Analysis

#### `analyze_got_origins()`
Game of Thrones names analysis with cultural context.

#### `analyze_aiden_variants()`
Comprehensive analysis of Aiden-style names.

#### `analyze_modern_invented()`
Analysis of modern invented names category.

---

## 📊 **Visualization Functions**

#### `visualize_name_spread(name_to_plot, sex_to_plot = "F", years_to_plot = NULL, min_births = 5)`
Creates geographic spread visualization.

**Parameters:**
- `name_to_plot`: Name to visualize
- `sex_to_plot`: Sex to analyze
- `years_to_plot`: Year range (auto-detected if NULL)
- `min_births`: Minimum births to show state

**Creates:**
- Timeline plot of state adoptions
- Regional emergence analysis

**Example:**
```r
source("R/interface/origin_visualization.R")
visualize_name_spread("Khaleesi", "F")
```

#### `compare_spread_patterns(names_to_compare, sex_filter = "F")`
Compare spread patterns across multiple names.

**Note:** Fixed version with robust error handling to prevent hanging.

---

## 🧪 **Utility Functions**

#### `quick_setup(reload_data = FALSE)`
Sets up analysis environment with cached data.

#### `show_stats(sex = "both")`
Shows classification distribution statistics.

#### `random_examples(classification = "EMERGING", sex = "M", n = 5)`
Get random examples from classification categories.

#### `export_analysis(name, filename = NULL)`
Export analysis results to CSV.

---

## 📋 **Data Structures**

### Classification Data Structure
```r
classified_names
├── name                        # Name (title case)
├── sex                        # "M" or "F"
├── classification             # Category (ESTABLISHED, TRULY_NEW, etc.)
├── classification_confidence  # "HIGH", "MEDIUM", "LOW"
├── baseline_total_births      # Births 1980-1989
├── modern_total_births        # Births 1990+
├── growth_ratio              # Modern/baseline ratio
├── modern_first_year         # First appearance in modern era
└── modern_peak_year          # Peak year in modern era
```

### Origin Data Structure
```r
origins
├── name                    # Name
├── sex                     # Sex
├── origin_state           # Most likely origin state
├── origin_year           # Year of origin
├── confidence_score      # 0.0-1.0 confidence
├── total_early_births    # Births in early years
├── n_early_states        # States in early emergence
└── classification        # Name category
```

---

## ⚠️ **Common Issues & Solutions**

### Data Loading Issues
```r
# Debug data loading
source("examples/debug_data_loading.R")
```

### Variable Name Conflicts
- Fixed in Week 2: Use explicit column references
- Example: `data$classified_names$name == search_name`

### Visualization Hanging
- Use `simple_origin_analysis.R` functions for reliable output
- Avoid `compare_spread_patterns()` in problematic environments

### Low Confidence Scores
- Week 2 improved algorithm provides 50-90% confidence range
- Use `confidence_threshold = 0.5` for moderate confidence results

---

## 🔄 **Version History**

- **v1.0.0**: Week 1 complete - Name classification system
- **v2.0.0**: Week 2 complete - Enhanced origin detection with confidence scoring

---

For usage examples and tutorials, see [User Guide](USER_GUIDE.md).