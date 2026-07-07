######################################
- Project: World Cup Pizza Company
- Script: q2_game_day_demand.sql
- Question: What are the highest demand products on game days by store?
- Tables: wc_orders, wc_order_items, wc_products
- Game day window: 2026-06-15 through 2026-06-30
- Note: July match dates (7/7, 7/15) excluded - unconfirmed bracket dates
- Author: J. Glenn
- Date: 2026-07
######################################

WITH totals AS (	
	SELECT
		o.store_name AS Store 
	,	SUM(oi.quantity) AS total_sold
	,  	p.product_name AS item
	FROM
		wc_orders o
	JOIN
		wc_order_items oi
	ON
		o.order_id = oi.order_id
	JOIN	
		wc_products p
	ON
		oi.product_id = p.product_id
	WHERE
		o.is_game_day = 1 AND (o.date BETWEEN '2026-06-15' AND '2026-06-30') AND p.category	!= 'Beverages'
	GROUP BY
		o.store_name
	,	p.product_name
	)
,	Top AS (
		SELECT
			
			RANK()OVER(PARTITION BY Store ORDER BY total_sold DESC) AS Most_popular
		,	Store 
		, 	total_sold 
		,	item
		FROM
			totals
		)
SELECT
	Store 
,	Item
,	Total_sold
,	Most_popular
FROM
	Top
WHERE	
	Most_popular < 6	
;