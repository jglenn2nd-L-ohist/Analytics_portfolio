--============================================================
--Project: 10_NHTSA_early_warning
--File name: q2_component_crosswalk.sql
-- Table(s): complaints, recalls
-- Tables created here: label_crosswalk, unmatched_families
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


--============================================================
-- SECTION 1: Profile component labels in both tables
--============================================================

-- Determine count of unique complaint table complaint components (compdesc -> 772)
SELECT COUNT(DISTINCT compdesc)
FROM complaints
;

-- Determine how many distinct system level complaints in complaints table (54)
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


-- Determine count of unique recall table components (compname -> 632)
SELECT COUNT(DISTINCT compname)
FROM recalls
;

-- Determine how many distinct system level components in recalls table (41)
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
        WHERE LDATE BETWEEN '20100101' AND '20261028' -- analysis window (date only, no product type filter)
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

-- First/last recall date, row count and distinct campaigns per top-level
-- recall label.
-- Result: 41 labels. Recalls use the new-style labels late and rarely
-- (ENGINE: 140 campaigns vs 641 for ENGINE AND ENGINE COOLING;
-- FUEL/PROPULSION SYSTEM: 2 campaigns). Rows overstate some labels:
-- COMMUNICATION is 17,235 rows but only 11 campaigns. Count campaigns,
-- not rows. Complaint labels in the new style must map to the old-style
-- recall labels (the crosswalk).
SELECT SPLIT_PART(compname, ':', 1) AS top_level
,   MIN(rcdate) AS oldest_entry
,   MAX(rcdate) AS latest_entry
,   COUNT(*) AS comp_num
,   COUNT(DISTINCT campno) AS campaigns
FROM recalls
GROUP BY 1
ORDER BY campaigns DESC
;


--============================================================
-- SECTION 2: Build the label-to-family crosswalk
--============================================================

-- Whitespace check on labels, run BEFORE the build. The CASE lists below
-- are typed by hand, so a label with a stray space would silently miss
-- its family (it would fall to ELSE and map to itself).
-- Lists every distinct top-level label, from either table, that differs
-- from its trimmed version.
-- Result: 'Other/I am not sure ' is the only label with any whitespace
SELECT label
,   TRIM(label) AS trimmed_label
,   LENGTH(label) - LENGTH(TRIM(label)) AS extra_chars
FROM (
    SELECT DISTINCT SPLIT_PART(compdesc, ':', 1) AS label
    FROM complaints
    UNION
    SELECT DISTINCT SPLIT_PART(compname, ':', 1) AS label
    FROM recalls
)
WHERE label <> TRIM(label)
;

-- Build crosswalk to match complaints and recalls tables by similar family groupings
-- Create table to hold the groupings
-- Result: 39 families. 31 appear on both sides, 8 are complaint-only,
-- 0 are recall-only. The EXCLUDED family holds 4 labels.
CREATE OR REPLACE TABLE label_crosswalk AS (
WITH all_labels AS (
    SELECT DISTINCT SPLIT_PART(compdesc, ':',1) AS top_level
    FROM complaints
    UNION
    SELECT DISTINCT SPLIT_PART(compname, ':',1) AS top_level
    FROM recalls
)
SELECT
    top_level AS label
,   CASE WHEN top_level IN ('ENGINE','ENGINE AND ENGINE COOLING') THEN 'ENGINE'
         WHEN top_level IN ('SERVICE BRAKES','SERVICE BRAKES, HYDRAULIC','SERVICE BRAKES, AIR','SERVICE BRAKES, ELECTRIC','SERVICE BRAKES, HYDRAULIC; AUTOHOLD BRAKE SYSTEM/BRAKE HOLD') THEN 'SERVICE BRAKES'
         WHEN top_level IN ('FUEL/PROPULSION SYSTEM','FUEL SYSTEM, GASOLINE','FUEL SYSTEM, DIESEL','FUEL SYSTEM, OTHER') THEN 'FUEL'
         WHEN top_level IN ('VISIBILITY','VISIBILITY/WIPER') THEN 'VISIBILITY'
         WHEN top_level IN ('ELECTRONIC STABILITY CONTROL (ESC)','ELECTRONIC STABILITY CONTROL') THEN 'ESC'
         WHEN top_level IN ('COMMUNICATION','COMMUNICATIONS') THEN 'COMMUNICATION'
         WHEN top_level IN ('TRAILER HITCHES','TRAILER HARDWARE') THEN 'TRAILER HITCHES'
         WHEN top_level IN ('UNKNOWN OR OTHER','OTHER','Other/Unknown','NONE') THEN 'EXCLUDED'
         ELSE top_level END AS family
FROM all_labels
);

-- Labels per family, after the build. Guards against a typo in a CASE
-- list: a mistyped label falls to ELSE and forms its own family, so the
-- merged family ends up with fewer labels than listed.
-- Result: SERVICE BRAKES 5, 4 each for FUEL as well as EXCLUDED, 
-- and 2 each for ENGINE, VISIBILITY, ESC, COMMUNICATION and
-- TRAILER HITCHES. 
SELECT family
,   COUNT(*) AS labels
FROM label_crosswalk
GROUP BY family
HAVING COUNT(*) > 1
ORDER BY labels DESC, family
;

