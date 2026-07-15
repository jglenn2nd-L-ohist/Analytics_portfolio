######################################################
# Project: Customer Lifetime Value Analysis
# Filename: q2_buying_habits.py
# Business Question: What are our customer tendencies and what is their lifetime value?
# Purpose: To understand customer patterns through recency/frequency/monetary (RFM)
# Author: J.Glenn
# Date: 2026-07-15
######################################################

# - Import libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# - Import dataset
ltv = pd.read_csv("../data/ltvclean.csv", parse_dates=["InvoiceDate"])

# - Determine Customer's Frequency of purchases (avg days between buys)
freq = ltv.groupby("CustomerID")["InvoiceNo"].count()
# - Determine date of customer's first purchase
early = ltv.groupby("CustomerID")["InvoiceDate"].min()
# - eoy gives anchor for frequency calculation
eoy = pd.Timestamp("2011-12-31")
av_day = pd.merge(freq, early, how="inner", left_index=True, right_index=True)
av_day["active_days"] = eoy - av_day["InvoiceDate"]
av_day["active_days"] = av_day["active_days"].dt.days
av_day["InvoiceDate"] = av_day["InvoiceDate"].dt.date 
av_day["days_buys"] = av_day["active_days"]/ freq 
print(av_day.head())

# - Determine customer's most recent transactions
rec = ltv.groupby("CustomerID")["InvoiceDate"].max().dt.date
print(rec.head())

# - Determine customer's average spend - engineer total spend
ltv['total'] = ltv['Quantity']*ltv['UnitPrice']
a_spend = ltv.groupby("CustomerID")["total"].mean().round(2)
print(a_spend.head())

# - Determine customer's total annual spend
t_spend = ltv.groupby("CustomerID")["total"].sum()
print(t_spend.head())   

# - Merge all sets
rec.name = 'last_purchase'
a_spend.name = 'avg_spend'
t_spend.name = 'total_spend'
rec_day = pd.merge(av_day, rec, how="inner", left_index=True, right_index=True)
a_rec = pd.merge(rec_day, a_spend, how="inner", left_index=True, right_index=True)
habits = pd.merge(a_rec, t_spend, how="inner", left_index=True, right_index=True)
habits.rename(columns={"InvoiceDate": "first_purchase"}, inplace=True)
habits.rename(columns={"InvoiceNo": "purchases_made"}, inplace=True)
print(habits.head())

# - Export to csv
habits.to_csv("../outputs/q2_buying_habits.csv")