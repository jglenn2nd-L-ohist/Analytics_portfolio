# Attribution Gap Analysis
# Connects to SQLite, runs a query, and visualizes unattributed leads

import sqlite3
import pandas as pd 
import matplotlib.pyplot as plt 

# --- Connect to database ---
conn = sqlite3.connect("../data/lead_attribution.db")

# --- Query ---
query = """
SELECT
    CASE
        WHEN "First source" = '-' THEN 'Unattributed'
        ELSE 'Attributed'
    END AS Attribution_status,
    COUNT(*) AS lead_count
FROM
    hyros
GROUP BY 
    1
"""

df = pd.read_sql_query(query, conn)
conn.close()

print(df)

# --- Chart ---
colors = ['#2E4057', '#E84855']

plt.figure(figsize=(6,4))
plt.bar(df['Attribution_status'], df['lead_count'], color=colors)
plt.title('Lead Attribution Gap', fontsize=14)
plt.xlabel('Attribution Status')
plt.ylabel('Lead Count')
plt.tight_layout()
plt.savefig('../data/attribution_gap.png')
print("Chart saved.")