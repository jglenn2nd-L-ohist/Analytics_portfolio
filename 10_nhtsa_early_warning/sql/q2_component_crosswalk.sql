--============================================================
--Project: 10_NHTSA_early_warning 
--File name: q2_component_crosswalk.sql
-- Table(s): complaints, recalls
-- Business question: Can complaint components be mapped to 
--                    recall components at a defensible 
--                    level (the crosswalk)?
--Purpose: Determine continuity between naming structures of 
--         complaints and recalls tables. Then build a cross-
--         walk so naming conventions capture the same data
--         from both tables
--Author: J.Glenn
-- Date: November 2026
--============================================================

-- Determine count of unique complaint table complaint components (compdesc -> 772)
SELECT COUNT(DISTINCT compdesc)
FROM complaints
;

-- Determine how many distinct system level ccompalints in complaints table (54)
WITH levels_c AS (
        SELECT compdesc
        ,       SPLIT_PART(compdesc, ':', 1) AS top_level
        ,       SPLIT_PART(compdesc, ':', 2) AS second_level
        ,       SPLIT_PART(compdesc, ':', 3) AS third_level                                                                    
        ,       SPLIT_PART(compdesc, ':', 4) AS fourth_level                                                                   
        FROM complaints
)
SELECT COUNT(DISTINCT top_level) AS by_system
FROM levels_c 
    ;


-- Determine count of unique recall table complaint components (compname -> 632)
SELECT COUNT(DISTINCT compname)
FROM recalls
;

-- Determine how many distinct system level complaints in recalls table (41)
WITH levels_r AS (
        SELECT compname
        ,       SPLIT_PART(compname, ':', 1) AS top_level
        ,       SPLIT_PART(compname, ':', 2) AS second_level
        ,       SPLIT_PART(compname, ':', 3) AS third_level                                                                    
        ,       SPLIT_PART(compname, ':', 4) AS fourth_level                                                                   
        FROM recalls
)
SELECT COUNT(DISTINCT top_level) AS by_system
FROM levels_r
;


-- Determine commonality between tables
WITH recalls_agg AS (    -- aggregate recalls to top level complaint and counts
        SELECT SPLIT_PART(compname, ':', 1) AS top_level
        ,      count(*) AS top_level_count                                                               
        FROM recalls
        GROUP BY top_level
    )
,   complaints_agg AS (    -- aggregate complaints to top level complaint and counts
        SELECT SPLIT_PART(compdesc, ':', 1) AS top_level
        ,      count(*) AS top_level_count                                                               
        FROM complaints
        WHERE LDATE BETWEEN '20100101' AND '20261028' -- Accounting for only vehicles in the spec time window
        GROUP BY top_level
    )
SELECT
    COALESCE(ca.top_level, ra.top_level) AS top_level 
,   ca.top_level_count AS complaints_rows
,   ra.top_level_count AS recalls_rows
FROM complaints_agg ca 
FULL OUTER JOIN recalls_agg ra 
ON ca.top_level = ra.top_level
ORDER BY  ca.top_level_count DESC
;

-- determine when ENGINE and ENGINE AND ENGINE COOLING label switchover took place in complaints table (complaints, by year - Switchover happened in 2012; from 2013 ENGINE is dominant description) 
SELECT SPLIT_PART(compdesc, ':', 1) AS top_level  
,   count(*) AS total
,   LEFT(ldate, 4) AS reg_date  
FROM complaints
WHERE SPLIT_PART(compdesc, ':', 1) IN ('ENGINE', 'ENGINE AND ENGINE COOLING') AND (ldate BETWEEN '20100101' AND '20261028')
GROUP BY reg_date 
,   top_level
ORDER BY reg_date
;

-- Look into second level to determine if ENGINE & ENGINE AND ENGINE COOLING can be treated as 1 unit for analysis (ENGINE became the overarching catch-all)
SELECT SUM(CASE WHEN ldate BETWEEN '20100101' AND '20111231' THEN 1 ELSE 0 END) AS pre_switchover
,   SUM(CASE WHEN ldate BETWEEN '20120101' AND '20261028' THEN 1 ELSE 0 END) AS post_switch
,   SPLIT_PART(compdesc, ':',1) AS top_level
,   SPLIT_PART(compdesc, ':', 2) AS second_level
FROM complaints
WHERE SPLIT_PART(compdesc, ':', 1) IN ('ENGINE', 'ENGINE AND ENGINE COOLING') AND (ldate BETWEEN '20100101' AND '20261028')
GROUP BY SPLIT_PART(compdesc, ':', 1)
,   SPLIT_PART(compdesc, ':', 2)
;

-- ENGINE vs ENGINE AND ENGINE COOLING in recalls, by year (rows and
-- distinct campaigns).
-- Result: recalls kept the old label; ENGINE stays the minority.
-- 2022 spike (1,561 rows) is only 51 campaigns: a row artifact, so
-- count campaigns, not rows.
SELECT SPLIT_PART(compname, ':', 1) AS top_level  
,   COUNT(*) AS total
,   LEFT(rcdate, 4) AS reg_date
,   COUNT(DISTINCT campno) AS campaigns 
FROM recalls
WHERE SPLIT_PART(compname, ':', 1) IN ('ENGINE', 'ENGINE AND ENGINE COOLING')
GROUP BY LEFT(rcdate, 4)
,    top_level
ORDER BY 3
;

-- First/last date per top-level complaint label, analysis window.
-- Result: new-style labels start Sep 2011 - mid 2012 (SERVICE BRAKES
-- 2011-09-19, VISIBILITY/WIPER 2012-01-26, FUEL/PROPULSION SYSTEM
-- 2012-05-11); old-style siblings run to 2026. FORWARD COLLISION
-- AVOIDANCE (2014-08) and LANE DEPARTURE (2015-06) are new
-- categories, not renames.
SELECT SPLIT_PART(compdesc, ':', 1) AS top_level  
,   count(*) AS total
,   MIN(ldate) AS oldest_entry
,   MAX(ldate) AS latest_entry 
FROM complaints
WHERE ldate BETWEEN '20100101' AND '20261028'
GROUP BY top_level
ORDER BY total DESC
;

-- Total complaints per year, 2010-2014. Checks whether the 2013 engine
-- step-up is a change across all complaints or local to engine.
-- Result: totals fell ~30% 2010-2012, then rose 28% (2013) and 54% (2014);
-- engine share rose 7.9% -> 13.5%. Partly global, so spike thresholds
-- (spec section 6) must allow for overall volume swings.
SELECT LEFT(ldate, 4) AS comp_yr
,   COUNT(*) AS comp_num
FROM complaints
WHERE ldate BETWEEN '20100101' AND '20141231'
GROUP BY 1
ORDER BY 1
;