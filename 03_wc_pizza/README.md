# 03 – WC Pizza Co | Labor & Operations Analysis

## Business Context
WC (World Cup) Pizza is a fictional pizza chain based in Atlanta that was slow in making preparations for the influx of customers due to the World Cup. This analysis covers a time period from Jan 01, 2026 until the last game of the world cup, in Atlanta. The areas covered include Calendar, Employees, Ingredients, Inventory, Order_items, Orders, Products, Recipes, Shifts_actual, Shifts_scheduled & stores. Findings produced for owner level and GM level audiences.

## Business Questions
Q1: Which locations/shifts are understaffed relative to order volume on game days vs. non-game days? 
Q2: Highest-demand products and ingredient volumes needed for game days? 
Q3: What does normal staffing look like and how can it be extrapolated to World Cup month? 
Q4: Where is labor cost leaking — overtime on slow days, scheduled vs. actual hours variance? 
Q5: Cost-per-order on game days vs. non-game days by location?

##  Data
Source: Fictional dataset - 11 tables, +267,500 table entries
Tables: wc_calendar, wc_employees, wc_ingredients, wc_inventory, wc_order_items, wc_orders, wc_products, wc_recipes, wc_shifts_actual, wc_shifts_scheduled & wc_stores

## Key Findings
Updated upon completion 

## Files
| File | Purpose |
|------|---------|
| `python/00_build_database.py` | Builds SQLite database from raw data |
| `python/00b_clean.py` | Data cleaning and standardization |
| `python/04_staffing_v_load.py` | Staffing vs. order load on game days vs. non-game days (Q1) |
| `sql/04_staffing_v_load.sql` | Supporting SQL for Q1 staffing analysis |
## Tools
SQL (SQLite) – Python (Pandas, Numpy, Matplotlib, Seaborn)

## Status
 Progressing
