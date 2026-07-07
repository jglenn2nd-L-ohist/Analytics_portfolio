######################################
- Project: World Cup Pizza Company
- Script: q4a_overtime_slow_days.sql
- Question: Where is the labor cost leak on slow days?
- Tables: wc_orders, wc_shifts_actual
- Date window: 2026-01-01 through 2026-06-30
- Author: J. Glenn
- Date: 2026-07
######################################

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
;