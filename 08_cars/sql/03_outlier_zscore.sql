-- ============================================================
-- 03_outlier_zscore.sql
-- Purpose: screen the 16 candidate zips for price outliers before
-- finalizing the 15-zip study set.
--
-- CAVEAT (state this in any write-up that cites this method):
-- z-scores and the +-2 SD convention assume a reasonably large,
-- roughly normal distribution. This is calculated on n=16 zip-level
-- averages -- a single unusual zip can distort the mean/SD used to
-- judge every other zip. This is used here as a DIRECTIONAL
-- SCREENING TOOL, not a statistically rigorous outlier test.
-- ============================================================

WITH zip_stats AS (
    SELECT
        dealer_zip, COUNT(*) AS listing_count,
        AVG(mileage) AS a_miles,
        AVG(price)   AS a_price,
        AVG(year)    AS a_year,
        CASE dealer_zip
            WHEN '30341' THEN 'Chamblee'
            WHEN '30360' THEN 'Doraville'
            WHEN '30339' THEN 'Vinings'
            ELSE city
        END AS display_city
    FROM 'C:\Users\jglen\Downloads\archive (3)\used_cars_data.csv'
    WHERE dealer_zip IN (
        '30096','30291','30519','30518','30144','30060','30067','30062',
        '30009','30013','30012','30094','30236','30341','30360','30339'
        -- includes 30236 (Jonesboro, since replaced) and 30360 (Doraville,
        -- excluded below) -- this is the full 16-zip CANDIDATE set, before
        -- either exclusion was finalized
    )
    AND franchise_dealer = true
    AND is_new = false
    GROUP BY display_city, dealer_zip
),
overall_stats AS (
    SELECT AVG(a_price) AS mean_price, STDDEV(a_price) AS sd_price
    FROM zip_stats
)
SELECT
    z.*,
    (z.a_price - o.mean_price) / o.sd_price AS z_score
FROM zip_stats z, overall_stats o
ORDER BY z_score DESC;

-- RESULT (recorded for reference):
--   30360 (Doraville): z ~ 2.70  -> EXCLUDED (exceeds +-2 threshold)
--   30339 (Vinings):   z ~ 1.45  -> RETAINED, but flagged in the writeup
--                                    as the second-highest z-score --
--                                    a near-miss, not a comfortable retain.
--   All other zips: within +-1.2, no concern.
