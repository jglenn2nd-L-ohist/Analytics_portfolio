-- ============================================================
-- Project:          WC Pizza Co
-- Script:           q4b_scheduling_variance.sql
-- Business Question: What do store level hours worked show
--                   When compared to the scheduled (budgeted) hours?
-- Tables Used:      wc_shifts_scheduled, wc_shifts_actual,
--                   wc_stores
-- Date Window:      2026-01-01 through 2026-06-30
-- Purpose:          Compare scheduling budgets to the actual hours
--					 worked by each location
-- Author:           J. Glenn
-- Date:             2026-07
-- ============================================================

WITH act AS ( --Actual hours worked by store
	SELECT
		a.store_id
	,	s.store_name
	,	SUM(a.actual_hours) AS act_hours
	FROM
		wc_shifts_actual a
	JOIN
		wc_stores s
	ON a.store_id = s.store_id
	GROUP BY
		a.store_id
	,	s.store_name
	)
,	Schd AS ( -- Scheduled hours by store
			SELECT
			store_id 
		,	SUM((shift_end - shift_start) * scheduled_staff) AS Scd_hours
		FROM
		wc_shifts_scheduled
		GROUP BY
			store_id
		)
SELECT
	a.store_id
,	a.store_name
, 	a.act_hours
,	SUM(s.scd_hours) AS Schd_hours
,	ROUND((SUM(a.act_hours) - (s.scd_hours)),2) AS Sched_var
FROM
	act a
JOIN
	schd s
ON a.store_id = s.store_id
GROUP BY
	a.Store_name
ORDER BY
	a.store_id
;