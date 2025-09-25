# Baby Names Analysis Project

**Advanced R-based analysis system for SSA baby names data focusing on cultural diversity, geographic diffusion patterns, and interactive exploration of naming trends.**

[![Language](https://img.shields.io/badge/Language-R-blue.svg)](https://r-project.org/)
[![Version](https://img.shields.io/badge/Version-2.0.0-green.svg)](#changelog)
[![Status](https://img.shields.io/badge/Status-Week%202%20Complete-brightgreen.svg)](#current-capabilities)

## 🎯 **Project Overview**

This project has evolved from basic diversity metrics to a sophisticated **name classification and origin detection system** that can:

- **Classify 100K+ names** into meaningful categories (ESTABLISHED, TRULY_NEW, EMERGING)
- **Detect geographic origins** for modern invented names with confidence scoring
- **Track cultural diffusion** patterns across US states and regions
- **Validate against real events** (Game of Thrones emergence, cultural trends)

## ⚡ **Quick Start**

```r
# 1. Complete setup (one-time, ~5 minutes)
source("setup.R")
main_setup()  # Installs packages, downloads data, generates classifications

# 2. Load analysis system
source("R/interface/simple_origin_analysis.R")

# 3. Analyze any name's origin and spread
analyze_name_origin_simple("Khaleesi", "F")
# Result: Origin CA 2011, 80% confidence, matches Game of Thrones debut

# 4. Compare multiple names
compare_origins_simple("Aiden", "Ayden", "Jayden", sex = "M")

# 5. Run batch analysis on interesting categories
quick_batch_analysis()
```

## 🚀 **Current Capabilities (Week 2 Complete)**

### **Name Classification System** ✅
- **36,192 names** classified as suitable for origin analysis
- **TRULY_NEW**: 13,851 names (Khaleesi, Nevaeh, Daenerys)
- **EMERGING**: 22,341 names (Aiden variants, modern inventions)
- **High accuracy** validated against known cultural events

### **Enhanced Origin Detection** ✅
- **Population-weighted algorithm** prevents small-state bias
- **Confidence scoring** (50-90% range) with reliability indicators
- **Geographic spread visualization** showing diffusion patterns
- **Regional analysis** across Northeast, South, Midwest, West

### **Interactive Analysis Tools** ✅
- `analyze_name_origin_simple()` - Complete origin analysis
- `compare_origins_simple()` - Multi-name comparisons
- `investigate_name()` - Classification details
- `quick_batch_analysis()` - Category analysis

## 📊 **Validated Examples**

| Name | Classification | Origin | Year | Confidence | Cultural Event |
|------|---------------|---------|------|------------|----------------|
| **Khaleesi** | TRULY_NEW | CA | 2011 | 75% | Game of Thrones debut |
| **Nevaeh** | TRULY_NEW | Multiple | 2001 | 68% | "Heaven" backwards trend |
| **Ayden** | TRULY_NEW | WA | 1995 | 62% | West Coast emergence |
| **Aiden** | EMERGING | CA | 1995 | 71% | Irish name popularization |

## 📁 **Repository Structure**

```
babynames/
├── R/                          # Core R modules
│   ├── core/                   # Data management & caching
│   ├── analysis/               # Classification & origin detection
│   ├── interface/              # User-facing functions
│   └── utilities/              # Helper functions
├── docs/                       # Documentation
├── examples/                   # Usage examples & test scripts
├── tests/                      # Validation & testing
├── data/                       # Cached data (auto-generated)
└── README.md                   # This file
```

## 📚 **Documentation**

- **[User Guide](docs/USER_GUIDE.md)** - Step-by-step tutorials and examples
- **[API Reference](docs/API_REFERENCE.md)** - Complete function documentation
- **[Changelog](docs/CHANGELOG.md)** - Version history and updates
- **[Technical Architecture](docs/TECHNICAL_ARCHITECTURE.md)** - System design

## 🛠 **Installation & Setup**

### **Method 1: Automatic Setup (Recommended)**
```r
# Set working directory to project folder
setwd("path/to/babynames")

# Complete automatic setup
source("setup.R")
main_setup()
# This installs packages, downloads data, and sets everything up
```

### **Method 2: Manual Installation**
```r
# Install required packages manually
install.packages(c("data.table", "dplyr", "stringr", "curl"))

# Then run classification setup
source("tests/test_name_classification.R")
```

### **Daily Use (After Setup)**
```r
# Quick environment check before each session
source("setup.R")
quick_check()  # Verifies everything is ready
```

## 🎮 **Example Analysis Workflows**

### **Game of Thrones Names Analysis**
```r
source("R/interface/week2_interface.R")
analyze_got_origins()  # Analyzes Khaleesi, Daenerys, Arya
```

### **Aiden Variants Comparison**
```r
analyze_aiden_variants()  # Compares Aiden, Ayden, Jayden, Brayden
```

### **Custom Name Investigation**
```r
explore_name_origin("YourName", "F")  # Complete analysis with visualizations
```

## 🧪 **Testing & Validation**

The system has been extensively tested with:
- **Known cultural events** (Game of Thrones 2011, Heaven backwards trend)
- **Historical emergence patterns** (Aiden variants from West Coast)
- **Classification accuracy** against manually verified examples

Run validation:
```r
# First ensure environment is set up
source("setup.R")
quick_check()

# Then run diagnostics
source("examples/debug_data_loading.R")  # System diagnostics
source("examples/test_fixed_origins.R")  # Core functionality tests
```

## 📈 **Project Roadmap**

- ✅ **Week 1**: Name classification system (36K names categorized)
- ✅ **Week 2**: Enhanced origin detection with confidence scoring
- 🔄 **Week 3**: Advanced visualization and regional clustering analysis
- 📋 **Week 4**: Predictive modeling and comparative cultural analysis

## 🤝 **Contributing**

This is a research project focused on cultural naming patterns. For technical details about the algorithms and system architecture, see [Technical Architecture](docs/TECHNICAL_ARCHITECTURE.md).

## 📄 **License**

This project is for research and educational purposes. Baby names data is provided by the Social Security Administration.

## 🏆 **Key Achievement**

Successfully solved the "Michael originated in Alaska 1990" problem by implementing sophisticated classification and population-weighted origin detection, producing culturally meaningful results for modern name analysis.

---

**Ready to explore name origins?** Start with `source("R/interface/simple_origin_analysis.R")` and `analyze_name_origin_simple("YourName", "F")`!