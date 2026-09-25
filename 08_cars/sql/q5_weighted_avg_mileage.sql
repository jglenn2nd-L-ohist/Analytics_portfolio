---------------------------------------------------------
-- Project: Metro Atlanta Used-Car Inventory Study
-- File name: q5_weighted_avg_mileage.sql
-- Table: none (single-row results, not persisted)
-- Business question: Q5) Has the weighted average mileage of
--                    franchise-dealer used inventory increased
--                    by 15,000 miles or more between September
--                    2020 and September 2026?
-- Purpose: weighted pooled mileage comparison using zip_weights
--          (Q3d). Same structure and exclusions as Q4: zip 30062
--          excluded from both periods, remaining 14 weights
--          renormalized here, zip_weights left unedited.
--          NULL mileage rows (99 in 2020, 29 in 2026) are
--          skipped by AVG(). no zero-mileage rows in either table.
--          Part 1 is the pre-registered test. Part 2 repeats it
--          on dealers present in both periods.
-- Author: J.Glenn
-- Date: September 2026
---------------------------------------------------------


-- =====================================================
-- PART 1: PRE-REGISTERED TEST (all franchise dealers)
-- =====================================================

WITH adj_weights AS (
    SELECT dealer_zip
         , cars_in_zip / (SELECT SUM(cars_in_zip)
                          FROM zip_weights
                          WHERE dealer_zip <> '30062') AS weight
    FROM zip_weights
    WHERE dealer_zip <> '30062'
)
, zip_miles_2026 AS (
    SELECT final_zip
         , AVG(miles) AS av_miles_26
    FROM final_matched
    GROUP BY final_zip
)
, zip_miles_2020 AS (
    SELECT dealer_zip
         , AVG(mileage) AS av_miles_20
    FROM cars_2020_fltrd
    WHERE dealer_zip <> '30062'
    GROUP BY dealer_zip
)
SELECT ROUND(SUM(a.weight * z20.av_miles_20), 0) AS miles_20
     , ROUND(SUM(a.weight * z26.av_miles_26), 0) AS miles_26
     , ROUND((SUM(a.weight * z26.av_miles_26)
            - SUM(a.weight * z20.av_miles_20)), 0) AS miles_variation
FROM adj_weights a
JOIN zip_miles_2020 z20
  ON a.dealer_zip = z20.dealer_zip
JOIN zip_miles_2026 z26
  ON a.dealer_zip = z26.final_zip;


-- =====================================================
-- PART 2: SAME-DEALER SENSITIVITY RUN
-- =====================================================
-- The 2026 sample covers only part of the franchise market.
-- Dealers holding nearly half of the 2020 listings are absent from
-- the 2026 pull (the 25-call-per-zip cap), and the 2026 side
-- includes stores with no 2020 counterpart in the data (true
-- market entries, and stores operating in 2020 but missing from
-- the 2020 data). The dealer mix therefore differs between periods
-- on BOTH sides. This run restricts BOTH periods to dealers
-- observed in both snapshots, so the comparison is like for like.
--
-- Continuing dealers:
--   2026 side: csv_match = true (matched 2020 data automatically,
--     carried in final_matched from q3c) plus the 10 override
--     dealers with a confirmed 2020 counterpart in a study zip.
--   2020 side: listings that match a 2026 csv_match dealer by the
--     same name-and-zip rule q3c uses (EXISTS), plus the 2020
--     names of those 10 override dealers. ALM GMC South and ALM
--     Mazda South were Hennessy Buick GMC Mazda (and Hennessy
--     Mazda) in 2020, confirmed by direct knowledge.
--
-- A 2020 dealer with no 2026 counterpart may have closed or may
-- simply not have been sampled. The data cannot tell which, and
-- this run does not need to: it keeps only dealers seen in both.
--
-- Weights are unchanged from Part 1. The zips column must read 14:
-- both sides are joined, so 14 confirms every zip has continuing
-- dealers in both periods.

WITH adj_weights AS (
    SELECT dealer_zip
         , cars_in_zip / (SELECT SUM(cars_in_zip)
                          FROM zip_weights
                          WHERE dealer_zip <> '30062') AS weight
    FROM zip_weights
    WHERE dealer_zip <> '30062'
)
, zip_miles_2026 AS (
    SELECT final_zip
         , AVG(miles) AS av_miles_26
    FROM final_matched
    WHERE ( csv_match = true
         OR dealerId IN (
              'd_da2c46d7beb1242f'  -- Global BMW
            , 'd_7bfda8a27828c52d'  -- John Miles
            , 'd_aa3c808ad5776409'  -- Group 1 Ford
            , 'd_f17a38eafcf9f604'  -- Premier Nissan
            , 'd_bea2c7500677d115'  -- Malcolm Cunningham
            , 'd_1bd625e0ea7fbcf7'  -- ALM Ford Marietta
            , 'd_a3ea3d7d17558de2'  -- Kia South Atlanta
            , 'd_e83b59ee37c7f8b8'  -- ALM GMC South
            , 'd_374d7b0ecf59000e'  -- Heritage Cadillac/Mitsubishi
            , 'd_3d857696dd81781d'  -- ALM Mazda South
         ) )
    GROUP BY final_zip
)
, zip_miles_2020 AS (
    SELECT f.dealer_zip
         , AVG(f.mileage) AS av_miles_20
    FROM cars_2020_fltrd f
    WHERE f.dealer_zip <> '30062'
      AND (
            -- matched automatically to a 2026 continuing dealer
            EXISTS (
                SELECT 1
                FROM final_matched m
                WHERE m.csv_match = true
                  AND m.final_zip = f.dealer_zip
                  AND ( LOWER(TRIM(m.dealer)) = LOWER(TRIM(f.sp_name))
                     OR f.sp_name ILIKE '%' || TRIM(m.dealer) || '%'
                     OR m.dealer ILIKE '%' || TRIM(f.sp_name) || '%' )
            )
            -- 2020 names of the 10 override continuing dealers
         OR f.sp_name IN (
              'Global Imports BMW'                          -- Global BMW
            , 'John Miles Chevrolet Buick GMC'              -- John Miles
            , 'Jim Tidwell Ford'                            -- Group 1 Ford
            , 'Sutherlin Nissan Mall of Georgia'            -- Premier Nissan
            , 'Malcolm Cunningham Chevrolet North Point'    -- Malcolm Cunningham
            , 'AutoNation Ford Marietta'                    -- ALM Ford Marietta
            , 'Kia Atlanta South'                           -- Kia South Atlanta
            , 'Heritage Cadillac Mitsubishi'                -- Heritage
            , 'Hennessy Buick GMC Mazda'                    -- ALM GMC and ALM Mazda South
            , 'Hennessy Mazda'                              -- ALM Mazda South
         )
      )
    GROUP BY f.dealer_zip
)
SELECT ROUND(SUM(a.weight * z20.av_miles_20), 0) AS miles_20
     , ROUND(SUM(a.weight * z26.av_miles_26), 0) AS miles_26
     , ROUND((SUM(a.weight * z26.av_miles_26)
            - SUM(a.weight * z20.av_miles_20)), 0) AS miles_variation
     , COUNT(*) AS zips
FROM adj_weights a
JOIN zip_miles_2020 z20
  ON a.dealer_zip = z20.dealer_zip
JOIN zip_miles_2026 z26
  ON a.dealer_zip = z26.final_zip;