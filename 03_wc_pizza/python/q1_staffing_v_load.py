# - Import libraries
import pandas as pd 
import numpy as np
import sqlite3 as sq
import matplotlib.pyplot as plt

# - Import dataset
conn = sq.connect("../data/wc_pizza.db")

# - Query data
query = """
WITH load AS (  -- Determine order volume by store/date/shift (taking into account order type)
	SELECT
		ord.store_name AS store 
	,	ord.date 
	,	ord.shift 
	,	ord.order_type
	,	(sum(oi.quantity) *1.0 ) AS Num_orders
	,	ord.is_game_day 
	FROM
		wc_order_items oi
	JOIN
		wc_products p
	ON p.product_id = oi.product_id
	JOIN
		wc_orders ord 
	ON	ord.order_id = oi.order_id
	WHERE	
		p.category != 'Beverages'
	GROUP BY
		ord.store_name 
	,	ord.date
	,	ord.shift
	,	ord.order_type
	,	ord.is_game_day
	)
,	sched AS (   -- Determine scheduled staff levels by store/date/shift 
		SELECT
			st.store_name AS store 
		,	sch.date
		,	sch.shift
		,	sch.scheduled_staff
		FROM
			wc_shifts_scheduled sch 
		JOIN
			wc_stores st
		ON st.store_id = sch.store_id
		)
,		actual AS (  -- Determine worked staff levels by store/date/shift 
			SELECT
				st.store_name AS store 
			,	ac.date
			,	ac.shift
			,	COUNT(DISTINCT ac.employee_id) AS Staff_count
			FROM
				wc_shifts_actual ac
			JOIN
				wc_stores st
			ON st.store_id = ac.store_id
			WHERE ac.title IN ('Shift Lead','Cook','Server') -- Filtered to omit non-load bearing staff
			GROUP BY
				st.store_name
			,	ac.date
			,	ac.shift
			)
SELECT
	l.store 
,	l.date
,	l.shift
,	l.order_type
,	l.num_orders
, 	ROUND((l.num_orders)/(a.staff_count),2) AS order_per_person
,	s.scheduled_staff
,	a.staff_count
,	l.is_game_day
FROM 
	load l
JOIN
	sched s
ON l.store = s.store AND l.date = s.date AND l.shift = s.shift 
JOIN
	actual a
ON
	l.store = a.store AND l.date = a.date AND l.shift = a.shift 
"""

loads = pd.read_sql_query(query, conn)

# - Create CSV loaded into data folder
loads.to_csv("../data/loads.csv")

# - grouping by store & game_day 
df = loads.groupby(['store','is_game_day'])['order_per_person'].mean().reset_index()    

# - pivot data for visualization
pivot = df.pivot(index='store',columns='is_game_day', values='order_per_person')

# - Plot the data
x = np.arange(len(pivot))

fig, ax = plt.subplots(figsize=(12, 8))

width = 0.3

ax.bar(x - width, pivot[1], width, label="Game Day" )
ax.bar(x, pivot[0], width, label="No Game")
ax.set_xticks(x)
ax.legend()
ax.set_ylabel('Avg Orders per Employee per Shift')
ax.set_xlabel("Store")
ax.set_title("Staffing load comparison Game day v Regular Day")
ax.set_xticklabels(pivot.index)

plt.savefig('../outputs/04_staffing_v_load.png', dpi=150, bbox_inches='tight')
plt.show()  

# - Terminate connection
conn.close()