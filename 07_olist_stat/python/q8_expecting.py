###############################################################
## Project: Olist E-commerce Fulfillment Analysis
## File name: q8_expecting.py
## Business question: Q8 Do orders where the actual delivery 
##                    arrives earlier than estimated produce 
##                    significantly higher review scores than 
##                    orders where delivery arrives on or after 
##                    the estimated date? 
## Purpose:   Determine if early arrival leads to significantly
##            higher review scores
## Author: J.Glenn
## Date: August 2026
###############################################################

# - import libraries
import pandas as pd
import numpy as np
import sqlite3 as sq
import matplotlib.pyplot as plt
import scipy.stats as stats

# - import dataframe
conn = sq.connect("../data/olist.db")

# - query data
query = """
        SELECT
            CASE WHEN ROUND(julianday(p.order_delivered_customer_date)-julianday(p.order_estimated_delivery_date),0) < 0 THEN 'early' ELSE 'not early' END AS arrival_v_expect
        ,	r.review_score
        FROM
            purch p
        JOIN	
            revu r
        ON
            p.order_id = r.order_id
        """    
expected = pd.read_sql_query(query, conn)
conn.close()

# - mask arrival timing
early = expected[expected["arrival_v_expect"]== "early"]
not_early = expected[expected["arrival_v_expect"]== "not early"]

# - Mann-Whitney U test
result = stats.mannwhitneyu(early["review_score"],not_early["review_score"])

print(result)

# - visualize violin plot
fig, ax = plt.subplots(figsize=(10,6))

ax.set_xticks([1,2])
ax.set_yticks([1,2,3,4,5])
plt.violinplot([early["review_score"].values, not_early["review_score"].values])
ax.set_xlabel("Arrival Time")
ax.set_ylabel("Review Scores")
ax.set_title("'Not Early' arrivals cause review scores to plummet ")
ax.set_xticklabels(["early","not early"])

plt.savefig("../outputs/q8_expecting.png")
plt.show()
               