# --  import libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import sqlite3 as sq

# -- Connect to data
conn = sq.connect("../data/pinnacle.db")

# -- Load queries
query = """
    SELECT
        store_name,
        store_id
    FROM
        pinstor ps
    """
stores = pd.read_sql_query(query, conn)

query2 = """
    SELECT
        store_id,
        transaction_date as tx,
        total_amount
    FROM
        pintransact pt
    """
transact = pd.read_sql_query(query2, conn)

# -- Merge data frames
store_tx = pd.merge(stores, transact, on=['store_id'], how='inner')

# -- Transform date/time
store_tx['tx'] = pd.to_datetime(store_tx['tx'])
store_tx['tx_y'] = store_tx['tx'].dt.year
store_tx['tx_m'] = store_tx['tx'].dt.month 

# -- Create data frame for Store revenue/month
store_rev = store_tx.groupby(['store_name','tx_y','tx_m'])['total_amount'].sum()
store_rev = store_rev.reset_index()

# -- Preparing data to be merged to get YoY at store level
prior_rev = store_rev.copy()
prior_rev['tx_y'] = prior_rev['tx_y'] + 1
merged_store_rev = pd.merge(store_rev, prior_rev, on=['store_name','tx_y','tx_m'])

# -- Growth rate calculation
merged_store_rev['growth_rate'] = (merged_store_rev['total_amount_x'] - merged_store_rev['total_amount_y'])/merged_store_rev['total_amount_y']
merged_store_rev = merged_store_rev[~((merged_store_rev['tx_y'] == 2025) & merged_store_rev['tx_m'] == 6)]
store_growth = merged_store_rev[merged_store_rev['tx_y'] == 2024][['store_name','tx_m','growth_rate']]

# -- 2025 Store Actuals
store_rev_25 = store_rev[store_rev['tx_y'] == 2025].copy()
store_rev_25 = store_rev_25[store_rev_25['tx_m'] != 6]

# -- 2024 Store Actuals
store_rev_24 = store_rev[store_rev['tx_y'] == 2024][['store_name','tx_y','tx_m','total_amount']]

# -- Merge 2024 & 2025 data
store_projections = pd.merge(store_rev_25, store_rev_24, on=['store_name','tx_m'], suffixes=('_2025','_2024'))
store_projections = pd.merge(store_projections, store_growth, on=['store_name','tx_m'])

# -- Projected Rev calculation
store_projections['proj_rev'] = store_projections['total_amount_2024'] * (1 + store_projections['growth_rate']) 

# -- Aggregate store totals for jan - may  for vis purposes
store_agg_24 = store_rev_24[store_rev_24['tx_m'] <6]
store_agg_24 = store_agg_24.groupby('store_name')['total_amount'].sum() 
store_agg_25 = store_rev_25[store_rev_25['tx_m'] <6]
store_agg_25 = store_agg_25.groupby('store_name',)['total_amount'].sum()
store_agg_pr = store_projections[store_projections['tx_m'] <6]
store_agg_pr = store_agg_pr.groupby('store_name')['proj_rev'].sum()

# -- Visualize store performance jan-may 2024, 2025 project, 2025 actual
names = store_agg_24.index.to_list()
x = np.arange(len(names))

fig, ax = plt.subplots(figsize=(12, 6))

width = 0.25

ax.bar(x - width, store_agg_24, width, label='2024 Actual')
ax.bar(x, store_agg_pr, width, label='2025 Projection')
ax.bar(x + width, store_agg_25, width, label='2025 Actual')
ax.set_xticks(x)
ax.set_xticklabels(names)
ax.legend()
ax.set_title('2024 Actual vs 2025 Projected & Actual (Store Level) | Jan–May 2025\nPinnacle Retail Group')

plt.savefig('../outputs/02_revenue_by_store.png', dpi=150, bbox_inches='tight')
plt.show()

# - Terminate connection
conn.close()