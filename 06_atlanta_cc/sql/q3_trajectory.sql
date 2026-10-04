-----------------------------------------------------------------
-- Project: Safe haven or Wild West
-- Filename: q3_trajectory.sql
-- TABLE: acc
-- Business Question: Determine the overall trend of firearm involved
--                    violence during the Dickens era in conjunction
--                    with constitutional carry
-- Purpose: Reveal the overall trend of gun related deaths from  
--          2022-2026 
-- Author: J.Glenn
-- Date Project Started: 2026-07-31 
-----------------------------------------------------------------
-- Determine crime rate and firearm use
WITH year_labels AS ( -- Break down 48m into years for equal comparisons
    SELECT
        *
    ,    CASE WHEN strftime('%Y/%m', ReportDate) < '2023/04' THEN '2022-2023'
			  WHEN strftime('%Y/%m', ReportDate) < '2024/04' THEN '2023-2024'
              WHEN strftime('%Y/%m', ReportDate) < '2025/04' THEN '2024-2025'
              WHEN strftime('%Y/%m', ReportDate) < '2026/04' THEN '2025-2026'
              ELSE 'Out_of_range'
			 END AS policy_year
    FROM acc
)
,
		crimes AS (
			SELECT
				count(*) incidents
			,	policy_year
			,	COUNT(CASE WHEN FireArmInvolved LIKE 'y%' THEN 1 END)  firearms 
			FROM
				year_labels
			GROUP BY
				policy_year
)
,
		yoy_c AS (  -- Determine YOY firearm change
			SELECT
				policy_year
			, 	firearms
			,	LAG(firearms)OVER(ORDER BY policy_year) AS prior_year_f
			FROM
				crimes
)
,
		homicide AS (	-- Determine homicide rate over the years
			SELECT
				COUNT(*) homicides
			, 	policy_year

			FROM
				year_labels
			WHERE
			FireArmInvolved LIKE 'y%' AND
			NibrsUcrCode = '09A' -- 09a is the code for Murder in the NIBRS_Offense
			GROUP BY
				policy_year
)	
,
		yoy_h AS ( -- Determine YOY homicide changes
			SELECT
				policy_year
			,	homicides
			,	LAG(homicides)OVER(ORDER BY policy_year) AS prior_year_h
			FROM
				homicide
)
SELECT
	c.policy_year
,	c.incidents
,	c.firearms
,	yc.prior_year_f AS firearm_incidentss_prior_year
,	(yc.firearms - yc.prior_year_f) AS yoy_firearm_incident_change
,	COALESCE(h.homicides, 0) AS homicides
,	yh.prior_year_h AS homicides_prior_year
,	(yh.homicides - yh.prior_year_h) AS yoy_homicide_change
,	ROUND((c.firearms *100.0 /c.incidents ),2)  pcnt_firearms
,	ROUND((h.homicides *100.0/c.firearms ),2)  firearm_homicides_per_100_firearm_incidents

FROM
	crimes c
LEFT JOIN
	homicide h
ON	c.policy_year = h.policy_year
LEFT JOIN
	yoy_h yh
ON	c.policy_year = yh.policy_year
LEFT JOIN
	yoy_c yc
ON c.policy_year = yc.policy_year
;
