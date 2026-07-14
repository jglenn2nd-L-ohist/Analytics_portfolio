######################################################
# Project: Customer Lifetime Value Analysis
# Filename: q1_customer_profile.py
# Business Question: What are our customer tendencies and what is their lifetime value?
# Purpose: Determine who are the customers
# Author: J.Glenn
# Date: 2026-07-14
######################################################

# - Import libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# - Import dataset
ltv = pd.read_csv("../data/ltvclean.csv")

# - Determine date of customer's first purchase
early = ltv.groupby('CustomerID')['InvoiceDate'].min()

# - Generate total spend per customer engineer 'total'
ltv['total'] = ltv['Quantity']*ltv['UnitPrice']
all_sales = ltv.groupby('CustomerID')['total'].sum()

# - Genereate total number of sales by customer
times = ltv.groupby('CustomerID')['InvoiceNo'].count()
print(times.head())

# -Merge all_sales / early / times
profile = pd.DataFrame({
    'first_purchase': early,
    'total_spend': all_sales,
    'purchases': times
})

# - Export to Outputs as csv
profile.to_csv("../outputs/q1_customer_profile.csv")

# - Plot histogram for customer profile
plt.figure(figsize=(10,6))
profile[profile['purchases'] <= profile['purchases'].quantile(0.95)]['purchases'].hist()
plt.title('Customer Purchase Frequency Histogram')
plt.xlabel('Number of Purchases')
plt.ylabel('Number of Customers')
plt.tight_layout()
plt.savefig('../outputs/q1_purchase_distribution.png')
plt.show()