######################################################
# Project: Customer Lifetime Value Analysis
# Filename: q4_cohort.py
# Business Question: What are our customer tendencies and what is their lifetime value?
# Purpose: To discover retention & growth pattern of customer cohorts
# Author: J.Glenn
# Date: 2026-07-17
######################################################

# - Import libraries
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

# - Import dataset
ltv = pd.read_csv("../data/ltvclean.csv")

# - Transform data type & extract month
ltv["InvoiceDate"] = pd.to_datetime(ltv["InvoiceDate"], format="mixed")
ltv["InvoiceDate"] = ltv["InvoiceDate"].dt.to_period('M')

# - Establish cohort
cohort = ltv.groupby("CustomerID")["InvoiceDate"].min()
ltv["cohort"] = ltv["CustomerID"].map(cohort)
ltv["period"] = (ltv["InvoiceDate"] - ltv["cohort"]).apply(lambda x: x.n)

# - Determine number of customers per cohort
uniq = ltv.groupby(["cohort","period"])["CustomerID"].count()
cohort_mat = uniq.unstack()

# - Determine retention rate of the cohort
r_rate = cohort_mat.div(cohort_mat[0], axis=0)

# - construct heatmap to visualize retention rates
fig, ax = plt.subplots(figsize=(10,6))
sns.heatmap(r_rate, annot=True, fmt="0.0%", cmap="Greens", ax=ax)

plt.title("Cohort/Period Retention Rate Heatmap")
plt.tight_layout()

plt.savefig("../outputs/q4_cohort.png")
plt.show()