# Quota and Commission Model (09_quota_model)

**Business question:** Does the flat-tier commission structure overpay, and if so, where and by how much?

**Status:** In progress. Data pipeline complete; Excel model under construction.

## Scenario

A fictional automotive replacement-parts company with 4 regions and 20 sales reps pays commission on gross margin, with the rate set by the rep's monthly net sales tier. The selected rate applies to all margin dollars, not only the dollars above the threshold. This project tests whether that flat structure overpays reps who cross a tier edge.

The rules are in `docs/rules_spec.md`.

## Pipeline

1. `python/generate_data.py` creates the synthetic sales data (60 months, Jan 2021 to Dec 2025).
2. `sql/01_create_tables.sql` builds the SQL Server schema.
3. `python/load_data.py` loads the CSVs into the database.
4. `sql/02_validate_load.sql` checks the load against the generator's totals.
5. `sql/03_rep_month_derivation.sql` aggregates completed net sales by rep by month.
6. `python/export_rep_month.py` writes `data/processed/rep_month.csv`.
7. Excel model (in progress): tier lookup, flat vs marginal commission, overpay by region and year.

## Data note

All data is synthetic. The synthetic-data generator (`generate_data.py`) was written with AI assistance (Claude). The SQL, Python loader and export, Excel model and analysis are my own work.

## Tools

SQL Server (SSMS), Python (pandas, SQLAlchemy), Excel.