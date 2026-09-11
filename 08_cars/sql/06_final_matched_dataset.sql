-- ============================================================
-- 06_final_matched_dataset.sql
-- Purpose: produce the final, cleaned current-period dataset --
-- franchise status resolved, geography resolved, out-of-area and
-- duplicate rows removed. This is the dataset the actual
-- age/mileage/price comparison should be built from.
--
-- STILL TO DO (not yet run/decided as of this file's writing):
--   - resolve the 49 cross-zip duplicate VINs to a single row each
--     (see sql/05_current_period_cleaning.sql for the diagnostic --
--     a final resolution rule/query has not yet been executed)
--   - apply the 2020-listing-share weighting when pooling metro-wide
--     averages (see docs/methodology.md sec. 9 "Next step")
--   - CPI-adjust price before comparing to the 2020 baseline
-- ============================================================

WITH csv_lookup AS (
    SELECT DISTINCT sp_name, dealer_zip, franchise_dealer
    FROM 'C:\Users\jglen\Downloads\archive (3)\used_cars_data.csv'
),
matched AS (
    SELECT
        c.*,
        l.franchise_dealer,
        l.dealer_zip AS csv_matched_zip
    FROM "C:/users/jglen/analytics_portfolio/08_cars/atlanta_listings_2026-09-10.csv" c
    LEFT JOIN csv_lookup l
        ON (LOWER(TRIM(c.dealer)) = LOWER(TRIM(l.sp_name))
            OR l.sp_name ILIKE '%' || TRIM(c.dealer) || '%')
       AND LEFT(l.dealer_zip, 5) = CAST(c.searchZip AS VARCHAR)
)
SELECT
    m.*,
    COALESCE(o.is_franchise, m.franchise_dealer) AS final_franchise_flag,
    COALESCE(o.confirmed_zip, m.csv_matched_zip, CAST(m.searchZip AS VARCHAR)) AS final_zip
FROM matched m
LEFT JOIN franchise_overrides o ON m.dealerId = o.dealerId
WHERE
    -- keep only confirmed franchise dealers
    COALESCE(o.is_franchise, m.franchise_dealer) = true
    -- drop anything resolving to a zip outside the official 15-zip
    -- study area -- this is what automatically excludes Nalley Lexus
    -- Smyrna (real zip 30080) without needing a dealer-specific
    -- exclusion rule
    AND COALESCE(o.confirmed_zip, m.csv_matched_zip, CAST(m.searchZip AS VARCHAR)) IN (
        '30096','30291','30519','30518','30144','30060','30067','30062',
        '30009','30013','30012','30094','30260','30341','30339'
    );
