######################################################
# Project: Customer Lifetime Value Analysis
# Filename: q5_ltv.py
# Business Question: What are our customer tendencies and what is their lifetime value?
# Purpose: To discover how much each cohort spends on average over time
# Author: J.Glenn
# Date: 2026-07-20
######################################################

# - Import libraries
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

# - Import dataset
ltv = pd.read_csv("../data/ltvclean.csv")

# - Convert InvoiceDate to date from string
ltv["InvoiceDate"] = pd.to_datetime(ltv["InvoiceDate"], format="mixed")
ltv["InvoiceDate"] = ltv["InvoiceDate"].dt.to_period('M')

# - Create revenue column
ltv["revenue"] = ltv["UnitPrice"]*ltv["Quantity"]

# - Create cohort
cohort = ltv.groupby("CustomerID")["InvoiceDate"].min()
ltv["cohort"] = ltv["CustomerID"].map(cohort)
ltv["period"] = (ltv["InvoiceDate"] - ltv["cohort"]).apply(lambda x: x.n)

# - Determine cohort avg revenue
avg = ltv.groupby(["cohort","period"])["revenue"].mean()
avg_mat = avg.unstack()

# - Create  heatmap
fig, ax = plt.subplots(figsize=(11,6))
sns.heatmap(avg_mat, annot=True, fmt="0.0f", cmap="Blues", ax=ax, vmax=50)

plt.title("Cohort average revenue per month")
plt.tight_layout()

plt.savefig("../outputs/q5_ltv.png")
plt.show()