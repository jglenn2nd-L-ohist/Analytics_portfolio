# Data Quality Summary — WC Pizza Co.
**Project 03 | J. Glenn | July 2026**

---

## Overview

Prior to any analysis, the WC Pizza Co. dataset was profiled in DB Browser for SQLite to surface data quality issues across all 11 tables. Profiling preceded cleaning — the output of that process became this documentation. No cleaning decisions were made without first understanding the shape and scope of each issue.

The dataset spans January–July 2026 across ~267,500 rows. Issues were found across date formatting, categorical label consistency, duplicate records, null values, and missing relational keys.

---

## Issues Identified & Resolutions

### 1. Mixed Date Formats
**Tables affected:** `wc_orders`, `wc_shifts_actual`  
**Issue:** Four distinct date formats were present across both tables, making date-based filtering and joins unreliable.  
**Resolution:** `pd.to_datetime()` with `format='mixed'` was applied to parse all variants, then converted back to a standardized `YYYY-MM-DD` string format using `dt.strftime('%Y-%m-%d')`.

---

### 2. Inconsistent Categorical Labels
**Tables affected:** `wc_orders`, `wc_shifts_actual`, `wc_shifts_scheduled`

| Field | Variants Found | Mapped To |
|-------|---------------|-----------|
| Shift labels | 16 variants | 3 standard values |
| Order type | 16 variants | 3 standard values |
| Store name | 22 variants | 5 locations |

**Resolution:** `.map()` with standardization dictionaries was applied to each field, replacing all variants with their canonical values. Both `wc_shifts_scheduled` and `wc_shifts_actual` required shift label standardization — the scheduled table was corrected mid-project after a downstream join revealed the inconsistency.

---

### 3. Duplicate Order Records
**Table affected:** `wc_orders`  
**Issue:** Approximately 1,360 duplicate order rows were identified during profiling — roughly 1.5% of total order volume. These were flagged as operational artifacts, not legitimate transactions.  
**Resolution:** `drop_duplicates()` was applied to remove duplicates. Index was reset after removal.

---

### 4. Null Pay Rates
**Table affected:** `wc_employees`  
**Issue:** 4 employee records had null pay rates, preventing accurate labor cost calculations for those individuals.  
**Resolution:** Null pay rates were flagged for operational review. Records were retained in the dataset but excluded from labor cost aggregations where pay rate was required.

---

### 5. Null Reorder Points
**Table affected:** `wc_inventory`  
**Issue:** Approximately 11 SKUs had null reorder point values — meaning no automated replenishment threshold existed for those items.  
**Resolution:** Nulls were documented as a process gap, not a data entry error. No imputation was applied. Flagged for inventory management review.

---

### 6. Missing Employee IDs in Shifts Actual
**Table affected:** `wc_shifts_actual`  
**Issue:** The shifts actual table did not carry `employee_id` — only employee names, which contained typos and truncations. This blocked accurate labor cost joins downstream.  
**Resolution:** `pd.merge()` was performed on employee name between `wc_shifts_actual` and `wc_employees` to bring `employee_id` across as a resolved key. Name typos were handled prior to the merge through manual standardization.

---

### 7. Employee Name Typos & Truncations
**Table affected:** `wc_shifts_actual`  
**Issue:** Employee names contained inconsistent spellings and truncations, preventing clean joins to the employees reference table.  
**Resolution:** Names were standardized prior to the employee ID merge to ensure join integrity.

---

### 8. Stale Inventory Dates
**Table affected:** `wc_inventory`  
**Issue:** Smyrna location showed inventory records with stale last-updated dates, indicating inventory data had not been refreshed in line with other locations.  
**Resolution:** Documented as an operational data hygiene issue. Records were retained but flagged.

---

## Summary Table

| Issue | Table(s) | Records Affected | Resolution | Status |
|-------|----------|-----------------|------------|--------|
| Mixed date formats | wc_orders, wc_shifts_actual | All date fields | Standardized via pd.to_datetime() | ✅ Resolved |
| Shift label variants | wc_shifts_actual, wc_shifts_scheduled | 16 → 3 values | Mapped via dictionary | ✅ Resolved |
| Order type variants | wc_orders | 16 → 3 values | Mapped via dictionary | ✅ Resolved |
| Store name variants | wc_orders, wc_shifts_actual | 22 → 5 values | Mapped via dictionary | ✅ Resolved |
| Duplicate orders | wc_orders | ~1,360 rows | drop_duplicates() | ✅ Resolved |
| Null pay rates | wc_employees | 4 records | Flagged, excluded from cost calc | ⚠️ Flagged |
| Null reorder points | wc_inventory | ~11 SKUs | Documented as process gap | ⚠️ Documented |
| Missing employee IDs | wc_shifts_actual | All rows | Resolved via name-to-ID merge | ✅ Resolved |
| Employee name typos | wc_shifts_actual | Multiple | Standardized prior to merge | ✅ Resolved |
| Stale inventory dates | wc_inventory (Smyrna) | Multiple | Flagged for ops review | ⚠️ Flagged |

---

## Cleaning Script
All cleaning logic is contained in `python/00b_clean.py`. The raw database is regenerable from `python/00_build_database.py`. The cleaning script is the asset — not the database.
