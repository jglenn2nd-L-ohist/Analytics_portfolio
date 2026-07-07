######################################
- Project: World Cup Pizza Company
- Script: q3_baseline_staffing.sql
- Question: What does normal staffing look like pre-event?
- Tables: wc_shifts_actual, wc_stores
- Baseline window: 2026-01-01 through 2026-06-14
- Author: J. Glenn
- Date: 2026-07
######################################

WITH totals AS ( -- CTE to determine total hours per day per store 
	SELECT
		st.store_name AS Store
	,	sa.date 
	,	CASE strftime('%w',sa.date) 
			WHEN '0' THEN 'Sunday' 
			WHEN '1' THEN 'Monday'
			WHEN '2' THEN 'Tuesday' 
			WHEN '3' THEN 'Wednesday' 
			WHEN '4' THEN 'Thursday'
			WHEN '5' THEN 'Friday'
			WHEN '6' THEN 'Saturday'
			END as day_of_week
	,	strftime('%w', sa.date) AS day_num  -- Function to be able to have days output in calendar format
	,	ROUND(SUM(sa.scheduled_hours),2) AS tot_hours_sch
	, 	ROUND(SUM(sa.actual_hours),2) AS tot_hours_wrk
	FROM
		wc_shifts_actual sa
	JOIN	
		wc_stores st
	ON st.store_id = sa.store_id
	WHERE sa.date < '2026-06-15'
	GROUP BY
		Store, day_of_week, sa.date 
	)
SELECT
	store 
,	day_of_week
,	ROUND(AVG(tot_hours_sch),2) AS A_hrs_sch
,	ROUND(AVG(tot_hours_wrk),2) AS A_hrs_wrk
FROM
	totals
GROUP BY
	Store, day_of_week
ORDER BY
	store, day_num
;    