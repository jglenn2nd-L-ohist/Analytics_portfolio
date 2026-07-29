###############################################################
## Project:           Global_Superstore_Operations_Analysis
## Script:            q4_return_factors.py
## Business Question: Q4 | What factors appear to drive high shipping 
##                    costs and high return rates? 
##                    Is there a correlation with discount level, 
##                    shipping time, order size, or order priority?
## Purpose:            To determine return correlations across ship_time,
##					  Discount, order size, order_priority and 
##                    similarly shipping_cost
## Author:            J. Glenn
## Date:              2026-07-29
################################################################

# - import libraries
import pandas as pd
import numpy as np
import sqlite3 as sql
import matplotlib.pyplot as plt
import seaborn as sns

# - import data set
conn = sql.connect("../data/global_ss.db")

# - query based on category
q_disc = """
    SELECT
        COUNT(o.order_id) num_returns	
    ,	CASE WHEN o.Discount = 0.0 THEN 'No Discount' 
            WHEN o.Discount > 0.0 AND o.Discount <= 0.3 THEN 'Min Discount' 
            WHEN o.Discount > 0.3 AND o.Discount <= 0.6 THEN 'Mid Discount'
            WHEN o.Discount > 0.6 THEN 'Max Discount' END AS discount_level		 
    FROM
        orders o
    LEFT JOIN
        returns r
    ON	o.order_id = r.order_id
    WHERE r.order_id IS NOT NULL AND o.shipping_cost > (SELECT round(avg(shipping_cost),2) av_ship_cost FROM orders) -- Average shipping cost subquery
    GROUP BY
        discount_level
    """	          

discount = pd.read_sql_query(q_disc, conn)

q_sales = """
    SELECT
        COUNT(o.order_id) num_returns	
    ,	CASE WHEN o.Sales <= 721 THEN '721(av return sales amt) and below'
            WHEN o.sales > 721 AND o.Sales <= 2000 THEN '722 - 2000'
            WHEN o.sales > 2000 AND o.Sales <= 5000 THEN '2001 - 5000'
            ELSE '5001 and up' End sales_volume
    FROM
        orders o
    LEFT JOIN
        returns r
    ON	o.order_id = r.order_id
    WHERE r.order_id IS NOT NULL AND o.shipping_cost > (SELECT round(avg(shipping_cost),2) av_ship_cost FROM orders) -- Average shipping cost subquery
    GROUP BY
        sales_volume
    ORDER BY
        num_returns DESC
    """

sales = pd.read_sql_query(q_sales, conn)

conn.close()

# - Plot bar charts
# - plotting by discount
discount["discount_level"] = pd.Categorical(
    discount["discount_level"],
    categories=["No Discount", "Min Discount", "Mid Discount", "Max Discount"],
    ordered=True
)
discount = discount.sort_values("discount_level").set_index("discount_level")

discount.plot(kind="bar", stacked=False, figsize=(14,9))
plt.xlabel("Discount Level")
plt.ylabel("Number of Returns")
plt.title("Returns and High Ship cost by Discount Level")

plt.tight_layout()
plt.savefig("../outputs/q4_discount_factors.png")
plt.show()


# - plotting by sales
sales = sales.set_index("sales_volume")
sales.plot(kind="bar", stacked=False, figsize=(14,9))
plt.xlabel("Sales buckets")
plt.ylabel("Number of returns")
plt.title("Returns and High Ship cost by Sales Volume")

plt.tight_layout()
plt.savefig("../outputs/q4_sales_factors.png")
plt.show()