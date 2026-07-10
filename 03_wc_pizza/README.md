# 03 – WC Pizza Co | Labor & Operations Analysis

## Business Context
WC (World Cup) Pizza is a fictional pizza chain based in Atlanta that was slow in 
making preparations for the influx of customers due to the World Cup. This analysis 
covers a time period from Jan 01, 2026 until the last game of the World Cup in Atlanta. 
Areas covered include Calendar, Employees, Ingredients, Inventory, Order Items, Orders, 
Products, Recipes, Shifts Actual, Shifts Scheduled, and Stores. Findings produced for 
owner-level and GM-level audiences.

## Business Questions
- **Q1:** Which locations/shifts are understaffed relative to order volume on game days vs. non-game days?
- **Q2:** Highest-demand products and ingredient volumes needed for game days?
- **Q3:** What does normal staffing look like and how can it be extrapolated to World Cup month?
- **Q4:** Where is labor cost leaking — overtime on slow days, scheduled vs. actual hours variance?
- **Q5:** What is the cost-per-order on game days vs. non-game days by location?

## Data
Source: Fictional dataset — 11 tables, 267,500+ rows  
Tables: wc_calendar, wc_employees, wc_ingredients, wc_inventory, wc_order_items, 
wc_orders, wc_products, wc_recipes, wc_shifts_actual, wc_shifts_scheduled, wc_stores

## Key Findings
- **Downtown dominates game day volume** — 736 average orders per game day, 
  nearly 3× the next highest location
- **Downtown generates $7,519 in average daily margin on game days** vs. $1,341 
  on non-game days — the highest margin opportunity in the chain
- **Smyrna carries the heaviest staff load** — 18.9 orders per staff member on 
  game days, signaling operational stress despite lower volume
- **Game day cost-per-order is lower than non-game days** at every location — 
  volume efficiency is present, but only if staffing keeps pace
- **Overtime is occurring on slow days** — scheduling is not being adjusted to 
  match forecasted volume, leaking labor cost unnecessarily
- **Classic Pepperoni and BBQ/Buffalo Chicken** are the top sellers across all 
  locations on game days

## Recommendations
1. **Bring staffing to budgeted levels** — Downtown and Smyrna are the priority. 
   Both locations are running below scheduled headcount on their highest-volume days, 
   limiting throughput on the most profitable days of the year.

2. **Fix scheduling logic to eliminate overtime on slow days** — stores are running 
   overtime on days that fall below the company average order volume. Staff to 
   forecasted demand, not a flat schedule. Tighter scheduling discipline will reduce 
   unnecessary labor cost without cutting coverage on high-demand days.

3. **Prioritize chicken and pepperoni inventory at Downtown for the July 15 final** 
   — Downtown carries the highest volume and highest margin per game day. Classic 
   Pepperoni and chicken pizzas are the top sellers across all game days. Inventory 
   allocation for the final match should be weighted toward Downtown to avoid stockouts 
   on the most profitable day of the World Cup.

## Files
| File | Purpose |
|------|---------|
| `python/00_build_database.py` | Builds SQLite database from synthetic data |
| `python/00b_clean.py` | Data cleaning and standardization |
| `sql/q1_staffing_v_load.sql` | Staffing vs. order load on game days vs. non-game days |
| `python/q1_staffing_v_load.py` | Visualization for Q1 |
| `sql/q2_game_day_demand.sql` | Top-selling products per store on game days |
| `sql/q2b_ingredients_game_day.sql` | Ingredient volumes needed for game days |
| `sql/q3_baseline_staffing.sql` | Baseline staffing by store and day of week |
| `sql/q4a_overtime_slow_days.sql` | Overtime hours on slow vs. busy days |
| `python/q4a_overtime_slow_days.py` | Visualization for Q4a |
| `sql/q4b_sheduled_variance.sql` | Scheduled vs. actual hours variance |
| `python/q4b_scheduled_variance.py` | Visualization for Q4b |
| `sql/q5_cost_rev.sql` | Cost, revenue, and margin by store and game day |
| `python/q5_cost_rev.py` | Visualization for Q5 |

## Tableau Dashboard
[World Cup Readiness: Staffing & Cost Analysis](https://public.tableau.com/views/WorldCupPizzaco/Dashboard1)

## Tools
SQL (SQLite) · Python (Pandas, NumPy, Matplotlib, Seaborn) · Tableau

## Status
✅ Complete