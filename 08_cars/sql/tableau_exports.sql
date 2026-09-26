---------------------------------------------------------
-- Project: Metro Atlanta Used-Car Inventory Study
-- File name: tableau_exports.sql
-- Table: none (writes three CSV files to deliverables/)
-- Business question: none (presentation layer for Q4-Q6)
-- Purpose: export the data behind the Tableau dashboard. All
--          calculations stay in SQL and Python. Tableau only
--          displays these files.
--            summary.csv      point estimates, 95% CIs, thresholds
--            zip_changes.csv  per-zip averages and changes
--            q6_history.csv   how the Q6 headline moved during
--                             the audit
-- Author: J.Glenn
-- Date: September 2026
---------------------------------------------------------
--
-- summary.csv is hardcoded from verified results: point
-- estimates from q4, q5, and q6 (Part 1 and Part 2), intervals
-- and shares from python/q4_q6_bootstrap.py. If any upstream
-- table changes, rerun those scripts and update these values.
--
-- Units: for Age, difference, ci_low, ci_high, and threshold are
-- in months, while value_2020 and value_2026 are in years. The
-- _pct columns express each metric as a share of its threshold,
-- so all three can share one axis (1.0 = threshold met).
--
-- Paths are absolute so the CLI can be opened from any folder.
-- The deliverables folder must exist before these run.


-- =====================================================
-- 1. summary.csv
-- =====================================================

COPY (
    SELECT *
         , difference / threshold  AS pct_of_threshold
         , ci_low     / threshold  AS ci_low_pct
         , ci_high    / threshold  AS ci_high_pct
    FROM (VALUES
        ('Age',        'Pre-registered', 2.66,  3.10,  5.31,  1.0,    10.1,  18,    'months',  1.000)
      , ('Age',        'Same dealer',    2.83,  3.41,  7.03,  2.7,    25.9,  18,    'months',  0.752)
      , ('Mileage',    'Pre-registered', 41594, 47477, 5883,  1637,   11620, 15000, 'miles',   0.997)
      , ('Mileage',    'Same dealer',    47171, 50922, 3751,  625,    23990, 15000, 'miles',   0.750)
      , ('Real price', 'Pre-registered', 34927, 37448, 2521,  -2318,  12059, 2000,  'dollars', 0.420)
      , ('Real price', 'Same dealer',    29972, 32439, 2467,  -3479,  4260,  2000,  'dollars', 0.634)
    ) AS t(metric, comparison, value_2020, value_2026, difference, ci_low, ci_high,
           threshold, unit, share_below_threshold)
) TO 'C:/Users/jglen/Analytics_portfolio/08_cars/deliverables/summary.csv' (HEADER);


-- =====================================================
-- 2. zip_changes.csv
-- =====================================================
-- Same rules as q4-q6 Part 1: 30062 excluded, CPI-adjusted 2020
-- prices, $1,000 price floor applied to price only. Dealer counts
-- are for the map tooltip, so a viewer can tell a solid zip from
-- a thin one.
--
-- Check before exporting: SUM(weight * each change column) should
-- reproduce the metro results (about 5.31 months, 5,883 miles,
-- $2,521), within rounding.

COPY (
WITH cpi AS (
    SELECT 259.918 AS aug20, 334.980 AS aug26, aug26 / aug20 AS ratio
)
, adj_weights AS (
    SELECT dealer_zip AS zip
         , cars_in_zip / (SELECT SUM(cars_in_zip)
                          FROM zip_weights
                          WHERE dealer_zip <> '30062') AS weight
    FROM zip_weights
    WHERE dealer_zip <> '30062'
)
, z20 AS (
    SELECT f.dealer_zip                                               AS zip
         , AVG(2020 - CAST(f.mod_year AS DOUBLE))                     AS age_2020
         , AVG(f.mileage)                                             AS mileage_2020
         , AVG(CASE WHEN f.price >= 1000 THEN c.ratio * f.price END)  AS price_2020
         , COUNT(*)                                                   AS listings_2020
         , COUNT(DISTINCT f.sp_name)                                  AS dealers_2020
    FROM cars_2020_fltrd f
    CROSS JOIN cpi c
    WHERE f.dealer_zip <> '30062'
    GROUP BY f.dealer_zip
)
, z26 AS (
    SELECT final_zip                                      AS zip
         , AVG(2026 - CAST(year AS DOUBLE))               AS age_2026
         , AVG(miles)                                     AS mileage_2026
         , AVG(CASE WHEN price >= 1000 THEN price END)    AS price_2026
         , COUNT(*)                                       AS listings_2026
         , COUNT(DISTINCT dealerId)                       AS dealers_2026
    FROM final_matched
    GROUP BY final_zip
)
SELECT a.zip
     , CASE a.zip
           WHEN '30096' THEN 'Duluth'     WHEN '30291' THEN 'Union City'
           WHEN '30519' THEN 'Buford'     WHEN '30518' THEN 'Buford'
           WHEN '30144' THEN 'Kennesaw'   WHEN '30060' THEN 'Marietta'
           WHEN '30067' THEN 'Marietta'   WHEN '30009' THEN 'Alpharetta'
           WHEN '30013' THEN 'Conyers'    WHEN '30012' THEN 'Conyers'
           WHEN '30094' THEN 'Conyers'    WHEN '30341' THEN 'Chamblee'
           WHEN '30339' THEN 'Vinings'    WHEN '30260' THEN 'Morrow'
       END                                                  AS display_city
     , a.weight
     , ROUND(z20.age_2020, 2)                               AS age_2020
     , ROUND(z26.age_2026, 2)                               AS age_2026
     , ROUND((z26.age_2026 - z20.age_2020) * 12, 2)         AS age_change_months
     , ROUND(z20.mileage_2020, 0)                           AS mileage_2020
     , ROUND(z26.mileage_2026, 0)                           AS mileage_2026
     , ROUND(z26.mileage_2026 - z20.mileage_2020, 0)        AS mileage_change
     , ROUND(z20.price_2020, 0)                             AS price_2020
     , ROUND(z26.price_2026, 0)                             AS price_2026
     , ROUND(z26.price_2026 - z20.price_2020, 0)            AS price_change
     , z20.listings_2020, z26.listings_2026
     , z20.dealers_2020,  z26.dealers_2026
FROM adj_weights a
JOIN z20 ON a.zip = z20.zip
JOIN z26 ON a.zip = z26.zip
ORDER BY a.zip
) TO 'C:/Users/jglen/Analytics_portfolio/08_cars/deliverables/zip_changes.csv' (HEADER);


-- =====================================================
-- 3. q6_history.csv
-- =====================================================
-- The pre-registered Q6 result at each stage of the audit (see
-- docs/methodology.md sec. 15).

COPY (
    SELECT * FROM (VALUES
        (1, 'Initial build',                    5624)
      , (2, 'Radius-overspill dealers removed', 2570)
      , (3, 'EchoPark added (final)',           2521)
    ) AS t(step, stage, real_price_change)
) TO 'C:/Users/jglen/Analytics_portfolio/08_cars/deliverables/q6_history.csv' (HEADER);