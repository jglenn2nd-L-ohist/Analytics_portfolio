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
-- Determine homicide count over the years
WITH year_labels AS ( -- Break down 48m into years for equal comparisons
    SELECT
        *
    ,   CASE WHEN strftime('%Y/%m', ReportDate) < '2023/04' THEN '2022-2023'
             WHEN strftime('%Y/%m', ReportDate) < '2024/04' THEN '2023-2024'
             WHEN strftime('%Y/%m', ReportDate) < '2025/04' THEN '2024-2025'
             WHEN strftime('%Y/%m', ReportDate) < '2026/04' THEN '2025-2026'
             ELSE 'Out_of_range'
        END AS policy_year
    FROM acc
)
SELECT
	COUNT(*) AS homicides
, 	policy_year

FROM
	year_labels
WHERE
FireArmInvolved LIKE 'y%' AND
NibrsUcrCode = '09A' -- 09a is the code for Murder in the NIBRS_Offense 
GROUP BY
	policy_year
;