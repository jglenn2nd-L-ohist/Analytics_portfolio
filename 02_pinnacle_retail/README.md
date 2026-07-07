# 02 — Pinnacle Retail Group | Business Intelligence Analysis

## Business Context
Pinnacle Retail Group is a fictional 6-store Atlanta retail chain experiencing
margin decline and inventory inefficiencies. This analysis covers 2024–2025
performance across transactions, customers, stores, inventory, and products —
producing findings structured for a VP-level audience.

## Analyst Questions
- Q01: How does 2025 actual revenue compare to projected by store?
- Q02: Which products and categories are driving or dragging margin?
- Q03: Where are inventory inefficiencies concentrated?
- Q04: What does the customer base look like and where is retention breaking down?
- Q05: What are the compounding factors behind overall margin decline?

## Data
- Source: Fictional dataset — 5 tables, 2,000+ transactions
- Tables: `pintransact`, `pincust`, `pinstor`, `pininv`, `pinprod`
- Known issue: Tableau dashboard was not published — data discrepancy between
  source tables was identified and determined not worth reconciling for this project.

## Key Findings
- 847 orphaned product IDs resolved during data cleaning
- Revenue vs. projected variance identified by store
- Margin and inventory findings surfaced through SQL and Python analysis

## Files
| File | Purpose |
|------|---------|
| `python/00_build_database.py` | Builds SQLite database from raw data |
| `python/00b_clean.py` | Data cleaning and standardization |
| `python/01_revenue_vs_projected.py` | 2025 actual vs. projected revenue by store |
| `sql/` | Supporting queries |

## Tools
SQL (SQLite) · Python (pandas, matplotlib, seaborn)

## Status
✅ Complete