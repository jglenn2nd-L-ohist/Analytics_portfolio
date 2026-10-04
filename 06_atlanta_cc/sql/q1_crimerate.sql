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
-- Establish proper year bucketing methodology
WITH year_labels AS ( -- Break down 48m into years for equal comparisons
    SELECT
        *
    ,   CASE WHEN strftime('%Y/%m', ReportDate) < '2023/04' THEN 'year_1'
             WHEN strftime('%Y/%m', ReportDate) < '2024/04' THEN 'year_2'
             WHEN strftime('%Y/%m', ReportDate) < '2025/04' THEN 'year_3'
             WHEN strftime('%Y/%m', ReportDate) < '2026/04' THEN 'year_4'
             ELSE 'Out_of_range'
        END AS policy_year
    FROM acc
)
, crimes AS (  
    SELECT
        policy_year
    ,   COUNT(*) AS incidents
    ,   COUNT(CASE WHEN FireArmInvolved LIKE 'y%' THEN 1 END) AS firearms -- Only count firearm envolved cases
    FROM year_labels
    GROUP BY policy_year
)
SELECT
    policy_year
,   incidents
,   firearms
,   ROUND(firearms * 100.0 / incidents, 2) AS pcnt_firearms
FROM crimes
ORDER BY policy_year
;
