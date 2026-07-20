######################################################
# Project: Customer Lifetime Value Analysis
# Filename: q3_country_habits.py
# Business Question: What are our customer tendencies and what is their lifetime value?
# Purpose: To discern customer buying pattern segmentation by country
# Author: J.Glenn
# Date: 2026-07-16
######################################################

# - Import libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# - Import dataset
ltv = pd.read_csv("../data/ltvclean.csv")

# - Determine what  international countries spend and spending break down
ltv["total"] = ltv["Quantity"]*ltv["UnitPrice"]
country_smry = ltv.groupby("Country").agg(
    tot_rev=("total","sum"),
    unq_cust=("CustomerID", "nunique"),
    inv_cnt=("InvoiceNo", "nunique")
)  
intl = country_smry[country_smry.index != "United Kingdom"] 
intl["av_spend_by_cust"] = (intl["tot_rev"] / intl["unq_cust"]).round(2)
excl = intl[intl.index != "EIRE"] #  - Excluding EIRE (Ireland) for purpose of number of buys because it is an extreme outlier
excl["num_buys"] = (excl["inv_cnt"] / excl["unq_cust"]).round(0)

# - Prepare 3 vews to be visualized
top_10r = intl["tot_rev"].sort_values(ascending=False).head(10)
top_10a = intl["av_spend_by_cust"].sort_values(ascending=False).head(10)
top_10n = excl["num_buys"].sort_values(ascending=False).head(10) 

# - Plot International spending
fig, ax= plt.subplots(figsize=(10,8))

ax.barh(top_10r.index, top_10r.values, label="Revenue by Country")
ax.set_xlabel("Revenue Generated")
ax.set_title("International Revenue, Top 10 countries")

plt.tight_layout()
plt.savefig("../outputs/q3a_rev_by_country.png")

# - Plot for Average spend by customer per country
fig, ax= plt.subplots(figsize=(10,8))

ax.barh(top_10a.index, top_10a.values, label="Avg Spend")
ax.set_xlabel("Revenue Generated")
ax.set_title("Average Spent by Customer, Top 10 countries")

plt.tight_layout()
plt.savefig("../outputs/q3b_cus_spend_country.png")

# - Plot for Average Number of buys per customer per country
fig, ax= plt.subplots(figsize=(10,8))

ax.barh(top_10n.index, top_10n.values, label="Times")
ax.set_xlabel("Number of Purchases")
ax.set_title("Average Purchases by Customer, Top 10 countries")

plt.tight_layout()
plt.savefig("../outputs/q3c_purc_customer_country.png")