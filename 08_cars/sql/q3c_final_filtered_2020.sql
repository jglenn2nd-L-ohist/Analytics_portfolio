---------------------------------------------------------
-- Project: Metro Atlanta Used-Car Inventory Study
-- File name: q3c_final_filtered_2020.sql
-- Table: cars_2020_fltrd (persistent DuckDB table)
-- Business question: Q3c) Build the final reconciled 2020 study
--                    population -- franchise, used-only, 15-zip --
--                    applying the overrides from
--                    q3a_franchise_overrides_2020.sql.
-- Purpose: produce the 2020-side equivalent of final_matched, so
--          the two periods can be compared on a like-for-like,
--          reconciled population.
-- Author: J.Glenn
-- Date: September 2026
---------------------------------------------------------

CREATE TABLE IF NOT EXISTS cars_2020_fltrd (
    sp_name           VARCHAR,
    dealer_zip        VARCHAR,
    city              VARCHAR,
    VIN               VARCHAR,
    mod_year          INTEGER,
    make_name         VARCHAR,
    model_name        VARCHAR,
    is_new            BOOLEAN,
    mileage           DOUBLE,
    price             DOUBLE
);

INSERT INTO cars_2020_fltrd
SELECT COALESCE(o2.dealer_name, c2.sp_name) AS sp_name
     , c2.dealer_zip
     , c2.city
     , c2.VIN
     , c2.year AS mod_year
     , c2.make_name
     , c2.model_name
     , c2.is_new
     , c2.mileage
     , c2.price

FROM cars_2020 c2
LEFT JOIN overrides_2020 o2 ON c2.sp_name = o2.sp_name
WHERE c2.franchise_dealer = true
  AND c2.is_new = false
  AND LEFT(c2.dealer_zip, 5) IN ('30096','30291','30519','30518','30144',
      '30060','30067','30062','30009','30013','30012','30094','30260',
      '30341','30339')
  AND COALESCE(o2.franchise, true) = true
;

-- verification (run manually after insert):
--   SELECT COUNT(*) FROM cars_2020_fltrd;                              -- expect 8,722
--   SELECT COUNT(DISTINCT VIN) FROM cars_2020_fltrd;                   -- expect 8,722 (no dupes)
--   SELECT COUNT(*) FROM cars_2020_fltrd WHERE sp_name ILIKE 'Southern Star%'; -- expect 0
