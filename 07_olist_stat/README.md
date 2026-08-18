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
PR (8,487) all sit at 92-95% · MA underperforms high-volume peers by 15+ points;     
  -Distance correlation coefficient .077 shows there is effectively no correlation between the distance and the delivery arrival 
   - Scatter plot added to visualize the correlation coefficient |
| Q3 |  4 or more days late review scores drop by more than 1.5 points; 4 or more (1.93) 1-3 (3.72); Early arrivals have 4.3 rating on +87,000 reviews; On-time total reviews (1,461) v early (87.375) shows a trend of conservative estimated delivery dates |
| Q4 | Filtered out 1 category that had NULL value; No visible correlation beween freight ratio and reviews; scatterplot and correlation coeffficient to be done in next phase of analysis; Noteworthy: review scores had to be assigned to categories and orders. With that some orders having multiple categories are represented in the output | 
| Q5 | Segmented Sellers by tiers based on a weighted scale where Vol (.45), On-Time Rate (.40) & Avg Reviews (.15), weights were applied after all metrics were normalized and indexed from 0.01-2.0; All sellers remain in the data set, even if they are low volume performers |
| Q6 | Determined that the peak season on-time rate dips to 88.47% (November-December) This marks an OTR drop of app 3.5 points from the normal rate of 92.08% ; Trend line vis in Python revealed March 2018 at 78.6% OTR, almost a full 7 points below peak season|
| Q7 | Kruskal-Wallis distribution test returned a p-value (p < 0.001). Indicating a strong relationship between the time a product arrived(in relation to its expected time) and review score. Test statistic of 10,089 also confirms the findings |
| Q8 | Mann-Whitney U test returned a p-value (p < 0.001). Indicating a strong relationship between the time a product arrived(in relation to its expected time) and review scores |
--

## Limitations

Upon joining all the tables, 3,000 entries were found to have zip prefixes not found in the loca table. They were dropped due to mismatch. 3,000 entries represents under 2% of the dataset

8,500 km Outlier was not excluded from the data set in order to preserve the scores of sales that were done with buyer and seller in the same zip as well as the legitimate long distance orders that IQR banding would have eliminated.
--

## Files

| File | Description |
|------|-------------|
| `00_profile.py` | EDA profile to discover shape and anomalies of the date to prepare for transformation process |
| `01_etl.py` | Remove data quality issues that surfaced during the profiling |
| `q1_delivery_rate.sql` | SQL script to determine on-time rate & average days early and late |
| `q2_state__otr.sql` | SQL query to determine on-time rate on state level |
| `q3_late_review.sql` | SQL query to segment review scores based upon delivery segments |
| `q4_freight_review.sql` | SQL query to determine average review score by product category |
| `q6_peak_otr.sql` | SQL query to determine peak season on-time rate |
| `q2_distance_delay.py` | Python script to determine delivery distance and delay correlation |
| `q2_distance_delay.png` | Scatterplot showing Distance delivery coefficient |
| `q5_seller_tier.sql` | Query to establish Seller Volume, on-time rate & Avg review score |
| `q5_seller_tier.py` | Python script to normalize and segment Volume, on-time rate & Avg reviews into tiers |
| `q6_peak_otr.py` | Python script to reveal monthly OTR |
| `q6_peak_otr.png` | Line chart vis showing OTR by month |
| `q7_accuracy.sql` | SQL script to get expecting & review score |
| `q7_accuracy.py` | Python script to get Kruskal-Wallis distrbiution score |
| `q7_accuracy.png` | Box plot showing review score distribution |
| `q8_expecting.sql` | SQL query to get early v not early & review scoring |
| `q8_expecting.py` | Python script to get Mann-Whitney U test data |
| `q8_expecting.png`| Violin plot to show review score distributions |
--

## Tools
Python · SQL 
--

## Status

in progress