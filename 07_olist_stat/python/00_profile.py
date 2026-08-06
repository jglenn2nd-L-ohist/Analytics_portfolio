##################################################
# Project: Olist E-commerce Fulfillment Analysis
# File name: 00_profile.py
# Business question: 
# Purpose:
# Author: J.Glenn
# Date: August 2026
###################################################

# - import libraries
import pandas as pd
import numpy as np

# - import libraries
cust = pd.read_csv("../data/customers.csv")
loca = pd.read_csv("../data/location.csv")
oitem = pd.read_csv("../data/order_items.csv")
pay = pd.read_csv("../data/payments.csv")
cate = pd.read_csv("../data/prod_cat_translation.csv")
prods = pd.read_csv("../data/products.csv")
purch = pd.read_csv("../data/purchases.csv")
revu = pd.read_csv("../data/reviews.csv")
vend = pd.read_csv("../data/vendors.csv")

# - profile data
# - customers table
########################
print('*' *10, 'Customers.csv profile', '*' *10)
print("Customer info", cust.info())
print("Customer dupes", cust.duplicated().sum())
print("Foreign Key dtype check: customer_id", cust["customer_id"].dtypes)
print('*' * 40)

# - order_items table
########################
print('*' *10, 'order_items.csv profile', '*' *10)
print("Order item info", oitem.info())
print("Order item dupes", oitem.duplicated().sum())
print("Foreign Key dtype check:", oitem[["order_id","order_item_id","product_id"]].dtypes)
print('*' * 40)

# - payments table
########################
print('*' *10, 'payments.csv profile', '*' *10)
print("Payment info", pay.info())
print("Payment dupes", pay.duplicated().sum())
print("Foreign Key dtype check: order_id", pay["order_id"].dtypes)
print('*' * 40)

# - products table
########################
print('*' *10, 'products.csv profile', '*' *10)
print("Product info", prods.info())
print("Product dupes", prods.duplicated().sum())
print("Foreign Key dtype check: product_id", prods["product_id"].dtypes)
print('*' * 40)

# - purchases table
########################
print('*' *10, 'purchases.csv profile', '*' *10)
print("Purchase info", purch.info())
print("Purchase dupes", purch.duplicated().sum())
print("Foreign Key dtype check:", purch[["order_id","customer_id"]].dtypes)
print('*' * 40)

# - reviews table
########################
print('*' *10, 'reviews.csv profile', '*' *10)
print("Review info", revu.info())
print("Review dupes", revu.duplicated().sum())
print("Foreign Key dtype check:", revu[["review_id","order_id"]].dtypes)
print('*' * 40)

# - vendors table
########################
print('*' *10, 'vendors.csv profile', '*' *10)
print("Vendor info", vend.info())
print("Vendor dupes", vend.duplicated().sum())
print("Foreign Key dtype check: seller_id", vend["seller_id"].dtypes)
print('*' * 40)

# - location table
########################
print('*' *10, 'locations.csv profile', '*' *10)
print("Location info", loca.info())
print("Location dupes", loca.duplicated().sum())
print(loca["geolocation_zip_code_prefix"].duplicated().sum())
print('*' * 40)

# - product category translation table
########################
print('*' *10, 'prod_cat_translation.csv profile', '*' *10)
print("Category translation info", cate.info())
print("Category translation dupes", cate.duplicated().sum())
print('*' * 40)


# - Cross reference order_status & order_delivered_customer_date to determine 
# reason for missing values in order_delivery_customer_date

missing = purch["order_delivered_customer_date"].isnull()
print(purch[missing].groupby("order_status").count())