######################################
- Project: World Cup Pizza Company
- Script: 03_Ingredients_game_day.sql
- Question: What are the ingredients necessary to supply game day demand on a store level?
- Tables: wc_orders, wc_order_items, wc_products, wc_recipes, wc_ingredients
- Game day window: 2026-06-15 through 2026-06-30
- Purpose: Project the necessary ingredients for the July7 and 15 games
- Author: J. Glenn
- Date: 2026-07
######################################
WITH totals AS (	
	SELECT
		o.store_name AS Store 
	,	SUM(oi.quantity) AS total_sold
	,  	p.product_name AS item
	,	i.ingredient_name AS ingredients
	,	SUM(r.quantity_per_order * oi.quantity) AS num_ingr
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
	JOIN 
		wc_recipes r
	ON
		p.product_id = r.product_id
	JOIN
		wc_ingredients i
	ON	
		r.ingredient_name = i.ingredient_name
	WHERE
		o.is_game_day = 1 AND (o.date BETWEEN '2026-06-15' AND '2026-06-30') AND p.category	!= 'Beverages'
	GROUP BY
		o.store_name
	,	p.product_name
	, 	i.ingredient_name
	)

		
SELECT
	Store 
,	ingredients
,	Num_ingr
FROM
	totals
GROUP BY
	Store 
,   Ingredients 
ORDER BY 
	Store 
,	ingredients
,	num_ingr DESC
;