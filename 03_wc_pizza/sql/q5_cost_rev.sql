-- ============================================================
-- Project:          WC Pizza Co
-- Script:           q5_cost_rev.sql
-- Business Question: What does cost and revenue margins look like
--                   game day v non-game day?
-- Tables Used:      wc_shifts_actual, wc_order_items, wc_products
--                   wc_stores, wc_orders
-- Date Window:      2026-01-01 through 2026-06-30
-- Purpose:          Compare total revenue to total costs comparing
--                   game day v non game day
-- Author:           J. Glenn
-- Date:             2026-07
-- ============================================================
WITH labor AS( -- Labor costs
	SELECT
		store_id
	,	SUM(labor_cost) tl_cost	
	,	CASE WHEN is_game_day = 1 THEN 'Y' ELSE 'N' END AS 'game_day'
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
	s.store_name
,	g.tot_rev
,	(l.tl_cost + g.tg_cost) tot_costs
,	g.tot_rev - (l.tl_cost + g.tg_cost) margin
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
;