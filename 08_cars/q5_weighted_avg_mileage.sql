---------------------------------------------------------
-- Project: Metro Atlanta Used-Car Inventory Study
-- File name: q5_weighted_avg_mileage.sql
-- Table: none (single-row result, not persisted)
-- Business question: Q5) Has the weighted average mileage of
--                    franchise-dealer used inventory increased
--                    by 15,000 miles or more between September
--                    2020 and September 2026?
-- Purpose: weighted pooled mileage comparison using zip_weights
--          (Q3d). Same structure and exclusions as Q4: zip 30062
--          excluded from both periods, remaining 14 weights
--          renormalized here, zip_weights left unedited.
--          NULL mileage rows (99 in 2020, 37 in 2026) are
--          skipped by AVG(); no zero-mileage rows in either table.
-- Author: J.Glenn
-- Date: September 2026
---------------------------------------------------------

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