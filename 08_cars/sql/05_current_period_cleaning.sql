-- ============================================================
-- 05_current_period_cleaning.sql
-- Purpose: diagnose and resolve two data-quality issues found in
-- the raw auto.dev pull before it's usable for comparison.
-- ============================================================

-- ISSUE 1: NULL scraped zip on >50% of rows.
-- Diagnostic that found it -- confirms searchZip is fully populated
-- while the scraped zip field is not:
SELECT searchZip, COUNT(*) AS total, COUNT(zip) AS has_real_zip
FROM "C:/users/jglen/analytics_portfolio/08_cars/atlanta_listings_2026-09-10.csv"
GROUP BY searchZip
ORDER BY searchZip;
-- RESOLUTION: use searchZip as the authoritative geography field
-- throughout. The scraped `zip` field is not reliable enough to
-- group or filter on directly.


-- ISSUE 2: cross-zip VIN duplication (radius searches for
-- neighboring zips overlapping and pulling in the same listing
-- more than once).
SELECT vin, COUNT(DISTINCT searchZip) AS zip_appearances, COUNT(*) AS total_rows
FROM "C:/users/jglen/analytics_portfolio/08_cars/atlanta_listings_2026-09-10.csv"
GROUP BY vin
HAVING COUNT(DISTINCT searchZip) > 1
ORDER BY zip_appearances DESC;
-- RESULT: 49 VINs affected, all capped at exactly 2 zip appearances
-- (no VIN in 3+ zips except the Nalley Lexus Smyrna case below, which
-- surfaced separately through a dealer-level check).

-- Nalley Lexus Smyrna specifically appeared under THREE search zips
-- (30339, 30291, 30009) -- the case that triggered an independent
-- address lookup, confirming its real location (30080) is outside
-- the study area entirely. See docs/methodology.md sec. 10.

-- RESOLUTION RULE: for any VIN appearing under multiple searchZips,
-- keep only the row where searchZip matches that dealer's
-- confirmed_zip (from franchise_overrides, where available) or its
-- most common searchZip otherwise. Below is the diagnostic query
-- used to inspect each duplicate pair manually before deciding:
WITH dupes AS (
    SELECT vin
    FROM "C:/users/jglen/analytics_portfolio/08_cars/atlanta_listings_2026-09-10.csv"
    GROUP BY vin
    HAVING COUNT(DISTINCT searchZip) > 1
)
SELECT l.vin, l.dealer, l.dealerId, l.searchZip, o.confirmed_zip
FROM "C:/users/jglen/analytics_portfolio/08_cars/atlanta_listings_2026-09-10.csv" l
JOIN dupes d ON l.vin = d.vin
LEFT JOIN franchise_overrides o ON l.dealerId = o.dealerId
ORDER BY l.vin;
