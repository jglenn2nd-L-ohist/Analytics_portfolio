-- ============================================================
-- q5_franchise_flag_reliability.sql
-- Question answered: does the 2020 franchise_dealer flag reliably
-- identify true franchise dealers, and where does it fail?
--
-- Method: no automated test catches a mislabeled flag -- the value
-- itself claims to already be true or false. The only way to find
-- an error is to pull the list of dealers a zip's flag says ARE
-- franchises and check names against real-world knowledge or an
-- independent source (manufacturer locator, web search).
-- ============================================================

-- List every dealer a given zip's 2020 data claims is a franchise.
-- Run per zip and spot-check names against known local dealers.
SELECT DISTINCT sp_name
FROM 'C:\Users\jglen\Downloads\archive (3)\used_cars_data.csv'
WHERE franchise_dealer = true AND dealer_zip = '30096';

-- FINDINGS from this check (30096 / Duluth):
--   "Southern Star Automotive" -- flagged true, confirmed NOT a
--     franchise by direct knowledge. This is a real error in the
--     source data. Overridden in q6_franchise_overrides.sql.
--   "Atlanta Classic Cars" -- flagged true, initially suspected of
--     the same issue (name resembles a vintage/collector car lot).
--     Independently verified via web search as the authorized
--     Mercedes-Benz dealership in Duluth, GA. Flag is CORRECT --
--     do not override.
--   "Atlanta Toyota" -- known real, long-standing franchise, does
--     NOT appear anywhere in this zip's franchise list at all. This
--     is a coverage gap, not a flag error -- the September 2020
--     crawl is a sample, not an exhaustive census, and may simply
--     not have captured this dealer's listings that week.

-- Reusable version of the check, for spot-checking any other zip:
-- SELECT DISTINCT sp_name
-- FROM 'C:\Users\jglen\Downloads\archive (3)\used_cars_data.csv'
-- WHERE franchise_dealer = true AND dealer_zip = '<target_zip>';

-- CONCLUSION: the flag is not perfect, but the error rate found so
-- far is low and specific (one confirmed wrong label out of ~18
-- dealers checked in one zip), not a systemic problem. Practical
-- approach going forward: only investigate a flag when something
-- concrete contradicts it (a name you know locally, a dealer you
-- expected to see and didn't) rather than web-verifying every row.
