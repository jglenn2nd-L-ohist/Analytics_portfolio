# 07 — Olist - E-commerce Fulfillment Analysis

## Business Context

Olist hypothesized that review ratings are linked to delivery arrival time relative to the estimated delivery date. The first leg of this analysis confirmed that hypothesis statistically -- delivery timing produces measurable, significant differences in customer review scores.

That finding raised a second, operational question: if late deliveries drive poor reviews, can late delivery risk be identified before it occurs? The second leg of this analysis shifts from descriptive and statistical to predictive -- using only information available at the moment an order is placed to flag orders at risk before shipment or fulfillment.

Together, the two legs answer:

- **Leg 1:** Does delivery timing produce measurable differences in review scores?
- **Leg 2:** Can late delivery risk be predicted at order placement, and which orders should operations intervene on?

--

## Analyst Questions

### Leg 1 — Delivery Performance & Review Impact

| # | Question |
|---|----------|
| Q1 | What does overall delivery performance look like -- on-time rate, average days late, average days early? |
| Q2 | Which seller states have the worst on-time delivery rates, and does seller-customer geographic distance correlate with delay? |
| Q3 | How do review scores distribute across delivery outcome buckets -- early, on-time, 1 to 3 days late, 4 or more days late? |
| Q4 | Which product categories carry the highest freight cost relative to item price, and does that ratio correlate with review scores? |
| Q5 | Build a seller performance tiering function. Input: seller_id. Output: tier assignment (high, mid, low) based on on-time rate, average review score, and order volume. |
| Q6 | Does delivery performance deteriorate during peak periods (November/December holiday season, identified from the data)? |
| Q7 | Is there a statistically meaningful relationship between how accurately Olist estimates the delivery date and the review score a customer leaves? |
| Q8 | Do orders where the actual delivery arrives earlier than estimated produce significantly higher review scores than orders where delivery arrives on or after the estimated date? |

### Leg 2 — Predictive Risk & Operational Intervention

| # | Question |
|---|----------|
| Q9 | Using only information available at order placement, which orders carry the highest predicted risk of late delivery? |
| Q10 | What patterns are most associated with late delivery risk -- which features carry the most predictive weight? |
| Q11 | Across simulated intervention capacities (top 5%, 10%, and 20% of flagged orders), how many late deliveries could an operations team realistically capture? |
| Q12 | What risk threshold delivers the best tradeoff between late delivery coverage and false alarm rate given realistic team capacity? |

--

## Data

Brazilian E-Commerce Public Dataset
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce?select=olist_customers_dataset.csv
Date Range: 2016–2018

--

## Key Findings

### Leg 1 — Delivery Performance & Review Impact

| # | Findings |
|---|----------|
| Q1 | Early/On-time rate: 92.08% · Late rate: 7.92% · Average days late: 10 · Average days early: 13 |
| Q2 | States with fewer than 50 shipments excluded; sample too small to distinguish performance from noise · MA worst on-time rate at 77% · SP (78,598), MG (8,601), PR (8,487) all sit at 92–95% · MA underperforms high-volume peers by 15+ points · Distance correlation coefficient -.077 shows effectively no correlation between distance and delivery arrival · Scatter plot added to visualize the correlation coefficient |
| Q3 | 4 or more days late review scores drop by more than 1.5 points; 4 or more days late (1.93), 1–3 days late (3.72); Early arrivals have 4.3 rating on +87,000 reviews; On-time total reviews (1,461) vs. early (87,375) shows a trend of conservative estimated delivery dates |
| Q4 | Filtered out 1 category with NULL value; No visible correlation between freight ratio and reviews; Noteworthy: review scores had to be assigned to categories and orders -- orders with multiple categories are represented in the output |
| Q5 | Segmented sellers by tier based on a weighted scale: Vol (.45), On-Time Rate (.40), Avg Reviews (.15); weights applied after all metrics were normalized and indexed 0.01–2.0; All sellers remain in the dataset, including low-volume performers |
| Q6 | Peak season on-time rate dips to 88.47% (November–December), a drop of approximately 3.5 points from the baseline of 92.08%; Trend line visualization revealed March 2018 at 78.6% OTR, nearly 10 points below peak season and 13 below baseline. |
| Q7 | Kruskal-Wallis test returned p < 0.001 with a test statistic of 10,089, confirming a statistically significant association between delivery timing relative to estimate and review score |
| Q8 | Mann-Whitney U test returned p < 0.001, confirming that early deliveries produce significantly higher review scores than on-time or late deliveries |

### Leg 2 — Predictive Risk & Operational Intervention

