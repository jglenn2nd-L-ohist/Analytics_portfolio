###############################################################
## Project:           Global_Superstore_Operations_Analysis
## Script:            q1_ship_mode.py
## Business Question: Q1 | Which shipping modes are being used 
##                    across segments and regions, and what is 
##                    the cost implication of those choices? 
## Purpose:           To determine cost of shipping modes across
##                    the entire company & its impact
## Author:            J. Glenn
## Date:              2026-07-22
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
        ,	ship_mode
        ,	count(*) num_shipments
        ,	ROUND(SUM(shipping_cost),2) tot_ship	
        ,	ROUND(SUM(Profit),2) tot_profit
        FROM
        orders 
        GROUP BY
            Region
        ,	Segment
        ,	ship_mode
        """
orders = pd.read_sql_query(query, conn)

# - Close connection
conn.close()

# - Aggregate to region, mode, count
orders  = orders.groupby(["Region", "ship_mode"])["num_shipments"].sum()

# - Expand every row to show ship_modes
unstack = orders.unstack()

# - Visualize with stacked bar chart
unstack.plot(kind="bar", stacked=True, figsize=(14,9))
plt.ylabel("Number of shipments")
plt.title("Shipments by Region and Shipping type")
plt.tight_layout()

plt.savefig("../outputs/q1_ship_mode.png")
plt.show()
