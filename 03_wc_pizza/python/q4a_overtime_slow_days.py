# - Import libraries
import pandas as pd
import numpy as np
import sqlite3 as sq
import matplotlib.pyplot as plt

# - Import data
conn = sq.connect("../data/wc_pizza.db")

# - Query data
query = """
    WITH load AS (-- CTE to derive volume of orders by store by day 
	SELECT
		store_name
	,	store_id
	,	date 
	,	COUNT(order_id) AS total_orders
	
	FROM
		wc_orders ord 
	GROUP BY
		store_id
	,	store_name
	,	date 	
	)
,	overtime AS ( -- CTE to derive overtime by store 
		SELECT
			store_id
		,	date
		,	SUM(overtime_hours) AS total_ot
	
		FROM
			wc_shifts_actual
		GROUP BY
			store_id
		,	date 
		)
,	threshold AS (
		SELECT 
			AVG(total_orders) AS av_ord
		FROM
			load 
		)
SELECT
	l.store_name
,	ROUND(AVG(l.total_orders),2) AS Av_orders
,	ROUND(t.av_ord,2) AS Company_av
,	ROUND(AVG(o.total_ot),2) AS Av_ot
,	CASE WHEN l.total_orders < t.av_ord THEN 'Slow' ELSE 'Busy' END AS 'Velocity'
FROM
	load l
JOIN
	overtime o
ON	l.store_id = o.store_id AND l.date = o.date  
CROSS JOIN threshold t
GROUP BY
	l.store_name
,	Velocity
"""
ot = pd.read_sql_query(query, conn)

# - Pivot data for visualization
ot_pivot = ot.pivot(index='store_name', columns='Velocity', values='Av_ot')

# - Plot data
x = np.arange(len(ot_pivot))

fig, ax = plt.subplots(figsize=(12, 8))

width = 0.3

ax.bar(x - width, ot_pivot['Slow'], width, label='Slow')
ax.bar(x, ot_pivot['Busy'], width, label='Busy')
ax.set_xticks(x)
ax.legend()
ax.set_ylabel('Average overtime hours')
ax.set_xlabel('Store')
ax.set_title('Comparison overtime hours slow v busy times')
ax.set_xticklabels(ot_pivot.index)  

plt.savefig("../outputs/q4a_overtime_slow_days.png", dpi=150, bbox_inches="tight")
plt.show()

# - Terminate Connection
conn.close()