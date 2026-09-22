---------------------------------------------------------
-- Project: Metro Atlanta Used-Car Inventory Study
-- File name: q2_franchise_flag_reliability_2020.sql
-- Table: cars_2020 (persistent DuckDB table, used_cars_data.csv)
-- Business question: Q2) Does the September 2020 franchise_dealer
--                    flag reliably identify true franchise
--                    dealers across the full 15-zip study set,
--                    and where does it fail?
-- Purpose: spot-check the flag against real-world knowledge,
--          since no automated test can catch a mislabeled value
-- Author: J.Glenn
-- Date: September 2026
---------------------------------------------------------

-- list every dealer flagged as franchise across all 15 study zips
-- at once, for a full manual review (not per-zip, since the set
-- is small enough to review in one pass).
SELECT DISTINCT sp_name
FROM cars_2020
WHERE franchise_dealer = true
  AND LEFT(dealer_zip, 5) IN ('30096','30291','30519','30518','30144',
      '30060','30067','30062','30009','30013','30012','30094','30260',
      '30341','30339');

-- findings (91 distinct dealers reviewed):
--   "Southern Star Automotive" -- flagged true, confirmed NOT a
--   franchise. real error in the source data. overridden in
--   q3a_franchise_overrides_2020.sql.
--
--   "Courtesy Ford" / "Courtesy Ford Conyers" / "Courtesy Ford
--   Mitsubishi" -- three name variants for one physical dealer,
--   confirmed via matching dealer_zip. not a flag error, but a
--   naming duplication that would triple-count one dealer's
--   listings if left as-is. collapsed to one canonical name in
--   q3a_franchise_overrides_2020.sql.

-- conclusion: flag is not perfect. two issues found across 91
-- dealers reviewed (1 mislabel, 1 three-way name duplication) --
-- low rate, not systemic, but both material enough to require
-- correction before building cars_2020_fltrd. 
