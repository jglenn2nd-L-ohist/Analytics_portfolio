#########################################################
## Project: Olist E-commerce Fulfillment Analysis
## File name: q2_distance_delay.py
## Business question:  Q2) Which seller states have the 
##                     worst on-time delivery rates, and 
##                     does seller-customer geographic 
##                     distance correlate with delay? 
## Purpose:   Determine worst on-time rates by state
##            and see is there a distance correlation
## Author: J.Glenn
## Date: August 2026
#########################################################

# - import libraries
import pandas as pd
import numpy as np
import sqlite3 as sq
import math as m
import matplotlib.pyplot as ply

# - import data set
conn = sq.connect("../data/olist.db")

# - query data
query = """
        SELECT
            c.customer_id AS Cust_id
        ,   o.order_id AS order_id
        ,	o.order_item_id AS order_item_id
        ,	c.customer_zip_code_prefix AS Cust_zip
        , 	l.geolocation_lat AS Cust_lat
        ,	l.geolocation_lng AS Cust_long
        ,	v.seller_id AS Seller_id
        ,	v.seller_zip_code_prefix AS Seller_zip 
        ,	l2.geolocation_lat AS Seller_lat
        ,	l2.geolocation_lng AS Seller_long
        ,   p.order_estimated_delivery_date AS Estimated_date
        ,   p.order_delivered_customer_date AS Actual_date
        ,	ROUND(julianday(p.order_delivered_customer_date)-julianday(p.order_estimated_delivery_date),0) arrival_diff
   
        FROM
            cust c
        JOIN
            loca l
        on c.customer_zip_code_prefix = l.geolocation_zip_code_prefix
        JOIN
            purch p
        on c.customer_id = p.customer_id
        JOIN
            oitem o
        on p.order_id = o.order_id
        JOIN
            vend v
        on o.seller_id = v.seller_id
        JOIN
            loca l2
        on v.seller_zip_code_prefix = l2.geolocation_zip_code_prefix
"""
distance = pd.read_sql_query(query,conn)

conn.close()

# - function to return distance between buyer and seller
def haversine(Cust_lat,Cust_long,Seller_lat,Seller_long):
    R = 6371
    lat1 = m.radians(Cust_lat)
    lat2 = m.radians(Seller_lat)
    dlat = m.radians(Seller_lat - Cust_lat)
    dlng = m.radians(Seller_long - Cust_long)
    a = m.sin(dlat/2)**2 + m.cos(lat1) * m.cos(lat2) * m.sin(dlng/2)**2
    c = 2 * m.atan2(m.sqrt(a), m.sqrt(1-a))
    return R * c 

distance["km_dist"] = distance.apply(lambda row: haversine(row["Cust_lat"], row["Cust_long"], row["Seller_lat"], row["Seller_long"]), axis=1)

print(distance[["km_dist","arrival_diff"]].corr())


# - scatterplot vis to show the correlation between distance and delivery time
fig, ax = ply.subplots(figsize=(10,6))
reg = np.polyfit(distance['km_dist'],distance["arrival_diff"], 1)
trend = np.poly1d(reg)
x_line = np.linspace(distance["km_dist"].min(), distance["km_dist"].max(), 100)
ax.plot(x_line, trend(x_line), color="red", linewidth=1.5)

samp = distance.sample(n=10000, random_state= 27)
ax.scatter(x=samp["km_dist"], y=samp["arrival_diff"],alpha=.3)
ax.set_xlabel("Shipping Distance")
ax.set_ylabel("Difference from Expected Delivery Date")
ax.set_title("No distance delivery time correlation (coef -0.077)")

ply.savefig("../outputs/q2_distance_delay.png")
ply.show()