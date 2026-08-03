-----------------------------------------------------------------
-- Project: Safe haven or Wild West
-- Filename: q2_homicide.sql
-- TABLE: acc
-- Business Question: Determine the rate of firearm related homicides
--                    in Atlanta from 2022-2026
-- Purpose: Reveal the overall trend of gun related deaths from  
--          2022-2026 
-- Author: J.Glenn
-- Date Project Started: 2026-07-31 
-----------------------------------------------------------------
-- Determine homicide rate over the years
SELECT
	COUNT(*)
, 	strftime('%Y', ReportDate) inc_year

FROM
	acc
WHERE
NibrsUcrCode = '09A' -- 09a is the code for Murder in the NIBRS_Offense
GROUP BY
	inc_year