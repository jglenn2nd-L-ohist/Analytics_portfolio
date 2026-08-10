##################################################
# Project: Olist E-commerce Fulfillment Analysis
# File name: 01_etl.py
# Business question: 
# Purpose:   
# Author: J.Glenn
# Date: August 2026
###################################################

# - import libraries
import pandas as pd
import numpy as np
import sqlite3 as sq

# - import datasets 
cust = pd.read_csv("../data/customers.csv")
loca = pd.read_csv("../data/location.csv")
oitem = pd.read_csv("../data/order_items.csv")
pay = pd.read_csv("../data/payments.csv")
cate = pd.read_csv("../data/prod_cat_translation.csv")
prods = pd.read_csv("../data/products.csv")
purch = pd.read_csv("../data/purchases.csv")
revu = pd.read_csv("../data/reviews.csv")
vend = pd.read_csv("../data/vendors.csv")

# - remove missing fields in the purchase table according to order_status
purch = purch[(purch["order_status"] == "delivered") & (purch["order_delivered_customer_date"].notnull())]

# - deduplicate the locations table filtering on the zip_code
loca = loca.drop_duplicates(subset=["geolocation_zip_code_prefix"])

# - Load data sets to SQLite
# - load all 9 tables
conn = sq.connect("../data/olist.db")
cust.to_sql("cust", conn, if_exists="replace", index=False )
loca.to_sql("loca", conn, if_exists="replace", index=False)
oitem.to_sql("oitem", conn, if_exists="replace", index=False)
pay.to_sql("pay", conn, if_exists="replace", index=False)
cate.to_sql("cate", conn, if_exists="replace", index=False)
prods.to_sql("prods", conn, if_exists="replace", index=False)
purch.to_sql("purch", conn, if_exists="replace", index=False)
revu.to_sql("revu", conn, if_exists="replace", index=False)
vend.to_sql("vend", conn, if_exists="replace", index=False)

conn.close()