##########################################################
## Project: Olist E-commerce Fulfillment Analysis
## File name: q6_peak_otr.py
## Business question: Q6 Does delivery performance deteriorate 
##                    during peak periods (November/December holiday 
##                    season, identified from the data)
## Purpose:   Does time of year have any effect on on-time rates
## Author: J.Glenn
## Date: August 2026
##########################################################

# - import libraries
import pandas as pd
import numpy as np
import sqlite3 as sq
import matplotlib.pyplot as plt

# - connect to database
conn = sq.connect("../data/olist.db")

# - query the data
query = """
        SELECT
            order_id AS id
        ,   order_purchase_timestamp AS purchase
        ,   order_delivered_customer_date AS delivered
        ,   order_estimated_delivery_date AS estimated
        FROM
            purch
"""

purch = pd.read_sql_query(query, conn)

# - convert data types
purch["purchase"]  = pd.to_datetime(purch["purchase"])
purch["delivered"] = pd.to_datetime(purch["delivered"])
purch["estimated"] = pd.to_datetime(purch["estimated"])

purch["purchase"] = purch["purchase"].dt.to_period("M")

# - create on-time boolean
purch["on_time"] = purch["delivered"] <= purch["estimated"]

# - establish purchase cohorts
p_cohort = purch.groupby("purchase").agg(
    total   = ("id", "count"),
    on_time = ("on_time", "sum")
)

# - establish OTR
p_cohort["OTR"] = 100.0 * (p_cohort["on_time"]) / p_cohort["total"]

# - create line chart
fig, ax = plt.subplots(figsize=(14, 7))

ax.plot(p_cohort.index.astype(str), p_cohort["OTR"])
ax.set_xlabel("Months")
plt.xticks(rotation=45, ha="right")
ax.set_ylabel("On Time Rate")
ax.set_title("March 2018 OTR Dropped 7 Points Below Holiday Season Levels")

plt.savefig("../outputs/q6_peak_otr.png")
plt.show()