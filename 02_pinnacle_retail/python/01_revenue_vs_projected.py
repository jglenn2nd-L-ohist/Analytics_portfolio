# -- Import libraries
import pandas as pd
import sqlite3 as sq
import matplotlib.pyplot as plt
import numpy as np

# -- Connect to data
conn = sq.connect("../data/pinnacle.db")

# -- Query data
query = """
SELECT
    *
FROM
    pintransact
"""
transact = pd.read_sql_query(query, conn)

# Convert transacttion date into date time format
transact['transaction_date'] = pd.to_datetime(transact['transaction_date'])
transact['transact_year'] = transact['transaction_date'].dt.year
transact['transact_month'] = transact['transaction_date'].dt.month

# -- Create monthly revenue dataframe
monthly_revenue = transact.groupby(['transact_year', 'transact_month'])['total_amount'].sum()
monthly_revenue = monthly_revenue.reset_index()

# -- Preparing to merge data set to get YoY data
prior_year = monthly_revenue.copy()
prior_year['transact_year'] = prior_year['transact_year'] + 1
merged_m_revenue = pd.merge(monthly_revenue, prior_year, on=['transact_year','transact_month'])

# -- Growth rate calaculation
merged_m_revenue['growth_rate'] = (merged_m_revenue['total_amount_x'] - merged_m_revenue['total_amount_y'])/merged_m_revenue['total_amount_y']
merged_m_revenue = merged_m_revenue[~((merged_m_revenue['transact_year'] == 2025) & (merged_m_revenue['transact_month'] == 6))]

# -- Get 2023 to 2024 growth rates
growth_rates = merged_m_revenue[merged_m_revenue['transact_year'] == 2024][['transact_month', 'growth_rate']]

# -- Get 2025 actuals
actuals_2025 = monthly_revenue[monthly_revenue['transact_year'] == 2025].copy()
actuals_2025 = actuals_2025[actuals_2025['transact_month'] != 6]

# -- Get 2024 actuals (this is the base we grow forward)
actuals_2024 = monthly_revenue[monthly_revenue['transact_year'] == 2024][['transact_month', 'total_amount']]

# -- Merge everything together
projection = pd.merge(actuals_2025, actuals_2024, on='transact_month', suffixes=('_2025', '_2024'))
projection = pd.merge(projection, growth_rates, on='transact_month')

# -- Calculate projected revenue
projection['projected_rev'] = projection['total_amount_2024'] * (1 + projection['growth_rate'])



# -- Visualize actual v projection
months = projection['transact_month'].tolist()
x = np.arange(len(months))

fig, ax = plt.subplots(figsize=(12, 6))

width = 0.25

ax.bar(x - width, projection['total_amount_2024'],width, label='2024 Actual')
ax.bar(x, projection['projected_rev'],width, label='2025 Projected')
ax.bar(x + width, projection['total_amount_2025'], width, label='2025 Actual')
ax.set_xticks(x)
ax.set_xticklabels(['Jan','Feb','Mar','Apr','May'])
ax.legend()
ax.set_title('2024 Actual vs 2025 Projected & Actual | Jan–May 2025\nPinnacle Retail Group')

plt.savefig('../outputs/01_revenue_vs_projected.png', dpi=150, bbox_inches='tight')
plt.show()

