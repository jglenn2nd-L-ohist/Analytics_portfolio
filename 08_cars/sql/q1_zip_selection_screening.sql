---------------------------------------------------------
-- Project: Metro Atlanta Used-Car Inventory Study
-- File name: q1_zip_selection_screening.sql
-- Table: used_cars_data.csv (2020)
-- Business question: Q1) Which metro Atlanta zip codes contain a
--                    defensible sample of franchise dealer, used
--                    only inventory in both periods?
-- Purpose: derive the final 15-zip study set, in the order the
--          decisions actually happened -- read top to bottom
-- Author: J.Glenn
-- Date: September 2026
---------------------------------------------------------

-- STAGE 1: 16-zip candidate pool. Stone Mountain -> Union City
-- and Douglasville/Stockbridge (0 franchise listings, confirmed
-- via direct zip test) -> Jonesboro already substituted in by
-- this point. Jonesboro (30236) and Doraville (30360) are both
-- still live candidates here, neither has been screened yet.
SELECT
    city, dealer_zip, COUNT(*) AS listing_count,
    AVG(mileage) AS a_miles, AVG(price) AS a_price, AVG(year) AS a_year
FROM 'C:/Users/jglen/Analytics_portfolio/08_cars/data/used_cars_data.csv'
WHERE dealer_zip IN (
    '30096','30291','30519','30518','30144','30060','30067','30062',
    '30009','30013','30012','30094','30236','30341','30360','30339'
)
AND franchise_dealer = true
AND is_new = false
GROUP BY city, dealer_zip
ORDER BY listing_count DESC;


-- STAGE 2: outlier screen on the 16-zip pool. n=16 zip-level
-- averages -- directional screening tool, not a rigorous test.
WITH zip_stats AS (
    SELECT
        dealer_zip, COUNT(*) AS listing_count,
        AVG(mileage) AS a_miles, AVG(price) AS a_price, AVG(year) AS a_year,
        CASE dealer_zip
            WHEN '30341' THEN 'Chamblee'
            WHEN '30360' THEN 'Doraville'
            WHEN '30339' THEN 'Vinings'
            ELSE city
        END AS display_city
    FROM 'C:/Users/jglen/Analytics_portfolio/08_cars/data/used_cars_data.csv'
    WHERE dealer_zip IN (
        '30096','30291','30519','30518','30144','30060','30067','30062',
        '30009','30013','30012','30094','30236','30341','30360','30339'
    )
    AND franchise_dealer = true
    AND is_new = false
    GROUP BY display_city, dealer_zip
),
overall_stats AS (
    SELECT AVG(a_price) AS mean_price, STDDEV(a_price) AS sd_price
    FROM zip_stats
)
SELECT z.*, (z.a_price - o.mean_price) / o.sd_price AS z_score
FROM zip_stats z, overall_stats o
ORDER BY z_score DESC;

-- result: 30360 (Doraville) z ~ 2.70 -> excluded.
-- 30339 (Vinings) z ~ 1.45 -> retained, near-miss, flagged in writeup.
-- all others within +-1.2. pool is now 15 zips, Jonesboro still in it.


-- STAGE 3: Jonesboro dropped for an unrelated reason -- its
-- CURRENT-period pull returned only 8 listings (population
-- ceiling, not a query issue). Morrow proposed as replacement,
-- validated against the 2020 data before being adopted, never
-- assume a substitute qualifies without testing it.
SELECT dealer_zip, COUNT(*) AS listing_count,
       AVG(price), AVG(mileage), AVG(year)
FROM 'C:/Users/jglen/Analytics_portfolio/08_cars/data/used_cars_data.csv'
WHERE dealer_zip = '30260' AND franchise_dealer = true AND is_new = false
GROUP BY dealer_zip;
-- result: 800 listings, distribution consistent with the rest of
-- the set, no city-label split. Morrow adopted. Pool is now the
-- final 15: Jonesboro (30236) out, Morrow (30260) in.


-- STAGE 4: final 15-zip set, city labels resolved, this is the
-- output the rest of the project builds on.
SELECT
    dealer_zip, COUNT(*) AS listing_count,
    AVG(mileage) AS a_miles, AVG(price) AS a_price, AVG(year) AS a_year,
    CASE dealer_zip
        WHEN '30341' THEN 'Chamblee'
        WHEN '30339' THEN 'Vinings'
        ELSE city
    END AS display_city
FROM 'C:/Users/jglen/Analytics_portfolio/08_cars/data/used_cars_data.csv'
WHERE dealer_zip IN (
    '30096','30291','30519','30518','30144','30060','30067','30062',
    '30009','30013','30012','30094','30260','30341','30339'
)
AND franchise_dealer = true
AND is_new = false
GROUP BY display_city, dealer_zip
ORDER BY listing_count DESC;
