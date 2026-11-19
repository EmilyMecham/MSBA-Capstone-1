
# ============================================================
# HOME CREDIT DEFAULT RISK
# Data Preparation and Feature Engineering
# ============================================================
#
# Purpose:
# Prepare application training and test datasets for predictive
# modeling using consistent, reusable data transformations.
#
# EDA decisions implemented:
# - Preserve applicant records rather than using complete-case deletion.
# - Investigate and preserve informative missingness.
# - Treat DAYS_EMPLOYED = 365243 as a special coded value.
# - Retain extreme financial observations initially.
# - Convert negative birth and employment days into years.
# - Exclude application identifiers from predictive features.
#
# Inputs:
#   data/application_train.csv
#   data/application_test.csv
#
# Outputs:
#   data/prepared_train.rds
#   data/prepared_test.rds
#   data/preprocessing_parameters.rds
#
# ============================================================


# 1. LOAD REQUIRED PACKAGES
# ============================================================

library(tidyverse)
library(janitor)
library(here)


# 2. IMPORT APPLICATION DATA
# ============================================================

# Identify project root directory
project_root <- here::here()

# Define input file locations
train_path <- file.path(
  project_root, "data", "application_train.csv"
)

test_path <- file.path(
  project_root, "data", "application_test.csv"
)

# Confirm required input files exist
stopifnot(
  file.exists(train_path),
  file.exists(test_path)
)

# Import training data
application_train <- read_csv(
  train_path,
  show_col_types = FALSE
) %>%
  clean_names()

# Import test data
application_test <- read_csv(
  test_path,
  show_col_types = FALSE
) %>%
  clean_names()


# 3. INITIAL DATA INTEGRITY CHECKS
# ============================================================

# Confirm required identifier and target variables exist
stopifnot(
  "sk_id_curr" %in% names(application_train),
  "sk_id_curr" %in% names(application_test),
  "target" %in% names(application_train),
  !"target" %in% names(application_test)
)

# Check for duplicate application identifiers
stopifnot(
  !anyDuplicated(application_train$sk_id_curr),
  !anyDuplicated(application_test$sk_id_curr)
)

# Confirm training and test datasets contain identical
# predictor columns, excluding TARGET
train_predictors <- setdiff(
  names(application_train), "target"
)

test_predictors <- names(application_test)

stopifnot(
  setequal(train_predictors, test_predictors)
)

# Reorder test columns to match training predictors
application_test <- application_test %>%
  select(all_of(train_predictors))

# Confirm training and test application IDs do not overlap
stopifnot(
  length(intersect(
    application_train$sk_id_curr,
    application_test$sk_id_curr
  )) == 0
)

# Display initial dataset dimensions
cat("\nDATA LOADING SUCCESSFUL\n")

cat(
  "Training observations:",
  nrow(application_train), "\n"
)

cat(
  "Test observations:",
  nrow(application_test), "\n"
)

cat(
  "Predictor variables:",
  length(train_predictors), "\n"
)

cat("\nINITIAL INTEGRITY CHECKS PASSED\n")


# ============================================================
# 4. FEATURE ENGINEERING
# ============================================================

engineer_features <- function(data) {

  # Confirm required variables are available
  required_columns <- c(
    "days_birth",
    "days_employed",
    "amt_income_total",
    "amt_credit",
    "amt_annuity"
  )

  stopifnot(
    all(required_columns %in% names(data))
  )

  data %>%
    mutate(

      # EDA decision: Convert negative birth days into age in years
      age_years = -days_birth / 365.25,

      # EDA decision: Preserve the special employment placeholder
      # before excluding it from actual employment calculations
      days_employed_placeholder = as.integer(
        coalesce(days_employed == 365243, FALSE)
      ),

      # Convert negative employment days into positive years
      # The special placeholder is treated as missing
      employment_years = if_else(
        days_employed_placeholder == 1,
        NA_real_,
        -as.numeric(days_employed) / 365.25
      ),

      # EDA decision: Retain extreme financial observations
      # while creating additional financial predictors

      # Requested credit relative to annual income
      credit_income_ratio = if_else(
        amt_income_total > 0,
        amt_credit / amt_income_total,
        NA_real_
      ),

      # Loan annuity relative to annual income
      annuity_income_ratio = if_else(
        amt_income_total > 0,
        amt_annuity / amt_income_total,
        NA_real_
      ),

      # Requested credit relative to loan annuity
      credit_annuity_ratio = if_else(
        amt_annuity > 0,
        amt_credit / amt_annuity,
        NA_real_
      ),

      # Reduce right skew while retaining original financial values
      log_income = log1p(amt_income_total),

      log_credit = log1p(amt_credit),

      # Create interpretable age categories
      age_group = cut(
        age_years,
        breaks = c(-Inf, 25, 35, 45, 55, Inf),
        labels = c(
          "Under 25",
          "25-34",
          "35-44",
          "45-54",
          "55 and older"
        ),
        right = FALSE
      )
    )
}


# ============================================================
# 5. FIT PREPROCESSING PARAMETERS
# ============================================================

