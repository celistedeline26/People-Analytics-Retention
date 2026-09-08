# People-Analytics-Retention
R-based people analytics auditing baseline employee attrition models. Combines decision trees, random forests, and Partial Dependence Plots (PDP) to isolate overwork and career stagnation risks among high-performing talent.

---

## 📖 Executive Summary (Storytelling Section)

This project evaluates employee turnover dynamics using the Kaggle HR Analytics dataset (14,999 records). Moving beyond standard correlation analyses, this study critiques popular baseline models that claim **95–99% accuracy** using surface-level satisfaction metrics.

After testing feature independence (specifically fitting classification models *without* job satisfaction), the analysis revealed that satisfaction is merely a **symptom of overwork**, not the primary root cause. High-performing employees (`last_evaluation >= 0.8`) split into two distinct operational risk groups: **severely overworked staff** (250+ monthly hours across 5–7 projects) and **stagnant staff** facing career inertia.

These findings demonstrate the necessity of behavioral segmentation and decision-threshold tuning to optimize proactive HR retention budgets.

---

## Project Overview

This project performs exploratory data auditing, non-linear machine learning modeling, and explainability analysis on employee performance records in R. The goal is to evaluate existing turnover claims, isolate the true root causes of high-performer attrition, and build a decision-focused classification pipeline to guide proactive HR intervention strategies.

---

## Business Context

Organizations facing high turnover need to understand:
* **Who** their most critical at-risk employees are (specifically top talent).
* **Why** high performers leave (overwork vs. career stagnation).
* **Whether** job satisfaction is a root cause or simply an indicator/symptom.
* **How** workload thresholds (monthly hours, project count) directly impact departure probability.

These insights support strategic decision-making in workforce planning, workload redistribution, management interventions, and targeted retention budgeting.

---

## Business Questions

1. Do standard bivariate correlations accurately explain the root causes of employee turnover?
2. Can machine learning models predict attrition effectively if job satisfaction data is unavailable?
3. What are the specific workload tipping points (hours/projects) that drive high performers to quit?
4. How do turnover risks vary across different organizational departments?
5. How can HR teams prioritize high-risk, high-value employees for financial retention interventions?

---

## Dataset Used

The dataset contains employee-level performance and operational records from Kaggle:
* **Satisfaction Level:** Self-reported job satisfaction score (`0–1`)
* **Last Evaluation:** Performance evaluation score (`0–1`)
* **Number of Projects:** Number of assigned concurrent projects
* **Average Monthly Hours:** Total working hours logged per month
* **Time Spent in Company:** Employee tenure in years
* **Work Accident:** Binary indicator (`0/1`)
* **Promotion Last 5 Years:** Binary indicator (`0/1`)
* **Department (`sales`):** Organizational department
* **Salary:** Income tier (`low`, `medium`, `high`)
* **Left (Target):** Binary turnover indicator (`0 = Stayed`, `1 = Left`)

---

## Data Preparation & Cleaning

The following preprocessing steps were performed in R:
* **Categorical Encoding:** Ordinal encoding for salary (`low = 1`, `medium = 2`, `high = 3`) and factor conversion for department and target variables.
* **Deduplication & Missing Values:** Checked for `NA` values and removed duplicate entries to ensure data integrity.
* **Partitioning:** Created an 80/20 train/test split using unique row identifiers for model validation.
* **Feature Subsetting:** Formatted datasets isolating satisfaction metrics to test feature dependencies (`dt_nosat`, `rf_nosat`).

---

## Basic Exploratory Data Analysis (EDA)

Basic EDA was conducted to understand scale and baseline distributions:
* Total Records: 14,999 employees
* Baseline Attrition Rate: ~23.8% (`left = 1`)
* Average Monthly Working Hours: ~201 hours/month
* Average Satisfaction Score: ~0.61

---

## Focused Exploratory Analysis & Audit

