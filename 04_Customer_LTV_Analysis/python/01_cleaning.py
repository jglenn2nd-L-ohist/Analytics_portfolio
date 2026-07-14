######################################################
# Project: Customer Lifetime Value Analysis
# Filename: 01_clean.py
# Business Question: What are our customer tendencies and what is their lifetime value?
# Purpose: Clean known data quality issues to prepare for analysis
# Author: J.Glenn
# Date: 2026-07-14
######################################################
# - Import libraries
import pandas as pd
import numpy as np

# - import data
ltv = pd.read_csv("../data/UCIOnlineRetail.csv")

# - Drop Null CustomerId
ltv = ltv.dropna(subset=['CustomerID'])
print(ltv.shape)

# - Drop cancelled orders
ltv = ltv[~ltv['InvoiceNo'].str.startswith('C')]
print(ltv.shape)

# - Drop negative quantities
ltv = ltv[ltv['Quantity'] >0]
print(ltv.shape)

# - Drop negative unitprice
ltv = ltv[ltv['UnitPrice'] >0]
print(ltv.shape)

# - Deduplicate dataframe
ltv = ltv.drop_duplicates()
print(ltv.shape)

# - Transform InvoiceDate to datetime
ltv['InvoiceDate'] = pd.to_datetime(ltv['InvoiceDate'], dayfirst=True)
print(ltv.info())

# - Export to CSV

ltv.to_csv("../data/ltvclean.csv")
