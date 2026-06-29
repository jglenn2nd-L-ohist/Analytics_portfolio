# -- Import libraries
import pandas as pd
import sqlite3 as sq
import matplotlib.pyplot as plt 

# -- Load database
conn = sq.connect("../data/pinnacle.db")

# -- Write the queries
query1 = """
    WITH stockout_base AS (
	SELECT
		store_id
	,	product_id
	,	ADJUSTED_quantity_on_hand AS qoh
	,	reorder_point AS reorder 
	,	CASE WHEN ADJUSTED_quantity_on_hand >	1.5*(reorder_point) THEN 'Good'
			 WHEN ADJUSTED_quantity_on_hand BETWEEN reorder_point AND 1.5*(reorder_point) THEN 'stockout risk'
			 WHEN ADJUSTED_quantity_on_hand < reorder_point OR reorder_point ISNULL THEN 'Immediate Reorder'
			 END AS Stockout_threat
	FROM
		pininv
	)
	
		SELECT
			ps.store_name
		, 	pp.product_name
		,	pp.category
		, 	sb.qoh
		,	sb.reorder 
		, 	sb.Stockout_threat
		FROM
			stockout_base sb
		JOIN
			pinstor ps
		ON ps.store_id = sb.store_id
		JOIN
			pinprod pp
		ON	pp.product_id = sb.product_id
		WHERE sb.Stockout_threat = 'Immediate Reorder'
        """
Stockout = pd.read_sql(query1, conn)

# -- Create table vis

fig, ax = plt.subplots(figsize=(10, 10))
ax.axis('off')

table_data = Stockout[['store_name', 'product_name', 'qoh', 'Stockout_threat']].values
col_labels = ['Store', 'Product', 'QOH', 'Status']

table = ax.table(
    cellText=table_data,
    colLabels=col_labels,
    loc='upper center'
)

table.auto_set_font_size(False)
table.set_fontsize(9)
table.auto_set_column_width([col for col in range(len(col_labels))])

plt.title('Immediate Reorder Alert — Pinnacle Retail Group', fontsize=13, pad=20)
plt.tight_layout()
plt.savefig('../outputs/04_stockout_table.png', dpi=150, bbox_inches='tight')
plt.show()