---------------------------------------------------------
-- Project: Metro Atlanta Used-Car Inventory Study
-- File name: q4_weighted_avg_age.sql
-- Table: none (single-row result, not persisted)
-- Business question: Q4) Has the weighted average age of
--                    franchise-dealer used inventory increased
--                    by 18 months or more between September 2020
--                    and September 2026?
-- Purpose: weighted pooled age comparison using zip_weights
--          (Q3d). Zip 30062 excluded from both periods; its only
--          2020 franchise dealer relocated to 30060 by 2026.
--          Remaining 14 weights renormalized here, zip_weights
--          left unedited.
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
, zip_age_2026 AS (
    SELECT final_zip
         , 2026 - AVG(year) AS av_age_2026
    FROM final_matched
    GROUP BY final_zip
)
, zip_age_2020 AS (
    SELECT dealer_zip
         , 2020 - AVG(CAST(mod_year AS DOUBLE)) AS av_age_2020
    FROM cars_2020_fltrd
    WHERE dealer_zip <> '30062'
    GROUP BY dealer_zip
)
SELECT ROUND(SUM(a.weight * z20.av_age_2020), 2) AS age_2020
     , ROUND(SUM(a.weight * z26.av_age_2026), 2) AS age_2026
     , ROUND((SUM(a.weight * z26.av_age_2026)
            - SUM(a.weight * z20.av_age_2020)) * 12, 2) AS age_difference_months
FROM adj_weights a
JOIN zip_age_2020 z20
  ON a.dealer_zip = z20.dealer_zip
JOIN zip_age_2026 z26
  ON a.dealer_zip = z26.final_zip;