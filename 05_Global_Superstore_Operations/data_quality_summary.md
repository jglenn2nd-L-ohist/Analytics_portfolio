 Data Quality Summary - Global Superstore Operations Analysis
**Project 05 | J.Glenn | July 2026**
**Data Source:** Global Superstore Dataset — Kaggle (CC0: Public Domain)  
https://www.kaggle.com/datasets/apoorvaappz/global-super-store-dataset

--

## Overview
The Global Superstore dataset was sourced from Kaggle (CC0: Public Domain) as a single .xls file containing three sheets: Orders (51,291 rows, 24 columns), Returns (1,174 rows, 3 columns), and People (14 rows, 2 columns).

A profiling pass was conducted via 00_profile.py before any transformation. The pass examined shape, data types, null counts, and column-level relevance across all three sheets. Three issues were identified. Two resulted in columns being dropped during ETL. One, negative profit values, was left untouched. Negative profit is a business reality and is analytically relevant to the questions being answered.

The dataset was loaded into SQLite as three separate relational tables after transformation. No records were removed. The issues documented below reflect the decisions made during that process.

--

## Known Issues

| Issue | Severity | Analytical Impact | Resolution |
|---|---|---|---|
| Postal Code - 41296 missing values | Low | This column has no bearing on the questions that need answered | Drop column during transformation stage |
| Profits - has negative values | Low | Negative profits are a business reality | Leave column untouched for analysis |
| Returned column - In Returns dataframe this is irrelevant as this is the purpose of the table | Low | Redundant column | Drop column during transformation stage, as it adds no value |

Profiling identified no duplicate records, no nulls in key analytical columns, and no data type corrections required beyond those handled during ETL

--