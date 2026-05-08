# DSC 531 Regression Project

**Course:** DSC 531 | **Data:** IPEDS (Integrated Postsecondary Education Data System)

This repository contains two regression analyses predicting graduation outcomes for U.S. postsecondary institutions, using data from IPEDS. All analyses are restricted to institutions with an incoming baccalaureate cohort of at least 200 students (n = 1,252 institutions).

---

## Project 1: Linear Regression — Predicting Graduation Rates

Builds a linear regression model to predict the six-year baccalaureate graduation rate (completion within 150% of normal time) using institutional characteristics and financial data.

**Files:**
- `project1_writeup.docx` — Final model with interpretations, specification sheet, and model selection discussion
- `project1_model_selection.csv` — Summary of all 9 model selection runs (3 methods × 3 criteria: AICc, SBC, Adj R²)

**Final model:** 10 effects (control, hloffer_collapse, locale_collapse, c21enprf_collapse, room, board_collapse, tuition2, fee2, avg_faculty_salary, cohort_total) — R² = 0.706, Adj R² = 0.701

---

## Project 2: Logistic Regression — Predicting Above-Median Graduation Rate

Builds a binary logistic regression model to predict whether an institution's graduation rate falls above the median (cutoff = 59.9%) using the same candidate predictors plus a census region variable.

**Files:**
- `project2_writeup.docx` — Final model with interpretations, specification sheet, and model selection discussion
- `project2_model_selection.csv` — Summary of all 6 model selection runs (3 methods × 2 criteria: p = 0.05, p = 0.10)

**Final model:** 4 predictors (tuition2, fee2, avg_faculty_salary, cohort_total) — c-statistic = 0.914

---

## SAS Code

- `modelling_project.sas` — Full SAS code including data preparation, variable creation, correlation checks, and all model selection runs for both projects

---

## Data Source

IPEDS (Integrated Postsecondary Education Data System). Data accessed via course repository. Variables drawn from the Graduation, Characteristics, Tuition and Costs, and Salaries datasets.
