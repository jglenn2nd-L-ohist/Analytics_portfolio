---------------------------------------------------------
-- Project: Metro Atlanta Used-Car Inventory Study
-- File name: q3b_current_period_cleaning.sql
-- Table: cars_2026, franchise_overrides
-- Business question: Q3b) Can current period franchise status and
--                    precise dealer location be recovered where
--                    the auto.dev data does not provide them
--                    directly? (part b: current-period cleaning)
-- Purpose: resolve NULL scraped zip and cross-zip VIN duplication,
--          output one clean row per VIN
-- Author: J.Glenn
-- Date: September 2026
---------------------------------------------------------

-- DIAGNOSTIC 1: NULL zip check
SELECT COUNT(*) AS total, COUNT(zip) AS has_real_zip FROM cars_2026;
-- resolution: zip is unreliable, use searchZip as the geography
-- field throughout. see 00_schema_reference.sql.

-- DIAGNOSTIC 2: cross-zip VIN duplication (radius overlap)
SELECT vin, COUNT(DISTINCT searchZip) AS zip_appearances, COUNT(*) AS total_rows
FROM cars_2026
GROUP BY vin
HAVING COUNT(DISTINCT searchZip) > 1
ORDER BY zip_appearances DESC;
-- result: 49 VINs affected, capped at 2 zip appearances each, except
-- Nalley Lexus Smyrna (3 zips: 30339, 30291, 30009) -- the case that
-- triggered the independent address lookup confirming its real zip
-- (30080) is outside the study area. see q3a.

-- RESOLUTION: one row per VIN. priority: keep the row whose
-- searchZip matches that dealer's confirmed_zip from
-- franchise_overrides where one exists; otherwise keep the row at
-- the dealer's own most frequent searchZip; final tiebreak is
-- searchZip itself, arbitrary but deterministic.
CREATE TABLE IF NOT EXISTS cars_2026_clean AS (
    WITH dominant_zip AS (
        SELECT dealerId, searchZip,
            ROW_NUMBER() OVER (
                PARTITION BY dealerId ORDER BY COUNT(*) DESC
            ) AS rn
        FROM cars_2026
        GROUP BY dealerId, searchZip
    ),
    ranked AS (
        SELECT c.*,
            ROW_NUMBER() OVER (
                PARTITION BY c.vin
                ORDER BY
                    CASE WHEN o.confirmed_zip IS NOT NULL
                              AND CAST(c.searchZip AS VARCHAR) = o.confirmed_zip
                         THEN 0 ELSE 1 END,
                    CASE WHEN d.searchZip = c.searchZip AND d.rn = 1
                         THEN 0 ELSE 1 END,
                    c.searchZip
            ) AS keep_rank
        FROM cars_2026 c
        LEFT JOIN franchise_overrides o ON c.dealerId = o.dealerId
        LEFT JOIN dominant_zip d ON c.dealerId = d.dealerId AND d.rn = 1
    )
    SELECT * EXCLUDE (keep_rank) FROM ranked WHERE keep_rank = 1
);

-- verify: should be one row per VIN
SELECT COUNT(*), COUNT(DISTINCT vin) FROM cars_2026_clean;