---------------------------------------------------------
-- Project: Metro Atlanta Used-Car Inventory Study
-- File name: q3c_final_matched_dataset.sql
-- Table: cars_2026_clean, cars_2020, franchise_overrides
-- Business question: Q3c) Can current period franchise status and
--                    precise dealer location be recovered where
--                    the auto.dev data does not provide them
--                    directly? (part c: final matched dataset)
-- Purpose: join cleaned current-period data against 2020 franchise
--          records plus manual overrides, producing the population
--          used for Q4-Q6 (age, mileage, price)
-- Author: J.Glenn
-- Date: September 2026
---------------------------------------------------------

-- name matching runs BOTH directions -- 2020 name containing the
-- current name catches shortened current names (Palmer Dodge vs.
-- Palmer Dodge Chrysler Jeep Ram); current name containing the
-- 2020 name catches the reverse (a name that grew more specific
-- over time). both conditions AND the zip match must be grouped
-- in one parenthesized block -- without it, AND binds tighter than
-- OR and the zip requirement silently stops applying to two of the
-- three name conditions. confirmed this the hard way: an ungrouped
-- version inflated the match count to the full unfiltered raw
-- total (6,549) by matching generic 2020 names nationwide.

CREATE TABLE IF NOT EXISTS final_matched AS (
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
    matched AS (
        SELECT c.*, l.franchise_dealer, l.dealer_zip AS csv_matched_zip
        FROM cars_2026_clean c
        LEFT JOIN csv_lookup l
            ON (LOWER(TRIM(c.dealer)) = LOWER(TRIM(l.sp_name))
                OR l.sp_name ILIKE '%' || TRIM(c.dealer) || '%'
                OR c.dealer ILIKE '%' || TRIM(l.sp_name) || '%')
            AND LEFT(l.dealer_zip, 5) = CAST(c.searchZip AS VARCHAR)
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
-- result as of this build: 3,279 rows, 3,279 distinct VINs.
-- grew from 2,593 (11 original overrides only) to 3,279 (33 total
-- overrides, 22 added second-wave). see docs/methodology.md sec.
-- 12 for the full reasoning behind each addition.

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
matched AS (
    SELECT c.dealerId, c.dealer, c.searchZip, c.vin,
           l.franchise_dealer, l.dealer_zip AS csv_matched_zip
    FROM cars_2026_clean c
    LEFT JOIN csv_lookup l
        ON (LOWER(TRIM(c.dealer)) = LOWER(TRIM(l.sp_name))
            OR l.sp_name ILIKE '%' || TRIM(c.dealer) || '%'
            OR c.dealer ILIKE '%' || TRIM(l.sp_name) || '%')
        AND LEFT(l.dealer_zip, 5) = CAST(c.searchZip AS VARCHAR)
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