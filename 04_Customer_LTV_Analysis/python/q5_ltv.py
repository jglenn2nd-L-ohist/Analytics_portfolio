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
avg_mat = avg_mat[avg_mat.count(axis=1) >= 3]
t_avg = avg_mat.mean(axis=1)
t_avg = t_avg[t_avg.index != pd.Period("2011-05", "M")] 

# - Create  heatmap for matrix
fig, ax = plt.subplots(figsize=(11,6))
sns.heatmap(avg_mat, annot=True, fmt=".0f", cmap="Blues", ax=ax, vmax=50)

plt.title("Cohort average revenue per month")
plt.tight_layout()

plt.savefig("../outputs/q5_ltv.png")

# - Create chart for total average cohort spend
fig, ax = plt.subplots(figsize=(10,6))

ax.barh(t_avg.index.astype(str), t_avg.values, label="Avg Revenue/Month By Cohort")
ax.set_xlabel("Revenue generated")
ax.set_title("Avg Revenue by Cohort by Month - Excluding 2011-05 Outlier")

plt.savefig("../outputs/q5b_ltv_avg.png")
plt.show()