1. **Correlation Matrix & Pair Plots:** Multi-variable correlation matrices (`corrplot`) and pair plots (`GGally`) were evaluated. While a moderate negative correlation (`~ -0.39`) exists between satisfaction and attrition, bivariate correlation fails to capture non-linear interactions.
2. **Departmental Risk Analysis:** Logistic regression (`glm`) was applied to compute relative odds ratios and confidence intervals across departments to test whether specific teams faced higher systemic departure risks.
3. **Multi-Dimensional Coordinates:** Interactive 6-D parallel coordinate plots (`plotly`) were generated to observe full multi-variable employee trajectories simultaneously.

---

## Advanced Machine Learning & Model Audit

### 1. Decision Trees (`rpart`) — Testing Satisfaction Dependencies
* **Purpose:** Fitted decision trees *with* and *without* `satisfaction_level`.
* **Insight:** Excluding satisfaction reduced raw performance minimally while revealing that workload metrics (`average_monthly_hours` and `number_project`) explain turnover with equal predictive power. Satisfaction acts as a symptom, whereas overwork is the operational root cause.

### 2. Random Forest Classification (`randomForest`) & ROC/AUC Validation
* **Purpose:** Trained ensemble classifiers on training data and evaluated performance on holdout test sets.
* **Evaluation:** Models were evaluated using ROC curves and Area Under the Curve (`pROC`) metrics alongside 10-fold Cross-Validation (`cv_folds`) to guard against overfitting.

### 3. Model Explainability — Partial Dependence Plots (`iml`)
* **Purpose:** Applied Partial Dependence Plots (PDP) and Individual Conditional Expectation (ICE) curves to identify non-linear risk thresholds.
* **Findings:**
  * **Monthly Hours:** Risk spikes sharply beyond **250–280 hours/month**.
  * **Project Count:** Assigned workloads exceeding **6 concurrent projects** dramatically increase departure probability.
  * **Tenure:** Employee turnover probability peaks between **4–6 years of tenure**.

---

## Key Findings & Insights

* **The "Satisfaction" Trap:** Relying on satisfaction surveys creates a delayed feedback loop; workload metrics predict attrition before satisfaction drops.
* **High-Performer Dual Risk:** High-performing staff (`last_evaluation >= 0.8`) split into:
  1. *Burnout Cluster:* 250+ monthly hours across 5–7 projects.
  2. *Stagnation Cluster:* Low project loads with no career advancement over 4+ years.
* **Actionable Thresholds:** Tipping points occur at **250+ monthly working hours** and **>5 concurrent projects**.

---

## Business Implications & Recommendations

* **Operational Workload Caps:** Implement automated HR alerts when monthly working hours exceed 240 hours or when concurrent projects exceed 5.
* **Targeted Retention Budgeting:** Use predicted departure probability thresholds (`> 0.6`) combined with high evaluation scores (`>= 0.8`) to direct financial retention incentives exclusively to high-value assets.
* **Tenure Re-engagement:** Introduce structured career progression and promotion reviews for employees reaching 3–4 years of company tenure.

---

## Limitations

* Analysis is observational and based on cross-sectional survey data.
* External macroeconomic conditions and market compensation data are not included in the dataset.
* Qualitative reasons for departure (e.g., direct manager relationship quality) are unobserved.

---

## Tools & Technologies

* **Language:** R
* **Data Manipulation & Viz:** `tidyverse`, `ggplot2`, `corrplot`, `GGally`, `plotly`
* **Machine Learning & Audit:** `randomForest`, `rpart`, `rpart.plot`, `caret`, `pROC`, `iml`
* **Platform:** GitHub

---

## Project Files

* 📜 [R Script](scripts/hr_turnover_analysis.R) – Full production R script (Data preparation, decision trees, random forests, PDP explainability, and ROC validation).
* 📄 [Report](reports/HR_Analytics_Executive_Report.pdf) – Executive summary report and visual figures.
* 📁 [Dataset](data_raw/kaggle_hr_analytics.csv) – Raw HR analytics dataset.
