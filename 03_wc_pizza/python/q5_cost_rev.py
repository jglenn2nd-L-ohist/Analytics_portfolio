# - Import libraries
import pandas as pd
import numpy as np
import sqlite3 as sq
import matplotlib.pyplot as plt

# - Import dataset
conn = sq.connect("../data/wc_pizza.db")

# - Query data
query = """
WITH labor AS( -- Labor costs
	SELECT
		store_id
	,	SUM(labor_cost) tl_cost	
	,	CASE WHEN is_game_day = 1 THEN 'Y' ELSE 'N' END AS 'game_day'
	,	COUNT(DISTINCT(date)) num_days
	FROM
		wc_shifts_actual 
	GROUP BY
		store_id
	,	CASE WHEN is_game_day = 1 THEN 'Y' ELSE 'N' END
	)
,	goods AS ( -- Goods costs
		SELECT
		o.store_id
	,	SUM(p.cogs * i.quantity) tg_cost
	,	sum(i.line_total) tot_rev
	,	COUNT(o.order_id) num_order
	,	CASE WHEN is_game_day = 1 THEN 'Y' ELSE 'N' END AS 'game_day'
		FROM		
			wc_order_items i
		JOIN
			wc_products p
		ON
			i.product_id = p.product_id
		JOIN 
			wc_orders o
		ON
			o.order_id = i.order_id
		GROUP BY
			o.store_id
		,	CASE WHEN is_game_day = 1 THEN 'Y' ELSE 'N' END
	)
	
SELECT 
	s.store_name store
,	g.tot_rev
,	(l.tl_cost + g.tg_cost) tot_costs
,	ROUND((g.tot_rev - (l.tl_cost + g.tg_cost))/l.num_days,2) margin
,	ROUND((l.tl_cost + g.tg_cost)/ num_order,2) cost_per_order
,	l.game_day
FROM
	labor l
JOIN
	goods g
ON
	l.store_id = g.store_id AND l.game_day = g.game_day
JOIN
	wc_stores s
ON
	l.store_id = s.store_id
GROUP BY
	l.store_id
,	l.game_day
"""

cost = pd.read_sql_query(query, conn)

# - Create CSV downloaded to data folder
cost.to_csv("../data/cost.csv")

# - prepare data for pivot by grouping on store & game day
df = cost.groupby(['store','game_day'])['margin'].mean().reset_index()

# - Pivot data
pivot = df.pivot(index='store', columns='game_day', values='margin')

# - Plot grouped bar chart
x = np.arange(len(pivot))

fig, ax = plt.subplots(figsize=(12, 8))

width = 0.3

ax.bar(x - width/2, pivot["Y"], width, label="Game Day" )
ax.bar(x + width/2, pivot["N"], width, label="No Game")
ax.set_xlabel("Game Day v No Game")
ax.set_xticks(x)
ax.legend()
ax.set_ylabel("margin")
ax.set_title("Game day v Non-Game Day Margins")
ax.set_xticklabels(pivot.index)

plt.savefig("../outputs/q5_cost_rev.png")
plt.show()