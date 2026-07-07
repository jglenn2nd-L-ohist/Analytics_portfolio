# -- Import libraries
import pandas as pd
import sqlite3 as sq
import matplotlib.pyplot as plt
import seaborn as sns

# -- Connect to database
conn = sq.connect("../data/pinnacle.db")

# -- Query tables
# -- load store table
query = """ 
    SELECT
        store_id
    ,   store_name
    FROM
        pinstor
"""
stor = pd.read_sql_query(query, conn)
# -- load product table
query1 = """ 
    SELECT
        category
    ,   product_name
    ,   product_id
    FROM
        pinprod
    """
prod = pd.read_sql_query(query1, conn)
# -- load transactions table
query2 = """
    SELECT
        product_id
    ,   quantity    
    ,   return_flag
    ,   store_id
    FROM
        pintransact
    """
transact = pd.read_sql_query(query2, conn)

# -- Merge tables
# -- Merge store with transact
stor_tx = pd.merge(stor, transact, on=['store_id'], how="inner")
# -- Merge new set with product to get all needed info
merged_stor = pd.merge(stor_tx, prod, on=['product_id'], how="left")

# -- Transform 'return_flag' to boolean
merged_stor = merged_stor.dropna(subset=['return_flag'])
merged_stor['return_flag'] = merged_stor['return_flag'].str.lower().isin(['yes', 'y', 'true'])
merged_stor['return_units'] = merged_stor['return_flag'] * merged_stor['quantity']

# -- aggregate returns by store/category
returns = merged_stor.groupby(['store_name','category']).agg(
    total=('quantity', 'sum'),
    returns=('return_units', 'sum')
)
returns['rate'] = returns['returns']/returns['total']
returns = returns.reset_index()

# -- Pivot table to prepare for heatmap
pivot = returns.pivot(index='category', columns='store_name', values='rate')

# -- Heat mapping
fig, ax = plt.subplots(figsize=(12, 7))
sns.heatmap(pivot, annot=True, fmt= '.0%', cmap='Reds', ax=ax)

plt.title('Return Rates by Store/Category')
plt.tight_layout()

plt.savefig('../outputs/03_return_rate_heatmap.png', dpi=150, bbox_inches='tight')
plt.show()

# - Terminate connection
conn.close()
