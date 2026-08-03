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
WITH crimes AS(
		SELECT
			count(*) incidents
		,	strftime('%Y', ReportDate) inc_year
		,	COUNT(CASE WHEN FireArmInvolved LIKE 'y%' THEN 1 END)  firearms 
		FROM
			acc
		GROUP BY
			inc_year
		)
,
		homicide AS (	-- Determine homicide rate over the years
			SELECT
				COUNT(*) homicides
			, 	strftime('%Y', ReportDate) inc_year

			FROM
				acc
			WHERE
			NibrsUcrCode = '09A' -- 09a is the code for Murder in the NIBRS_Offense
			GROUP BY
				inc_year
			)	
SELECT
	c.firearms
,	h.homicides
,	c.incidents
,	ROUND((c.firearms *1.0 /c.incidents *1.0),4) *100.0 pcnt_firearms
,	ROUND((h.homicides *1.0/c.incidents *1.0),4) *100.00 pcnt_crime
,	c.inc_year
FROM
	crimes c
JOIN
	homicide h
ON	c.inc_year = h.inc_year

