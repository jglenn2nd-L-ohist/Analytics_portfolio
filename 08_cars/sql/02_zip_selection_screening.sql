-- ============================================================
-- 02_zip_selection_screening.sql
-- Purpose: derive the final 15-zip study set from the 2020 data.
-- See docs/methodology.md sec. 2 for the full reasoning behind
-- every inclusion/exclusion/substitution.
-- ============================================================

-- Step 1: per-zip, per-city listing volume, franchise + used only.
-- Grouping by BOTH city and zip is intentional here -- it's how the
-- Stonecrest/Lithonia and Atlanta/Chamblee/Doraville/Vinings city-label
-- splits were originally discovered. Do NOT collapse to zip-only until
-- after you've reviewed for label splits (step 2).
SELECT
    city, dealer_zip, COUNT(*) AS listing_count,
    AVG(mileage) AS a_miles,
    AVG(price)   AS a_price,
    AVG(year)    AS a_year
FROM 'C:\Users\jglen\Downloads\archive (3)\used_cars_data.csv'
WHERE dealer_zip IN (
    '30096','30291','30519','30518','30144','30060','30067','30062',
    '30009','30013','30012','30094','30260','30341','30339'
    -- 30360 intentionally excluded -- see 03_outlier_zscore.sql
)
AND franchise_dealer = true
AND is_new = false
GROUP BY city, dealer_zip
ORDER BY listing_count DESC;


-- Step 2: final version, with verified city labels resolved via CASE,
-- grouped by (display_city, dealer_zip) so zips with split raw labels
-- (e.g. 30341 under both "Atlanta" and "Chamblee") collapse into ONE
-- row instead of two. Grouping by the raw `city` column here would
-- silently double-count any zip with inconsistent labels.
SELECT
    dealer_zip, COUNT(*) AS listing_count,
    AVG(mileage) AS a_miles,
    AVG(price)   AS a_price,
    AVG(year)    AS a_year,
    CASE dealer_zip
        WHEN '30341' THEN 'Chamblee'   -- verified via zip-codes.com / USPS alias
        WHEN '30360' THEN 'Doraville'  -- verified; excluded as price outlier, see sql/03
        WHEN '30339' THEN 'Vinings'    -- verified; USPS lists "Cumberland" as name to avoid
        ELSE city
    END AS display_city
FROM 'C:\Users\jglen\Downloads\archive (3)\used_cars_data.csv'
WHERE dealer_zip IN (
    '30096','30291','30519','30518','30144','30060','30067','30062',
    '30009','30013','30012','30094','30260','30341','30339'
)
AND franchise_dealer = true
AND is_new = false
GROUP BY display_city, dealer_zip
ORDER BY listing_count DESC;


-- Zero-result checks performed during selection (kept for reference --
-- these confirm real absences, not query errors):
--   Douglasville (30134, 30135) -- 0 franchise listings, confirmed via
--     direct zip test with no city filter
--   Stockbridge (30281) -- 0 franchise listings, same confirmation
--   Jonesboro (30236) -- returned only 8 listings in the CURRENT-period
--     pull (population ceiling, not a query issue) -- replaced with
--     Morrow (30260), independently screened below before adoption

-- Morrow (30260) validation query -- run BEFORE adopting a substitute
-- zip, never assume a replacement will qualify:
SELECT dealer_zip, COUNT(*) AS listing_count,
       AVG(price), AVG(mileage), AVG(year)
FROM 'C:\Users\jglen\Downloads\archive (3)\used_cars_data.csv'
WHERE dealer_zip = '30260' AND franchise_dealer = true AND is_new = false
GROUP BY dealer_zip;
-- Result: 800 listings, price/mileage/year all within the existing
-- 15-zip distribution, no city-label split. Passed.
