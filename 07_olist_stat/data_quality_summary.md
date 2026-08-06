 ### Data Quality Summary - Olist E-commerce Fulfillment Analysis
** Project 07 | J.Glenn | August 2026 **
**Data Source:** Brazilian E-Commerce Public Dataset by Olist — Kaggle (CC0: Public Domain)  
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce?resource=download
--

## Overview
The Olist E-commerce dataset was sourced from Kaggle (CC0: Public Domain) as 9 .csv files  
| file | Entries |
|------|---------|
| purchases | 99441 |
| products | 32951 |
| payments | 103886 |
| order_items | 112650 |
| customers | 99441 |
| reviews | 99224 |
| vendors | 3095 |
| locations | 1000163 |
| prod_cat_translation | 71 |

A profiling pass was conducted via 00_profile.py before any transformation. The pass examined info, null counts, and a foreign key dtype check, to confirm all keys were intact. 


--

## Known Issues

| Issue | Severity | Analytical Impact | Resolution |
|---|---|---|---|
| 2965 `order_delivered_customer_date` NULL entries | Expected/No Impact | None - All non-delivered status will be excluded from analysis | ETL filters to `order_status` = `delivered` . 8 `delivered` orders with null dates flagged as anomaly. |
| 981148 `geolocation_zip_code_prefix` duplicates | Severe | Duplication of zipcode prefixes would cause erroneous results when joining this table | Deduplication of `geolocation_zip_code_prefix` during the ETL process |
| 610 `product_category_name` NULL entries | Low | Represents under 3% of the field | Noted & will exclude during ETL process |