fit_preprocessor <- function(training_data) {

  # Apply deterministic feature engineering first
  training_features <- engineer_features(training_data)

  # Identify predictors, excluding the target and application ID
  predictor_columns <- setdiff(
    names(training_features),
    "target"
  )

  # Identify variables containing missing observations
  # These will receive missingness indicator features
  missing_columns <- predictor_columns[
    map_lgl(
      training_features[predictor_columns],
      anyNA
    )
  ]

  missing_columns <- setdiff(
    missing_columns,
    "sk_id_curr"
  )

  # Identify numeric predictors
  numeric_columns <- predictor_columns[
    map_lgl(
      training_features[predictor_columns],
      is.numeric
    )
  ]

  numeric_columns <- setdiff(
    numeric_columns,
    "sk_id_curr"
  )

  # Identify categorical predictors
  categorical_columns <- predictor_columns[
    map_lgl(
      training_features[predictor_columns],
      ~ is.character(.x) || is.factor(.x)
    )
  ]

  # Calculate numeric medians using training data only
  training_medians <- map_dbl(
    training_features[numeric_columns],
    ~ median(.x, na.rm = TRUE)
  )

  # Prevent silent failures when a variable has no usable
  # training observations
  if (any(!is.finite(training_medians))) {
    stop(
      "At least one numeric predictor has no valid ",
      "training median. Investigate before proceeding."
    )
  }

  # Store all learned preprocessing information
  parameters <- list(

    numeric_columns = numeric_columns,

    categorical_columns = categorical_columns,

    missing_columns = missing_columns,

    training_medians = training_medians,

    predictor_columns = predictor_columns,

    output_columns = c(
      predictor_columns,
      paste0(missing_columns, "_was_missing")
    )
  )

  cat("\nPREPROCESSING PARAMETERS CREATED\n")

  cat(
    "Numeric variables:",
    length(numeric_columns), "\n"
  )

  cat(
    "Categorical variables:",
    length(categorical_columns), "\n"
  )

  cat(
    "Missingness indicators:",
    length(missing_columns), "\n"
  )

  return(parameters)
}

# ============================================================
# 6. APPLY PREPROCESSING
# ============================================================

apply_preprocessor <- function(data, parameters) {

  # Apply the same deterministic feature engineering
  features <- engineer_features(data)

  # Verify all expected predictors are present
  stopifnot(
    all(parameters$predictor_columns %in% names(features))
  )

  # Create missingness indicators BEFORE imputation
  # This preserves information about original missing values
  for (variable in parameters$missing_columns) {

    indicator_name <- paste0(
      variable,
      "_was_missing"
    )

    features[[indicator_name]] <- as.integer(
      is.na(features[[variable]])
    )
  }

  # Impute numeric missing values using TRAINING medians
  for (variable in parameters$numeric_columns) {

    features[[variable]] <- as.numeric(
      features[[variable]]
    )

    features[[variable]][
      is.na(features[[variable]])
    ] <- parameters$training_medians[[variable]]
  }

  # Replace missing categorical values with "Missing"
  for (variable in parameters$categorical_columns) {

    features[[variable]] <- as.character(
      features[[variable]]
    )

    features[[variable]][
      is.na(features[[variable]])
    ] <- "Missing"
  }

  # Ensure consistent column ordering
  # TARGET is retained only when present in the input
  features <- features %>%
    select(
      all_of(parameters$output_columns),
      any_of("target")
    )

  return(features)
}

# ============================================================
# 7. TRAIN/TEST CONSISTENCY VALIDATION
# ============================================================

validate_prepared_data <- function(train, test) {

  # Confirm training and test have identical predictors
  train_predictors <- setdiff(names(train), "target")

  test_predictors <- names(test)

  stopifnot(
    identical(train_predictors, test_predictors)
  )

  # Confirm no missing values remain
  stopifnot(sum(is.na(train)) == 0)
  stopifnot(sum(is.na(test)) == 0)

  # Confirm application identifiers are unique
  stopifnot(anyDuplicated(train$sk_id_curr) == 0)
  stopifnot(anyDuplicated(test$sk_id_curr) == 0)

  # Confirm target exists only in training data
  stopifnot("target" %in% names(train))
  stopifnot(!"target" %in% names(test))

  cat("\nALL TRAIN/TEST VALIDATION CHECKS PASSED\n")

  invisible(TRUE)
}

# ============================================================
# 8. EXECUTE DATA PREPARATION PIPELINE
# ============================================================

# Learn preprocessing parameters using training data only
preprocessing_parameters <- fit_preprocessor(
  application_train
)

# Apply identical transformations to training and test data
prepared_train <- apply_preprocessor(
  application_train,
  preprocessing_parameters
)

prepared_test <- apply_preprocessor(
  application_test,
  preprocessing_parameters
)

# Validate prepared datasets
validate_prepared_data(
  prepared_train,
  prepared_test
)

# Create output directory for prepared datasets
dir.create(
  "data/processed",
  recursive = TRUE,
  showWarnings = FALSE
)

# Save prepared datasets and learned parameters
saveRDS(
  prepared_train,
  "data/processed/prepared_train.rds"
)

saveRDS(
  prepared_test,
  "data/processed/prepared_test.rds"
)

saveRDS(
  preprocessing_parameters,
  "data/processed/preprocessing_parameters.rds"
)

cat("\nDATA PREPARATION PIPELINE COMPLETED SUCCESSFULLY\n")
