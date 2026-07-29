# Global Superstore Operations Analysis

**Analyst:** J. Glenn  
**Project:** 05_Global_Superstore_Operations  
**Status:** In Progress  

---

## Business Context

A global retail operation spanning 7 markets and multiple customer segments has engaged a BI Analyst to support the COO with a full operational review. Shipping costs are a
growing concern, return rates vary significantly by region, and leadership needs to understand not just where performance is breaking down, but why.

This project moves beyond descriptive reporting. 
The goal is root cause: identify the operational factors driving high shipping costs and elevated return rates, and surface actionable patterns the COO can act on.

---

## Business Questions

| # | Question |
|---|----------|
| Q1 | Which shipping modes are being used across segments and regions, and what is the cost implication of those choices? |
| Q2 | Which regions and customer segments generate the most revenue and profit, and what product categories are driving that performance? |
| Q3 | Which regions have the highest return rates, and is there a pattern by product category or customer segment? |
| Q4 | What factors appear to drive high shipping costs and high return rates? Is there a correlation with discount level, shipping time, order size, or order priority? |

---

## Data

**Source:** Global Superstore dataset (Kaggle)  
**Format:** Single `.xls` file — three sheets  

| Sheet | Rows | Columns | Description |
|-------|------|---------|-------------|
| Orders | 51,291 | 24 | Transactional sales data Jan 2011 – Dec 2014 |
| Returns | 1,174 | 3 | Returned order flags by market |
| People | 14 | 2 | Regional manager assignments (13 managers → 7 markets) |

**Key columns:** Order ID, Order Date, Ship Date, Ship Mode, Customer ID, Segment,
City, State, Country, Market, Region, Category, Sub-Category, Product Name, Sales,
Quantity, Discount, Profit, Shipping Cost, Order Priority

---

## ETL Pipeline

Extract from `.xls` (three sheets via `pd.read_excel()`) → Transform in pandas  
(merge, clean, engineer shipping time) → Load into SQLite → Query for analysis

---

## Key Findings

Q1:
    Ship mode reveals negative profit pattern across multiple region/category/ship mode combinations
Q2:
    Central is profit leader 50% above 2nd place profit leader
Q3:
    Company average return rate: 5.96%
    North Asia, North & West are all more than double company return rate
    in both category and segment breakdown
Q4:
    824 Returned and had high shipping costs
    of those 542 were at or below the average sale price
    also 436 of the 824 were sold without discounting
---

## Recommendations

*To be populated upon project completion.*

---

## Files

| File | Description |
|------|-------------|
| `data/Global Superstore.xls` | Raw source data — three sheets |
| `data_quality_summary.md` | Data quality issues, severity, and resolutions |
| `python/00_profile.py` | EDA pass — shape, nulls, dtypes, data quality flags |
| `python/01_etl.py` | Extract, transform, load into SQLite |
| `python/q1_shipping_modes.py` | Shipping mode usage and cost by segment and region |
| `python/q2_revenue_profit.py` | Revenue and profit by region, segment, and category |
| `python/q3_return_rates.py` | Return rate analysis by region, category, and segment |
| `python/q4_root_cause.py` | Correlation analysis — shipping cost and return rate drivers |
| `sql/` | SQL queries used in analysis |
| `outputs/` | Charts and exported CSVs |
| `deliverables/` | Executive briefing and Power BI dashboard |

---

## Dashboard

*Power BI dashboard — to be linked upon completion.*

---

## Tools

- **Python** — pandas, numpy, matplotlib, seaborn, xlrd, sqlite3
- **SQL** — SQLite (analytical query layer)
- **Power BI** — executive dashboard