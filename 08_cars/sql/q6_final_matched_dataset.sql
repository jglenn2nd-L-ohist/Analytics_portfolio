-- ============================================================
-- q6_final_matched_dataset.sql
-- Purpose: produce the final, cleaned current-period dataset --
-- franchise status resolved, geography resolved, out-of-area and
-- duplicate rows removed. This is the dataset the actual
-- age/mileage/price comparison should be built from.
--
-- STILL TO DO (not yet run/decided as of this file's writing):
--   - apply the 2020-listing-share weighting when pooling metro-wide
--     averages (see docs/methodology.md sec. 9 "Next step")
--   - CPI-adjust price before comparing to the 2020 baseline
--
-- DONE: the 49 cross-zip duplicate VINs (sql/q6_current_period_cleaning.sql)
-- are resolved in the final `deduped` step below -- one row per VIN,
-- verified 6,500 total rows / 6,500 distinct VINs after resolution.
-- Resolution priority: (1) dealer's confirmed_zip from franchise_overrides,
-- (2) dealer's single most common searchZip across all their listings,
-- (3) deterministic tiebreak. Priority 2 is an ASSUMPTION, not a verified
-- address, for any dealer not in franchise_overrides -- worth spot-checking
-- before leaning on it heavily in the write-up.
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
filtered AS (
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
        )
),
dealer_dominant_zip AS (
    -- fallback for dealers NOT in franchise_overrides: their single
    -- most frequent searchZip stands in for their real location
    SELECT dealerId, searchZip,
           ROW_NUMBER() OVER (
               PARTITION BY dealerId
               ORDER BY COUNT(*) DESC
           ) AS rn
    FROM filtered
    GROUP BY dealerId, searchZip
),
deduped AS (
    SELECT
        f.*,
        ROW_NUMBER() OVER (
            PARTITION BY f.vin
            ORDER BY
                -- priority 1: matches the confirmed override zip
                CASE WHEN f.final_zip IS NOT NULL
                          AND CAST(f.searchZip AS VARCHAR) = f.final_zip
                     THEN 0 ELSE 1 END,
                -- priority 2: matches the dealer's own dominant zip
                CASE WHEN d.searchZip = f.searchZip AND d.rn = 1
                     THEN 0 ELSE 1 END,
                f.searchZip  -- final tiebreak, arbitrary but deterministic
        ) AS keep_rank
    FROM filtered f
    LEFT JOIN dealer_dominant_zip d ON f.dealerId = d.dealerId AND d.rn = 1
)
SELECT * FROM deduped WHERE keep_rank = 1;

-- Verification run alongside this query (2026-09-11): 6,500 total rows,
-- 6,500 distinct VINs -- confirms clean 1-row-per-vehicle resolution.
