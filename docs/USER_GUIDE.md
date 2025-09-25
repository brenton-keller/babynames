# User Guide - Baby Names Analysis Project

Complete tutorial for using the Baby Names Analysis system, from basic setup to advanced cultural analysis.

## 🎯 **Table of Contents**

1. [Getting Started](#getting-started)
2. [Basic Name Analysis](#basic-name-analysis)
3. [Origin Detection & Geographic Analysis](#origin-detection--geographic-analysis)
4. [Advanced Analysis Workflows](#advanced-analysis-workflows)
5. [Troubleshooting](#troubleshooting)
6. [Case Studies](#case-studies)

---

## 🚀 **Getting Started**

### **Complete Setup (Recommended)**
```r
# Set working directory to project folder
setwd("path/to/babynames")

# Automatic complete setup (installs packages + downloads data)
source("setup.R")
main_setup()

# Expected output:
# 📦 Installing/loading packages
# 📊 Downloading data (~5 minutes)
# ✅ Classified 36,192 names suitable for origin analysis
# 🎉 Setup complete!
```

### **Manual Setup (Alternative)**
```r
# Install packages manually
install.packages(c("data.table", "dplyr", "stringr", "curl"))

# Load packages
library(data.table)
library(dplyr)
library(stringr)
library(curl)

# Download and classify names
source("tests/test_name_classification.R")
```

### **Quick Test**
```r
# Verify environment is ready
source("setup.R")
quick_check()

# Load the analysis system
source("R/interface/simple_origin_analysis.R")

# Test with a simple analysis
analyze_name_origin_simple("Khaleesi", "F")

# Expected result: CA 2011, ~75% confidence
```

### **Daily Usage (After Initial Setup)**
```r
# Start each analysis session with:
source("setup.R")
quick_check()  # Ensures everything is loaded and ready

# Then proceed with analysis:
source("R/interface/simple_origin_analysis.R")
analyze_name_origin_simple("YourName", "F")
```

---

## 📊 **Basic Name Analysis**

### **Understanding Name Classifications**

The system categorizes names into five types:

| Classification | Description | Examples | Count |
|---------------|-------------|----------|--------|
| **ESTABLISHED** | Popular before 1990 | Michael, Ashley, Christopher | 755 |
| **TRULY_NEW** | Never existed before 1990s | Khaleesi, Nevaeh, Daenerys | 13,851 |
| **EMERGING** | Rare before 1990, popular after | Aiden, Jayden, Brayden | 22,341 |
| **RISING** | Established but accelerating | Some traditional names | 62 |
| **OTHER** | Doesn't fit patterns | Various | 63,064 |

### **Investigating Individual Names**

#### **Basic Investigation**
```r
source("R/interface/quick_analysis.R")

# Investigate any name
investigate_name("Ayden", "M")
```

**Output:**
```
🔍 QUICK INVESTIGATION: Ayden
========================================

📊 Ayden ( M ) → TRULY_NEW
🔒 Confidence: HIGH
📈 1980s: 0 births | 1990s+: 87,801 births
🎯 Origin Analysis: ✅ Eligible
```

#### **Comparing Multiple Names**
```r
# Compare names side by side
quick_compare("Aiden", "Ayden", "Jayden", sex = "M")
```

**Output:**
```
Name         Class        Baseline   Modern     Growth
----------------------------------------------------
Aiden        EMERGING     76         252,528    759.0x
Ayden        TRULY_NEW    0          87,801     NEW
Jayden       EMERGING     88         249,145    566.0x
```

### **System Validation**
```r
# Validate classification accuracy
quick_validate()
```

This tests the system against known cases like:
- Michael → ESTABLISHED (correct)
- Nevaeh → TRULY_NEW (correct)
- Aiden → EMERGING (correct)

---

## 🗺️ **Origin Detection & Geographic Analysis**

### **Week 2 Core Functionality**

#### **Simple Origin Analysis (Recommended)**
```r
source("R/interface/simple_origin_analysis.R")

# Analyze name origin with full details
analyze_name_origin_simple("Khaleesi", "F")
```

**Complete Output:**
```
🎯 SIMPLE ORIGIN ANALYSIS: Khaleesi (F)
==================================================

📊 Classification Status:
📊 Khaleesi ( F ) → TRULY_NEW
🔒 Confidence: HIGH
📈 1980s: 0 births | 1990s+: 5,125 births
🎯 Origin Analysis: ✅ Eligible

🔍 Origin Detection:
📍 Khaleesi (F)
   Origin: CA in 2011
   Confidence: 75%
   Early births: 898
   ✅ High confidence result

🗺️ State Adoption Timeline:
-----------------------------------
Rank State    Year   Births
-----------------------------------
1    CA       2011   5        ← ORIGIN
2    FL       2012   14       Early adopter
3    NY       2012   14       Early adopter
4    TX       2012   10       Early adopter
5    IL       2012   7        Early adopter
... and 34 more states

🌎 Regional Emergence:
-------------------------
Region       Year   States
-------------------------
West         2011   4
South        2012   10
Northeast    2012   4
Midwest      2012   5
```

#### **Origin Comparison**
```r
# Compare origins of related names
compare_origins_simple("Aiden", "Ayden", "Jayden", sex = "M")
```

**Summary Table:**
```
📊 COMPARISON SUMMARY
========================================
Name         Origin   Year   Conf%  Births
----------------------------------------
Aiden        CA       1995   71.0   156
Ayden        WA       1995   62.0   187
Jayden       ND       1990   45.0   164
```

### **Confidence Score Interpretation**

| Confidence | Meaning | Reliability |
|------------|---------|-------------|
| **70-90%** | High confidence | Very reliable result |
| **50-70%** | Moderate confidence | Generally reliable |
| **30-50%** | Low confidence | Multiple possible origins |
| **<30%** | Very low confidence | Unreliable result |

---

## 🎮 **Advanced Analysis Workflows**

### **Pop Culture Names Analysis**

#### **Game of Thrones Names**
```r
source("R/interface/week2_interface.R")

# Comprehensive GoT analysis
analyze_got_origins()
```

This analyzes:
- **Khaleesi**: Expected CA 2011 (matches TV debut)
- **Daenerys**: Expected 2012 emergence
- **Arya**: Traditional name, different pattern

#### **Custom Pop Culture Analysis**
```r
# Add your own pop culture names
custom_names <- c("Elsa", "Anna", "Moana")  # Disney names
for (name in custom_names) {
  analyze_name_origin_simple(name, "F")
}
```

### **Trend Category Analysis**

#### **Aiden Variants (Emerging Names)**
```r
analyze_aiden_variants()
```

Analyzes the complete Aiden family:
- Aiden, Ayden, Jayden, Brayden, Kaden
- Shows West Coast emergence patterns
- Demonstrates cultural diffusion

#### **Modern Invented Names**
```r
analyze_modern_invented()
```

Studies names like:
- **Nevaeh** ("Heaven" backwards)
- **Jaelyn**, **Kylee**, **Destinee**
- Shows modern naming creativity patterns

### **Batch Analysis**
```r
# Analyze multiple categories at once
quick_batch_analysis()
```

This runs:
1. Game of Thrones analysis
2. Aiden variants comparison
3. Modern invented names study

---

## 🧪 **Troubleshooting**

### **Common Issues & Solutions**

#### **1. Data Loading Problems**
```r
# Debug data loading issues
source("examples/debug_data_loading.R")
```

**Common Causes:**
- Missing classification data (run `source("tests/test_name_classification.R")`)
- Corrupted cache files (delete `data/` folder and re-run setup)

#### **2. Name Not Found**
```r
# If name not found, check similar spellings
investigate_name("Aiden", "M")  # Will suggest alternatives if not found
```

**Tips:**
- Use exact spelling with proper capitalization
- Try alternative spellings (Aiden vs Ayden)
- Check both male and female versions

#### **3. Low Confidence Results**
```r
# Check if name meets minimum requirements
analyze_name_origin_simple("RareName", "F")
```

**Requirements for High Confidence:**
- Name appears in multiple states (≥5)
- Sufficient total births (≥100)
- Clear emergence pattern
- Consistent early appearance

#### **4. Visualization Issues**
```r
# Use simple analysis if visualization functions hang
analyze_name_origin_simple("Name", "F")  # Safe version
# Avoid: explore_name_origin("Name", "F")  # May hang
```

### **System Diagnostics**
```r
# Complete system check
source("examples/test_fixed_origins.R")
```

---

## 📚 **Case Studies**

### **Case Study 1: Game of Thrones Impact**

**Background:** Game of Thrones TV series premiered April 2011.

**Analysis:**
```r
analyze_name_origin_simple("Khaleesi", "F")
```

**Results:**
- **Origin**: California, 2011
- **Confidence**: 75% (High)
- **Pattern**: Immediate nationwide spread after 2011
- **Validation**: Perfect timing match with cultural event

**Interpretation:**
- California's entertainment industry likely drove initial adoption
- Rapid diffusion shows strong cultural influence
- High confidence due to clear emergence timing

### **Case Study 2: West Coast Name Innovation**

**Background:** Analyzing the "Aiden" phenomenon.

**Analysis:**
```r
compare_origins_simple("Aiden", "Ayden", "Jayden", sex = "M")
```

**Results:**
- **Aiden**: CA 1995, 71% confidence
- **Ayden**: WA 1995, 62% confidence
- **Jayden**: ND 1990, 45% confidence

**Interpretation:**
- West Coast (CA, WA) leads naming innovation
- Similar timing suggests cultural cross-pollination
- Variations spread from multiple origin points

### **Case Study 3: Modern Invented Names**

**Background:** The "Nevaeh" phenomenon (Heaven backwards).

**Analysis:**
```r
analyze_name_origin_simple("Nevaeh", "F")
```

**Expected Results:**
- **Origin**: Multiple states around 2001
- **Pattern**: Rapid nationwide adoption
- **Cultural Context**: Creative modern naming trend

---

## 🎓 **Advanced Tips**

### **Research Applications**

#### **Academic Research**
```r
# Export data for statistical analysis
export_analysis("Khaleesi", "khaleesi_analysis.csv")
```

#### **Cultural Trend Analysis**
```r
# Analyze name emergence by decade
decades <- list(
  "1990s" = c("Aiden", "Ayden"),
  "2000s" = c("Nevaeh", "Jaelyn"),
  "2010s" = c("Khaleesi", "Daenerys")
)

for (decade in names(decades)) {
  message("=== ", decade, " ===")
  for (name in decades[[decade]]) {
    analyze_name_origin_simple(name, "F")
  }
}
```

### **Performance Optimization**

#### **Large-Scale Analysis**
```r
# For analyzing many names, use batch processing
names_list <- c("Name1", "Name2", "Name3")
results <- list()

for (name in names_list) {
  results[[name]] <- investigate_origin(name, "F")
}
```

#### **Memory Management**
```r
# Clear memory between large analyses
gc()  # Garbage collection
```

---

## 🔗 **Next Steps**

- **Week 3 Development**: Enhanced visualization and regional clustering
- **Week 4 Development**: Predictive modeling and comparative analysis
- **Research Applications**: Academic papers and cultural studies

For technical details, see [API Reference](API_REFERENCE.md)
For project updates, see [Changelog](CHANGELOG.md)