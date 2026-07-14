######################################################
# Project: Customer Lifetime Value Analysis
# Filename: 00_profile.py
# Business Question: What are our customer tendencies and what is their lifetime value?
# Purpose: Determine data irregularities, prepare for data cleaning
# Author: J.Glenn
# Date: 2026-07-14
######################################################

# - Import libraries
import pandas as pd
import numpy as np

# - Import data set
uci = pd.read_csv("../data/UCIOnlineRetail.csv")

# - Preview data
print(uci.shape)
print(uci.describe())
print(uci.info())

# - Duplicate check
print("duplicate rows:", uci.duplicated().sum())

# - Cancellation check
print("Cancellations:", uci['InvoiceNo'].str.startswith('C').sum())


# - Check for negatives outside of Cancelled orders
neg = uci[~uci['InvoiceNo'].str.startswith('C')]
print("Negative quantities apart from cancellations", (neg['Quantity']< 0).sum())
print("Negative quantities apart from cancellations", (neg['UnitPrice']< 0).sum())

