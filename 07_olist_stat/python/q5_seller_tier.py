###########################################################
## Project: Olist E-commerce Fulfillment Analysis
## File name: q5_seller_tier.py
## Business question: Q5  Build a seller performance tiering 
##                      function. Input: seller_id. 
##                      Output: tier assignment (high, mid, low) 
##                      based on on-time rate, average review score, 
##                      and order volume.
## Purpose:   Classify sellers based on volume, otr & review 
## Author: J.Glenn
## Date: August 2026
############################################################

# - import libraries
import pandas as pd
import numpy as np
import sqlite3 as sq

# - import dataset
conn = sq.connect("../data/olist.db")

# - query data
query = """
        WITH on_time AS ( -- Establish Seller volume, OTR & Avg review scores
                SELECT
                    o.seller_id
                ,	COUNT(o.order_item_id) AS volume
                , 	COUNT( CASE WHEN julianday(p.order_delivered_customer_date)-julianday(p.order_estimated_delivery_date) <= 0 THEN 1 END) AS On_time
                ,	ROUND(avg(r.review_score),2) AS av_review
                FROM
                    oitem o
                JOIN
                    purch p
                ON
                    o.order_id = p.order_id
                JOIN
                    revu r
                ON
                    p.order_id = r.order_id
                GROUP BY
                    o.seller_id
                )
        SELECT
            seller_id
        ,	volume
        ,	on_time
        , 	ROUND(100.0 * on_time/volume ,2) AS OTR -- On time Percentage
        ,	av_review

        FROM
            on_time 
        """

seller = pd.read_sql_query(query, conn)

# - Establish function to determine seller composite score for tiering
def tier(seller_id, seller):
    row = seller[seller["seller_id"] == seller_id]
  # - pull each metric from dataframe
    vol = row["volume"].values[0]
    otr = row["OTR"].values[0]
    rev = row["av_review"].values[0]
  # - get averages from each metric
    a_vol = np.average(seller["volume"])
    a_otr = np.average(seller["OTR"])
    a_rev = np.average(seller["av_review"])
  # - normalize each metric and cap the range from 0.01-2.0
    norm_v = np.clip(vol/a_vol, 0.01, 2.0)
    norm_o = np.clip(otr/a_otr, 0.01, 2.0)
    norm_r = np.clip(rev/a_rev, 0.01, 2.0)
  # - weight metrics 
    w_vol = norm_v *.45
    w_otr = norm_o *.40
    w_rev = norm_r *.15

    comp = w_vol + w_otr + w_rev

# - Establish tiers for composite scoring
    if comp <= 0.666:
        tier = "Lower"
    elif comp > 1.333:
        tier = "Upper"
    else:
        tier = "Mid"

    return tier  

seller["tier"] = seller.apply(lambda row: tier(row["seller_id"], seller), axis=1)

conn.close()

print(seller)