# 07 —  Olist - E-commerce Fulfillment Analysis

## Business Context

Olist has hypothesized that their reviews ratings are linked to the arrival time of 
customer purchases. Olist is theorizing that improving the arrival time as compared to the expected delivery time will generate higher review ratings

--

## Analyst Questions

| # | Questions |
|---|----------|
| Q1 | What does overall delivery performance look like -- on-time rate, average days late, average days early?|
| Q2 | Which seller states have the worst on-time delivery rates, and does seller-customer geographic distance correlate with delay? |
| Q3 | How do review scores distribute across delivery outcome buckets -- early, on-time, 1 to 3 days late, 4 or more days late? |
| Q4 | Which product categories carry the highest freight cost relative to item price, and does that ratio correlate with review scores? |
| Q5 | Build a seller performance tiering function. Input: seller_id. Output: tier assignment (high, mid, low) based on on-time rate, average review score, and order volume. | 
| Q6 | Does delivery performance deteriorate during peak periods (November/December holiday season, identified from the data)? | 
| Q7 | Is there a statistically meaningful relationship between how accurately Olist estimates the delivery date and the review score a customer leaves? | 
| Q8 | Do orders where the actual delivery arrives earlier than estimated produce significantly higher review scores than orders where delivery arrives on or after the estimated date? |
--

## Data

Brazilian E-Commerce Public Dataset
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce?select=olist_customers_dataset.csv
Date Range:
--

## Key Findings

| # | Findings |
|---|----------|
| Q1 | Early/On-time rate: 92.08% · Late rate: 7.92% · Average days late: 10 · Average days early: 13 | 
| Q2 | States with fewer than 50 shipments excluded; sample too small to distinguish 
performance from noise · MA worst on-time rate at 77% · SP (78,598), MG (8,601), 
PR (8,487) all sit at 92-95% · MA underperforms high-volume peers by 15+ points (Distance correlation portion will be answered via the python diagnostic phase) |
--

## Files

| File | Description |
|------|-------------|
| `00_profile.py` | EDA profile to discover shape and anomalies of the date to prepare for transformation process |
| `01_etl.py` | Remove data quality issues that surfaced during the profiling |
| `q1_delivery_rate.sql` | SQL script to determine on-time rate & average days early and late |
--

## Tools
Python
--

## Status

in progress