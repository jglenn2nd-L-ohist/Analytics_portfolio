# Global Superstore Operations Analysis

**Analyst:** J. Glenn  
**Project:** 05_Global_Superstore_Operations  
**Status:** Complete

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

**Attribution:** Global Superstore Dataset — Kaggle (CC0: Public Domain)  
https://www.kaggle.com/datasets/apoorvaappz/global-super-store-dataset
---

## ETL Pipeline

Extract from `.xls` (three sheets via `pd.read_excel()`) → Transform in pandas  
(merge, clean, engineer shipping time) → Load into SQLite → Query for analysis

---

## Key Findings

| Q1 |
With respect to shipping costs, data reveals there are large profit losses found in all categories, some more than $2,000 per order. |
| Q2 |
With the corporate segment experiencing the heaviest losses Central region is our overall profit leader, bringing in 50% more than the 2nd place region, North. |
| Q3 |
|Our company returns rate is 5.96%. North Asia, North & West all have return rates double the company average when viewed by both category and segment. |
| Q4 | 
Studying returns, specifically with high shipping costs, the company has a sample size of 824. Of those 824, 542 (~66%) were sales made at or below the company average of $721. Also of those 824, 436 (~53%) were sold at full price, without any discount. |
---

## Recommendations

| # | Recommendation | Based On |
|---|---------------|----------|
| R1 | Commission a pricing study to determine the proper shipping cost structure for corporate accounts across all shipping modes. | Q1 |
| R2 | Conduct an operational review of the Central region to identify the practices driving its profit leadership and assess replicability across underperforming regions. | Q2 |
| R3 | Implement a return survey in North Asia, North, and West regions to identify root causes and inform a targeted reduction strategy. | Q3 |
| R4 | Evaluate a discount strategy for high-shipping-cost, low-sale-price items as a perceived value intervention to reduce return rates. | Q4 |
---

## Files

| File | Description |
|------|-------------|
| `data/GlobalSuperstore.xls` | Raw source data — three sheets |
| `data_quality_summary.md` | Data quality issues, severity, and resolutions |
| `python/00_profile.py` | EDA pass — shape, nulls, dtypes, data quality flags |
| `python/01_etl.py` | Extract, transform, load into SQLite |
| `python/q1_ship_mode.py` | Shipping mode usage and cost by segment and region |
| `python/q2_revenue_profit.py` | Revenue and profit by region, segment, and category |
| `python/q3_region_return.py` | Return rate analysis by region, category, and segment |
| `python/q4_return_factors.py` | Correlation analysis — shipping cost and return rate drivers |
| `sql/q1_ship_mode.sql` | Query shipping mode costs |
| `sql/q2_revenue_profit.sql` | Query profits by region |
| `sql/q3_region_return.sql` | Query return rates by region and category |
| `sql/q4_return_factors.sql` | Query 4 separate factors for returns with high shipping costs |
| `outputs/q1_ship_mode.png` | Shipping mode cost vis |
| `outputs/q2_revenue_profit.png` | Revenue breakdown by region vis |
| `outputs/q3_region_category.png` | Return rates by region |
| `outputs/q3_returns_segment.png` | Return rates by segment |
| `outputs/q4_discount_factors.png` | Return/High shipping and discounts vis |
| `outputs/q4_sales_factors.png` | Return/High shipping and sale price vis |

---

## Dashboard

Power BI dashboard committed to `deliverables/global_superstore_dashboard.pbix`
Requires Power BI Desktop to open locally
*Live published link - pending*

---

## Tools

- **Python** — pandas, numpy, matplotlib, seaborn, xlrd, sqlite3
- **SQL** — SQLite (analytical query layer)
- **Power BI** — executive dashboard