-- ============================================================
-- Project:          WC Pizza Co
-- Script:           04_staffing_vs_load.sql
-- Business Question: Which locations and shifts are understaffed
--                   relative to order volume on game days vs.
--                   non-game days?
-- Tables Used:      wc_orders, wc_order_items, wc_products,
--                   wc_shifts_scheduled, wc_shifts_actual,
--                   wc_stores
-- Date Window:      2026-01-01 through 2026-06-30
-- Purpose:          Compare scheduled and actual staff counts
--                   against non-beverage item volume by store,
--                   date, and shift to identify understaffing
--                   patterns on game days vs. non-game days
-- Author:           J. Glenn
-- Date:             2026-07-06
-- ============================================================
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
			,	COUNT(DISTINCT ac.employee_id_x) AS Staff_count
			FROM
				wc_shifts_actual ac
			JOIN
				wc_stores st
			ON st.store_id = ac.store_id
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
;