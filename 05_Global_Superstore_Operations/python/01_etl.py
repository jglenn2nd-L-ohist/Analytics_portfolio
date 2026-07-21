######################################################
# Project: Global Superstore Operations Analysis
# Filename: 01_etl.py
# Business Question: What is the root cause of operational issues (shipping, performance & returns)?
# Purpose: Extract, Transform Load data into SQLite
# Author: J.Glenn
# Date: 2026-07-21
######################################################

# - Import libraries
import pandas as pd
import numpy as np
import sqlite3 as sql

# - Import dataset into different data frames
orders = pd.read_excel("../data/GlobalSuperstore.xls", sheet_name="Orders", engine="xlrd")
returns = pd.read_excel("../data/GlobalSuperstore.xls", sheet_name="Returns", engine="xlrd")
people = pd.read_excel("../data/GlobalSuperstore.xls", sheet_name="People", engine="xlrd")

# - Transform orders and returns by dropping irrelevent columns
orders = orders.drop("Postal Code", axis=1)
returns = returns.drop("Returned", axis=1)

# - Normalizing column names to remove " " in orders and returns
new = {
    "Row ID" : "row_id",
    "Order ID" : "order_id",
    "Order Date" : "order_date",
    "Ship Date" : "ship_date",
    "Ship Mode" : "ship_mode",
    "Customer ID" : "customer_id",
    "Customer Name" : "customer_name",
    "Product ID" : "product_id",
    "Sub-Category" : "sub_category",
    "Product Name" : "product_name",
    "Shipping Cost" : "shipping_cost",
    "Order Priority" : "order_priority"
}

orders = orders.rename(columns=new)

new = {
    "Order ID" : "order_id"
}

returns = returns.rename(columns=new)

# - Engineer column to determine shipping time
orders["ship_time"] = (orders["ship_date"] - orders['order_date'])

# - convert ship_time to int
orders["ship_time"] = orders["ship_time"].dt.days

print(orders.head())