| # | Findings |
|---|----------|
| Q9 | Logistic regression built on feature mart; did not produce an operationally productive classifier · class_weight='balanced' raised recall 0.2% to 12%, at the cost of precision dropping 0.22 to 0.06 and accuracy falling 10 points · Threshold lowered 0.5 to 0.3 raised recall to 31%, but accuracy fell to 62% with precision dropping slightly to 0.05 · Result mirrors Leg 1 distance-delay finding (Q2): available data does not capture the operational factors driving late delivery |
| Q10 | In progress |
| Q11 | In progress |
| Q12 | In progress |

--

## Limitations

### Leg 1
Upon joining all tables, 3,000 entries were found to have zip prefixes not present in the geolocation table. They were dropped due to mismatch. 3,000 entries represents approximately 3% of the dataset.

8,500 km outlier was not excluded from the dataset in order to preserve scores for same-zip sales as well as legitimate long-distance orders that IQR banding would have eliminated.

### Leg 2
A seller's first-ever order is excluded from the training data. The rolling on-time rate window function requires at least one prior order to produce a valid historical signal; a seller with no order history produces no meaningful feature value, and imputing one would introduce an unsupported assumption.

All predictive features are constructed using only data available at the moment of order placement. No post-fulfillment information is included. This leakage control is the primary methodological discipline of Leg 2.

Time-based train-test split will be used to ensure model evaluates future data.

15 orders were excluded from the feature mart due to missing product weight/dimension data at the source (prods table), which caused `tot_weight`/`tot_volume` to compute as NULL. This affects roughly 0.016% of orders and was addressed by dropping the affected rows prior to modeling.

--

## Feature Engineering (Methodology) Notes
bare non-aggregated columns under GROUP BY (`seller_id`) silently corrupted rolling OTR/volume for any seller who wasn't SQLite's arbitrary pick on a multi-seller order, a bug that affected every seller's calculation, not just a visible subset. The fix required regrounding `roll_otr`/`roll_vol` to the seller-item grain and reasoning through why OTR collapses via MIN (weakest link drives risk) while volume collapses via MAX (presence of a strong seller is the meaningful signal, not the average or sum).

--

## Files

### Leg 1

| File | Description |
|------|-------------|
| `00_profile.py` | EDA profile to discover shape and anomalies of the data to prepare for transformation |
| `01_etl.py` | Remove data quality issues that surfaced during profiling |
| `q1_delivery_rate.sql` | SQL script to determine on-time rate and average days early and late |
| `q2_state_otr.sql` | SQL query to determine on-time rate at the state level |
| `q3_late_review.sql` | SQL query to segment review scores based on delivery outcome buckets |
| `q4_freight_review.sql` | SQL query to determine average review score by product category |
| `q6_peak_otr.sql` | SQL query to determine peak season on-time rate |
| `q2_distance_delay.py` | Python script to calculate delivery distance and delay correlation |
| `q2_distance_delay.png` | Scatter plot showing distance-delay correlation coefficient |
| `q5_seller_tier.sql` | Query to establish seller volume, on-time rate, and average review score |
| `q5_seller_tier.py` | Python script to normalize and segment metrics into performance tiers |
| `q6_peak_otr.py` | Python script to reveal monthly OTR trend |
| `q6_peak_otr.png` | Line chart showing OTR by month |
| `q7_accuracy.sql` | SQL script to retrieve delivery timing buckets and review scores |
| `q7_accuracy.py` | Python script to run Kruskal-Wallis distribution test |
| `q7_accuracy.png` | Box plot showing review score distribution by delivery timing |
| `q8_expecting.sql` | SQL query to retrieve early vs. not-early delivery and review scores |
| `q8_expecting.py` | Python script to run Mann-Whitney U test |
| `q8_expecting.png` | Violin plot showing review score distributions |
| `olist_case_study.html` | Case study deliverable |
| `07_olist_report_branded.pdf` | Technical report deliverable |

### Leg 2

| File | Description |
|------|-------------|
| `q9_feature_mart.sql` | SQL script to build the prediction-ready feature mart with leakage controls |
| `q9_model.py` | Python script to train baseline and comparison models and evaluate performance |
| `q10_feature_importance.py` | Python script to extract and visualize feature importance |
| `q11_intervention_sim.py` | Python script to simulate intervention capacity scenarios |
| `q12_threshold_analysis.py` | Python script to evaluate precision/recall tradeoffs across risk thresholds |

--

## Tools

### Leg 1
Python · SQL · pandas · SciPy · Matplotlib

### Leg 2
Python · SQL · scikit-learn · pandas · Matplotlib

--

## Status

Leg 1: Complete
Leg 2: In Progress