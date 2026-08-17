############################################################
## Project: Olist E-commerce Fulfillment Analysis
## File name: q7_accuracy.sql
## Table: purch, revu
## Business question: Q7 Is there a statistically meaningful 
##                    relationship between how accurately Olist 
##                    estimates the delivery date and the review 
##                    score a customer leaves?
## Purpose:   Determine if there is a statistically significant 
##            relationship between expeced arrival & review scores
## Author: J.Glenn
## Date: August 2026
############################################################

# - import libraries
import pandas as pd
import numpy as np
import sqlite3 as sq
import matplotlib.pyplot as plt
import scipy.stats as stats

# - import dataset
conn = sq.connect("../data/olist.db")

## - query data
query = """
        SELECT
            CASE WHEN ROUND(julianday(p.order_delivered_customer_date)-julianday(p.order_estimated_delivery_date),0) < 0 THEN '01 - early'  
                WHEN ROUND(julianday(p.order_delivered_customer_date)-julianday(p.order_estimated_delivery_date),0) = 0 THEN '02 - on-time' 
                WHEN ROUND(julianday(p.order_delivered_customer_date)-julianday(p.order_estimated_delivery_date),0) in (1,2,3) THEN '03 - 1-3 days late' 
                ELSE '04 - 4 or more days late'  END AS arrival_v_expect
        ,	r.review_score
        FROM
            purch p
        JOIN	
            revu r
        ON
            p.order_id = r.order_id
        """
expected = pd.read_sql_query(query, conn)

# - mask the arrivals
early = expected[expected["arrival_v_expect"] == '01 - early']
on_time = expected[expected["arrival_v_expect"] == '02 - on-time']
late = expected[expected["arrival_v_expect"] == '03 - 1-3 days late']
very_late = expected[expected["arrival_v_expect"] == '04 - 4 or more days late']


# - kruskal wallis testing
result = stats.kruskal(early["review_score"], on_time["review_score"], late["review_score"], very_late["review_score"])

print(result)

# - Box plot for more clarity 
fig, ax = plt.subplots(figsize=(10,6))

ax.boxplot([early["review_score"],on_time["review_score"],late["review_score"],very_late["review_score"]])
ax.set_xticklabels(['01 - early','02 - on-time','03 - 1-3 days late','04 - 4 or more days late'])
ax.set_xlabel("Arrival Category")
ax.set_ylabel("Review scores")
ax.set_title("Early & On-time arrivals lead to higher review scores")

plt.savefig("../outputs/q7_accuracy.png")
plt.show()