---------------------------------------------------------
-- Project: Metro Atlanta Used-Car Inventory Study
-- File name: q3c_final_matched_dataset.sql
-- Table: final_matched (persistent DuckDB table)
-- Business question: Q3c) Can current period franchise status and
--                    precise dealer location be recovered where
--                    the auto.dev data does not provide them
--                    directly? (part c: final matched dataset)
-- Purpose: franchise match against 2020 data plus the manual
--          overrides in q3a, zip-membership filter, outputs
--          final_matched
-- Author: J.Glenn
-- Date: September 2026
---------------------------------------------------------

-- the 2020 match uses EXISTS, not a JOIN. the question is only
-- "does this 2026 listing have at least one matching 2020
-- franchise record?" a JOIN returns one row per match, so a dealer
-- with several 2020 name variants (Courtesy Ford has three) would
-- repeat every listing once per variant. EXISTS answers yes or no
-- and cannot multiply rows.
--
-- EXISTS is computed in its own CTE (flagged) because DuckDB does
-- not allow a later column in the same SELECT to reference an
-- alias whose expression contains a subquery.

CREATE OR REPLACE TABLE final_matched AS (
    WITH csv_lookup AS (
        SELECT DISTINCT sp_name, dealer_zip, franchise_dealer
        FROM cars_2020
        WHERE LEFT(dealer_zip, 5) IN (
            '30096','30291','30519','30518','30144','30060','30067','30062',
            '30009','30013','30012','30094','30260','30341','30339'
        )
        AND franchise_dealer = true
        AND is_new = false
    ),
    flagged AS (
        SELECT c.*
             , EXISTS (
                   SELECT 1
                   FROM csv_lookup l
                   WHERE ( LOWER(TRIM(c.dealer)) = LOWER(TRIM(l.sp_name))
                        OR l.sp_name ILIKE '%' || TRIM(c.dealer) || '%'
                        OR c.dealer ILIKE '%' || TRIM(l.sp_name) || '%' )
                     AND LEFT(l.dealer_zip, 5) = CAST(c.searchZip AS VARCHAR)
               ) AS csv_match
        FROM cars_2026_clean c
    ),
    matched AS (
        SELECT f.*
             , CASE WHEN f.csv_match THEN true END AS franchise_dealer
             , CASE WHEN f.csv_match THEN CAST(f.searchZip AS VARCHAR) END AS csv_matched_zip
        FROM flagged f
    )
    SELECT m.*,
        COALESCE(o.is_franchise, m.franchise_dealer) AS final_franchise_flag,
        COALESCE(o.confirmed_zip, m.csv_matched_zip, CAST(m.searchZip AS VARCHAR)) AS final_zip
    FROM matched m
    LEFT JOIN franchise_overrides o ON m.dealerId = o.dealerId
    WHERE COALESCE(o.is_franchise, m.franchise_dealer) = true
      AND COALESCE(o.confirmed_zip, m.csv_matched_zip, CAST(m.searchZip AS VARCHAR)) IN (
          '30096','30291','30519','30518','30144','30060','30067','30062',
          '30009','30013','30012','30094','30260','30341','30339'
      )
);

-- verify: should be one row per VIN, no fan-out
SELECT COUNT(*), COUNT(DISTINCT vin) FROM final_matched;
-- verified: 3,041 rows, 3,041 distinct VINs. history: 2,593
-- (original overrides only), then 3,279 (33 overrides after
-- second-wave recovery), then 3,024 after five radius-overspill
-- dealers were removed from q3a (28 overrides) and the 2020 match
-- was changed from a JOIN to EXISTS (the JOIN version had produced
-- 114 duplicate Courtesy Ford rows), then 3,041 after EchoPark was
-- added (29 overrides). see docs/methodology.md sec. 12.

-- CHECKPOINT: full disposition breakdown, useful any time this
-- count needs re-auditing. classifies every current-period row
-- into an exhaustive, non-overlapping reason category rather than
-- testing one hypothesis at a time -- this is the method that
-- actually found the second-wave gap, not a single-shot guess.
WITH csv_lookup AS (
    SELECT DISTINCT sp_name, dealer_zip, franchise_dealer
    FROM cars_2020
    WHERE LEFT(dealer_zip, 5) IN (
        '30096','30291','30519','30518','30144','30060','30067','30062',
        '30009','30013','30012','30094','30260','30341','30339'
    )
    AND franchise_dealer = true AND is_new = false
),
flagged AS (
    SELECT c.*
         , EXISTS (
               SELECT 1
               FROM csv_lookup l
               WHERE ( LOWER(TRIM(c.dealer)) = LOWER(TRIM(l.sp_name))
                    OR l.sp_name ILIKE '%' || TRIM(c.dealer) || '%'
                    OR c.dealer ILIKE '%' || TRIM(l.sp_name) || '%' )
                 AND LEFT(l.dealer_zip, 5) = CAST(c.searchZip AS VARCHAR)
           ) AS csv_match
    FROM cars_2026_clean c
),
matched AS (
    SELECT f.*
         , CASE WHEN f.csv_match THEN true END AS franchise_dealer
         , CASE WHEN f.csv_match THEN CAST(f.searchZip AS VARCHAR) END AS csv_matched_zip
    FROM flagged f
),
tagged AS (
    SELECT m.*, o.dealerId AS override_id, o.is_franchise, o.confirmed_zip,
        CASE
            WHEN m.franchise_dealer IS NULL AND o.dealerId IS NULL THEN '1_no_match_no_override'
            WHEN m.franchise_dealer IS NULL AND o.dealerId IS NOT NULL AND o.is_franchise = true THEN '2_rescued_by_override'
            WHEN m.franchise_dealer IS NULL AND o.dealerId IS NOT NULL AND o.is_franchise != true THEN '3_override_confirms_not_franchise'
            WHEN m.franchise_dealer = true THEN '4_matched_confirmed_franchise'
            WHEN m.franchise_dealer = false THEN '5_matched_but_not_franchise_at_all'
        END AS disposition
    FROM matched m
    LEFT JOIN franchise_overrides o ON m.dealerId = o.dealerId
)
SELECT disposition, COUNT(*) AS row_count, COUNT(DISTINCT dealer) AS distinct_dealers
FROM tagged
GROUP BY disposition
ORDER BY disposition;