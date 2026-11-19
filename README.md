# MSBA-Capstone-1

## Project Overview

This repository contains my work for the Home Credit Default Risk project as part of my graduate coursework in the Master of Science in Business Analytics program.

The project explores how applicant characteristics and alternative financial information can help identify repayment risk and improve lending decisions for individuals with limited traditional credit histories.

The analysis follows the CRISP-DM analytics lifecycle, progressing through business understanding, exploratory data analysis, data preparation, predictive modeling, and evaluation.

## Business Problem

Home Credit seeks to improve its ability to distinguish between applicants who are likely to repay their loans and those who may experience payment difficulties.

The project investigates applicant characteristics, financial indicators, and other available information to identify patterns associated with repayment outcomes. The ultimate goal is to support more informed lending decisions while balancing financial risk with responsible access to credit.

## Project Structure

- `data/` – Original application datasets and processed data (excluded from GitHub).
- `notebooks/` – Quarto notebooks containing exploratory analysis and project findings.
- `E.Mecham.Data.Preparation.R` – Reusable R functions for data cleaning, feature engineering, and preprocessing.
- `README.md` – Project documentation.

## Exploratory Data Analysis

The exploratory data analysis examined the Home Credit application training and test datasets, focusing on:

- Dataset structure, observation counts, and variable types.
- Missing values and patterns of information availability.
- Duplicate application identifiers.
- Special placeholder values in employment duration.
- Extreme financial observations and skewed distributions.
- Relationships between applicant characteristics and payment difficulty.
- Differences in external credit scores and financial characteristics across repayment outcomes.

EDA findings informed the data cleaning decisions and feature engineering procedures implemented in the data preparation script.

## Data Preparation

### Purpose

The `E.Mecham.Data.Preparation.R` script translates findings from exploratory data analysis into reusable, reproducible data preparation functions.

The script applies consistent transformations to training and test data while preventing data leakage by calculating preprocessing parameters exclusively from the training dataset.

### Data Transformations

The script implements the following EDA-informed decisions:

**1. Demographic and Employment Features**
- Converts negative birth-day values into applicant age in years.
- Converts negative employment duration values into positive years.
- Identifies the special `365243` employment placeholder, creates a missingness indicator, and excludes the placeholder from actual employment duration calculations.
- Creates age categories for additional analysis.

**2. Financial Features**
- Creates credit-to-income, annuity-to-income, and credit-to-annuity ratios.
- Creates log-transformed income and credit variables to address skewed financial distributions.
- Retains original financial variables and extreme observations rather than automatically deleting them.

**3. Missing Data Treatment**
- Creates missingness indicators for variables containing missing observations.
- Calculates numeric imputation medians using training data only.
- Replaces missing categorical values with a separate `"Missing"` category.

**4. Train/Test Consistency**
- Learns preprocessing parameters from training data.
- Reuses the same parameters when transforming test data.
- Maintains identical predictor columns and column ordering across training and test datasets.
- Retains `TARGET` only in the training dataset.

### Train/Test Validation

The script includes validation checks to confirm:

- Training and test predictor columns match.
- No missing values remain after preprocessing.
- Application identifiers are unique within each dataset.
- The target variable is present in training data and absent from test data.

### Inputs

The script uses the following original application datasets:

- `data/application_train.csv` – 307,511 observations, including the `TARGET` variable.
- `data/application_test.csv` – 48,744 observations, without the `TARGET` variable.

Supplementary Home Credit datasets are not included in this stage of the project.

### Outputs

Prepared datasets and learned preprocessing parameters are saved in `data/processed/`:

- `prepared_train.rds` – Prepared training dataset.
- `prepared_test.rds` – Prepared test dataset.
- `preprocessing_parameters.rds` – Training-derived preprocessing parameters used for consistent transformations.

Raw data and processed outputs are excluded from version control.

### How to Run

1. Clone this repository to your local machine.
2. Place the original `application_train.csv` and `application_test.csv` files in the `data/` directory.
3. Open the project in Positron or another R-compatible environment.
4. Ensure the required R packages are installed, including `tidyverse` and any additional packages referenced in the script.
5. Run the following command from the project root directory:

```r
source("E.Mecham.Data.Preparation.R")
```

The script loads the original datasets, applies the preprocessing functions, validates train/test consistency, and saves the prepared datasets and preprocessing parameters.

## Reproducibility and Version Control

The project uses GitHub for version control and documentation. The data preparation script is maintained separately from the exploratory notebook to support reproducibility, maintainability, and consistent processing as the project progresses.

Original datasets, processed data files, and intermediate R objects are excluded from version control through `.gitignore`.

## Tools and Technologies

- R
- Positron
- Quarto
- Git and GitHub
- tidyverse
- ggplot2
