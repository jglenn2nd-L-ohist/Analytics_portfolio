# Portfolio Audit Log

Audit of every claim on the portfolio against the underlying data, 2026-11-03. Each number was recomputed from repo data where the data exists.

## Corrected

| Project | Issue | Fix |
|---|---|---|
| Telecom | Churn shares reported as churn rates | Contract churn restated: month-to-month 46%, one-year 11%, two-year 3%. Month-to-month is 51% of customers and 89% of churn. Findings 03 to 06 recomputed. |
| Watson Healthcare | Share of leavers reported as attrition rate; unsupported benchmark claims | Rewritten around attrition rates: overtime 29% vs 5%, job level 1 and tenure, income, involvement. 1,676 records. |
| Olist | Lift wording overstated; precision lacked a base rate | Lift stated as 1.15x at 5%, 1.04x at 10%, 0.91x at 20%. Test-set late rate (5.3%, 994 of 18,777) added next to the 6.1% precision. |
| Global Superstore | Return-rate denominators included markets with no return data; Central lead presented as performance | Returns data covers 4 of 7 markets (5.8% order-level). Central's profit lead is volume (11.0% vs 15.6% margin). Discounts, not shipping, separate loss-making lines. |
| Customer LTV | Cohort code used `.count()` (invoice lines) instead of distinct customers; revenue per line shown as per customer | `q4_cohort.py` and `q5_ltv.py` fixed and charts regenerated. Revenue is per active customer-month. Dec 2010 left-censoring caveat added. |
| Used-Car | "Pre-registered" overstated | Reworded to "pre-specified" across page, docs and homepage card. |
| Commission | None needed | Model reproduces exactly. Labelled synthetic. |
| Homepage | Overstated cards; "business owner" framing | Value-first hero, featured trio, provenance pills, territory described as company territory managed. |

## Added
- Decision brief on Olist, Used-Car and Commission pages.
- Card thumbnails in `thumbs/`.

## Open
- Tableau dashboards, PPT and PDF exports still carry pre-audit numbers (Global Superstore Central +50%, LTV Aug 2011 cohort, Telecom 89%, "Pre-registered" label).
- Resumes and talking points may cite corrected-away figures.
- `10_nhtsa_early_warning/` is kept off the homepage until validated.
