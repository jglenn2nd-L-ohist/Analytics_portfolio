---------------------------------------------------------
-- Project: Metro Atlanta Used-Car Inventory Study
-- File name: q3d_zip_weights.sql
-- Table: zip_weights (persistent DuckDB table)
-- Business question: Q3d) What is each study zip's fixed weight,
--                    based on its share of the 2020 reconciled
--                    listing population, for use in pooling
--                    metro-wide comparisons across both periods?
-- Purpose: shared input for Q4 (age), Q5 (mileage), and Q6
--          (price) -- computed once here, joined identically by
--          all three, so pooling logic never drifts between them.
-- Author: J.Glenn
-- Date: September 2026
---------------------------------------------------------

CREATE TABLE IF NOT EXISTS zip_weights (
    cars_in_zip INTEGER,
    all_cars    INTEGER,
    weight      DOUBLE,
    dealer_zip  VARCHAR
);

INSERT INTO zip_weights
WITH breakdown AS (
    SELECT COUNT(*) AS cars_in_zip
         , (SELECT COUNT(*) FROM cars_2020_fltrd) AS all_cars
         , dealer_zip
    FROM cars_2020_fltrd
    GROUP BY dealer_zip
)
SELECT cars_in_zip
     , all_cars
     , ROUND((cars_in_zip / all_cars), 3) AS weight
     , dealer_zip
FROM breakdown;

-- verification (run manually after insert):
--   SELECT SUM(weight) FROM zip_weights;   -- expect 1.000
--   SELECT COUNT(*) FROM zip_weights;      -- expect 15 (one per study zip)