-- Checking to confirm crosswalk condensed top_levels into the various families of complaints
-- Result: 39 families. 31 appear on both sides, 8 on the complaints side
-- only, 0 on the recalls side only.
WITH complaints_cross AS (
        SELECT DISTINCT l.family AS family
        FROM complaints c
        JOIN label_crosswalk l
        ON SPLIT_PART(c.compdesc,':',1) = l.label
        WHERE c.ldate BETWEEN '20100101' AND '20261028'
),
    recalls_cross AS (
        SELECT DISTINCT l.family AS family
        FROM recalls r
        JOIN label_crosswalk l
        ON  SPLIT_PART(r.compname,':',1) = l.label
)
SELECT cc.family AS complaints_fam
,   rc.family AS recalls_fam
FROM complaints_cross cc
FULL OUTER JOIN recalls_cross rc
ON cc.family = rc.family
;

-- Reconcile family counts to the window total. The join to the crosswalk
-- is an inner join, so complaints with a NULL label drop out silently.
-- Result: family counts sum to 1,510,983 = 1,511,009 complaints in the
-- window less 26 complaints with a NULL label. Nothing else is lost.
SELECT l.family
,   COUNT(*) AS complaints
FROM complaints c
JOIN label_crosswalk l
  ON SPLIT_PART(c.compdesc, ':', 1) = l.label
WHERE c.ldate BETWEEN '20100101' AND '20261028'
GROUP BY l.family
ORDER BY complaints DESC
;

-- Make the 26 visible: complaints in the window with no component label.
-- Result: 26 NULL label complaint, verified
SELECT COUNT(*) AS null_label_complaints
FROM complaints
WHERE compdesc IS NULL
  AND ldate BETWEEN '20100101' AND '20261028'
;


--============================================================
-- SECTION 3: Scope check - unmatched families and PROD_TYPE
--============================================================

-- Create a table to store unmatched families for further querying.
-- A family is unmatched when complaints have it and recalls do not.
-- Built from the data (no typed labels), so a stray space cannot hide a row.
-- Result: 8 families: the six child-seat labels (Chest Clip, Buckle,
-- Harness; Carry Handle, Shell, Base; Insert, Padding; Tether, Lower
-- Anchor; I suspect the car seat is counterfeit; Other/I am not sure),
-- plus FIRERELATED and ROLLOVER. These are excluded from the analysis.
CREATE OR REPLACE TABLE unmatched_families AS (
WITH recall_families AS (        -- families that exist on the recalls side
    SELECT DISTINCT l.family
    FROM recalls r
    JOIN label_crosswalk l
      ON SPLIT_PART(r.compname, ':', 1) = l.label
),
complaint_families AS (          -- families that exist on the complaints side, in window
    SELECT DISTINCT l.family
    FROM complaints c
    JOIN label_crosswalk l
      ON SPLIT_PART(c.compdesc, ':', 1) = l.label
    WHERE c.ldate BETWEEN '20100101' AND '20261028'
)
SELECT cf.family                 -- in complaints, with no match in recalls
FROM complaint_families cf
LEFT JOIN recall_families rf
  ON cf.family = rf.family
WHERE rf.family IS NULL
);

-- Question: is excluding the 8 unmatched families a clean cut, or does
-- PROD_TYPE also matter for them?
-- Result: the six child-seat labels hold 1,956 complaints: C 1,457,
-- V 466, E 31, NULL 2 (75% C, 24% V). FIRERELATED (180) and ROLLOVER (2)
-- are all V. Family-based exclusion removes 2,138 complaints (about
-- 0.14% of the window). The 182 FIRERELATED and ROLLOVER complaints are
-- the only genuine vehicle complaints lost; record this in the spec.
SELECT l.family
,   c.prod_type
,   COUNT(*) AS complaints
FROM complaints c
JOIN label_crosswalk l
  ON SPLIT_PART(c.compdesc, ':', 1) = l.label
JOIN unmatched_families u
  ON l.family = u.family
WHERE c.ldate BETWEEN '20100101' AND '20261028'
GROUP BY l.family, c.prod_type
ORDER BY l.family, complaints DESC
;

-- Question: if complaints are scoped to PROD_TYPE = 'V', which families
-- lose rows, and how many?
-- Result: 25 of the 30 matched analysis families are at least 97% V
-- (all but COMMUNICATION at 99.5% or higher), so a V filter removes
-- almost nothing there. Five are mixed: TIRES (49.6% V, 50.2% T),
-- EQUIPMENT (55.8% V, 44.0% E), CHILD SEAT (29.0% V, 70.8% C),
-- TRAILER HITCHES (85.7% V) and EQUIPMENT ADAPTIVE/MOBILITY (91.5% V).
-- A row-level V filter leaves those five as half-populations. Decide
-- the scope rule after profiling recalls by RCLTYPECD (next step).
SELECT l.family
,   c.prod_type
,   COUNT(*) AS complaints
,   ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY l.family), 1) AS pct_of_family
FROM complaints c
JOIN label_crosswalk l
  ON SPLIT_PART(c.compdesc, ':', 1) = l.label
WHERE c.ldate BETWEEN '20100101' AND '20261028'
GROUP BY l.family, c.prod_type
ORDER BY l.family, complaints DESC
;