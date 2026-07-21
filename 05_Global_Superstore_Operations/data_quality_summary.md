 Data Quality Summary - Global Superstore Operations Analysis
**Project 05 | J.Glenn | July 2026**


--

## Overview
--
## Known Issues

| Issue | Severity | Analytical Impact | Resolution |
|---|---|---|---|
| Postal Code - 41296 missing values | Low | This column has no bearing on the questions that need answered | Drop column during transformation stage |
| Profits - has negative values | Low | Negative profits are a business reality | Leave column untouched for analysis |
| Returned column - In Returns dataframe this is irrelevant as this is the purpose of the table | Low | Redundant column | Drop column during transformation stage, as it adds no value |