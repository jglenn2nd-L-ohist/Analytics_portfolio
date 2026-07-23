###############################################################
## Project:           Global_Superstore_Operations_Analysis
## Script:            q2_revenue_profit.py
## Business Question: Q2 | Which regions and customer segments
##                    generate the most revenue and profit, and 
##                    what product categories are driving that 
##                    performance?
## Purpose:           To determine which regions/categories/segments
##                    drive revenue and profits
## Author:            J. Glenn
## Date:              2026-07-23
################################################################

# - Import libraries
import pandas as pd
import numpy as np
import sqlite3 as sql
import matplotlib.pyplot as plt

# - Import dataset from SQLite
conn = sql.connect("../data/global_ss.db")

# - Query data set
query = """
        SELECT
            Region
        ,	Segment
        , 	Category
        ,	ROUND(SUM(Sales *(1 - Discount)),2) Revenue
        ,	ROUND(SUM(Profit),2) Profits
        FROM
            orders 
        GROUP BY
            Region
        ,	Segment
        ,	Category
        ORDER BY
            Region
        ,	Segment
        ,	Revenue DESC
        """
orders = pd.read_sql_query(query, conn) 

# - Close connection
conn.close()

# - Gather data for vis
orders = orders.groupby("Region")["Profits"].sum()
orders = orders.sort_values()
# - Plot bar chart
fig, ax = plt.subplots(figsize=(14,9))

ax.bar(orders.index, orders.values)
ax.set_xlabel("Regions")
ax.set_ylabel("Profits")
ax.set_title("Profits by Region, 2011-2014")

plt.tight_layout()
plt.savefig("../outputs/q2_revenue_profit.png")
plt.show()