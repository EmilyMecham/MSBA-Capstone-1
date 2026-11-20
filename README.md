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

## Modeling

The modeling phase builds on the prepared training and test datasets to predict the likelihood of loan repayment difficulties. The analysis is documented in `notebooks/modeling.qmd`.

### Models Evaluated

Three classification algorithms were compared using stratified three-fold cross-validation:

| Model | Mean ROC AUC |
|---|---:|
| XGBoost | 0.765 |
| Logistic Regression | 0.749 |
| Random Forest | 0.725 |

XGBoost achieved the highest initial ROC AUC and was selected for further experimentation.

### Class Imbalance Experiments

Because approximately 8% of applicants in the training dataset experienced payment difficulties, three approaches to class imbalance were evaluated:

| Strategy | Mean ROC AUC |
|---|---:|
| Original class distribution | 0.738 |
| Downsampling | 0.714 |
| SMOTE | 0.675 |

Retaining the original class distribution produced the strongest results. Neither downsampling nor SMOTE improved model performance.

### Hyperparameter Tuning

A randomized search evaluated 20 XGBoost configurations using three-fold cross-validation on a 10% sample of the training data. The selected configuration achieved a mean ROC AUC of 0.747.

The final configuration used:
- 300 trees
- Tree depth of 7
- Learning rate of 0.014
- Minimum node size of 24
- Loss reduction of 0.304
- Observation sampling proportion of 0.630
- Predictor sampling proportion of 0.689

### Final Model and Evaluation

The selected XGBoost configuration was trained on the full training dataset. Evaluation on an 80/20 stratified split produced the following results:

| Metric | Result |
|---|---:|
| ROC AUC | 0.761 |
| Accuracy | 91.8% |
| Sensitivity (Recall) | 0.71% |
| Specificity | 99.9% |
| Precision | 52.2% |

Classification threshold analysis demonstrated that lowering the default threshold from 0.50 to 0.10 increased sensitivity to 60.9%, with specificity of 77.7%. This highlighted the tradeoff between identifying more potentially high-risk applicants and increasing false-positive classifications.

### Kaggle Submission

The final model generated predicted probabilities for the competition test dataset and achieved the following Kaggle scores:

| Evaluation | ROC AUC |
|---|---:|
| Public leaderboard | 0.75575 |
| Private leaderboard | 0.75231 |

The private leaderboard score was used as the final competition evaluation result.

### Model Selection Rationale

XGBoost was selected because it achieved the strongest initial cross-validation performance among the three candidate algorithms. Class imbalance experiments supported retaining the original target distribution, and randomized hyperparameter tuning provided an efficient method for selecting the final configuration.

The project demonstrated an end-to-end predictive modeling workflow, including data preparation, feature engineering, model comparison, class imbalance evaluation, hyperparameter tuning, model validation, and Kaggle submission.

### Business Value

Predicting loan repayment difficulties can help lenders make more informed risk-management decisions. A model that estimates applicant-level repayment risk could support application review prioritization, help identify applicants who may benefit from additional evaluation, and provide insight into patterns associated with repayment challenges.

The final XGBoost model achieved a private Kaggle ROC AUC score of 0.75231, demonstrating its ability to distinguish between applicants with different levels of repayment risk. While the model is not intended to replace lending decisions, it illustrates how predictive analytics can support more informed and data-driven risk assessment.

### Challenges and Lessons Learned

Several challenges emerged throughout the project:

- **Missing data:** A substantial portion of the dataset contained missing values. Developing a consistent preprocessing approach required identifying missingness patterns, selecting appropriate imputation strategies, and creating missingness indicators.
- **Data quality:** The `DAYS_EMPLOYED` variable contained an unusual sentinel value representing 365,243 days. This required additional feature engineering to distinguish the placeholder from meaningful employment information.
- **Class imbalance:** Only approximately 8% of applicants experienced payment difficulties. Experiments with downsampling and SMOTE demonstrated that balancing the target classes did not necessarily improve model performance.
- **Preprocessing leakage:** Cross-validation initially highlighted the importance of fitting preprocessing parameters exclusively on training folds. Revising the workflow to use fold-specific preprocessing helped prevent information from leaking between training and validation data.
- **Model evaluation:** Accuracy alone was misleading because of the imbalanced target. Comparing ROC AUC, sensitivity, specificity, and precision provided a more complete understanding of model performance.
- **Reproducibility:** Developing the Quarto notebooks as self-contained documents reinforced the importance of explicitly loading dependencies, data, and reusable functions rather than relying on objects from an interactive R session.

The project reinforced that successful predictive modeling involves more than selecting an algorithm. Data quality, preprocessing, validation strategy, class distribution, and evaluation metrics all influence the reliability and usefulness of the final model.

### Key Takeaways

This project strengthened my ability to develop an end-to-end analytics workflow using R, including data cleaning, feature engineering, exploratory analysis, predictive modeling, cross-validation, hyperparameter tuning, and model evaluation.

Some of the most important lessons were:

- More complex models do not automatically outperform simpler alternatives.
- Techniques intended to address class imbalance can reduce predictive performance.
- Proper cross-validation requires preprocessing to be fitted within each training fold.
- A model's ranking performance and its ability to make useful classification decisions are different considerations.
- Technical results become more valuable when translated into practical business implications.

Overall, the project demonstrated how data science techniques can be applied to a real-world financial risk problem while emphasizing the importance of reproducibility, thoughtful evaluation, and clear communication.