-----------------------------------------------------------------
-- Project: Safe haven or Wild West
-- Filename: q1_crimerate.sql
-- TABLE: acc
-- Business Question: How has firearm involvement in crime trended 
--                    annually since constitutional carry took effect
--                    in April 2022?
--                    Total firearm-involved incidents per year
--                    And the percent of total incidents per year
-- Purpose: Reveal whether Atlanta is a Safe haven or the Wild west
--          since the start of Constitutional Carry and the Dickens era 
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
SELECT
	firearms
,	incidents
,	ROUND((firearms *1.0 /incidents *1.0),4) *100.0 pcnt_firearms
,	inc_year
FROM
	crimes