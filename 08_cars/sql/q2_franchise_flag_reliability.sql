---------------------------------------------------------
-- Project: Metro Atlanta Used-Car Inventory Study
-- File name: q2_franchise_flag_reliability.sql
-- Table: used_cars_data.csv (2020)
-- Business question: Q2) Does the September 2020 franchise_dealer
--                    flag reliably identify true franchise
--                    dealers, and where does it fail?
-- Purpose: spot-check the flag against real-world knowledge,
--          since no automated test can catch a mislabeled value
-- Author: J.Glenn
-- Date: September 2026
---------------------------------------------------------

-- list every dealer a given zip's data claims is a franchise.
-- run per zip, spot-check names against known local dealers.
SELECT DISTINCT sp_name
FROM 'C:/Users/jglen/Analytics_portfolio/08_cars/data/used_cars_data.csv'
WHERE franchise_dealer = true AND dealer_zip = '30096';

-- findings (30096 / Duluth):
--   "Southern Star Automotive" -- flagged true, confirmed NOT a
--   franchise. real error in the source data. overridden in
--   q3a_franchise_overrides.sql.
--
--   "Atlanta Classic Cars" -- flagged true, initially suspected
--   of the same issue. independently verified via web search as
--   the authorized Mercedes-Benz dealer in Duluth. flag is
--   correct, do not override.
--
--   "Atlanta Toyota" -- known real franchise, doesn't appear
--   anywhere in this zip's list. coverage gap, not a flag error --
--   Sept 2020 is a sample, not a census, may not have captured
--   this dealer's listings that week.

-- reusable version for spot-checking any other zip:
-- SELECT DISTINCT sp_name
-- FROM 'C:/Users/jglen/Analytics_portfolio/08_cars/data/used_cars_data.csv'
-- WHERE franchise_dealer = true AND dealer_zip = '<target_zip>';

-- conclusion: flag is not perfect, error rate found so far is low
-- and specific (1 confirmed wrong label out of ~18 checked in one
-- zip), not systemic. going forward: only investigate a flag when
-- something concrete contradicts it, not by web-verifying every row.
