-- ============================================================
-- 01_schema_reference.sql
-- Purpose: confirm the shape of both data sources before writing
-- any downstream query. Run this first if picking the project
-- back up after a break.
-- ============================================================

-- 2020 source (Kaggle "US Used Cars Dataset", CarGurus crawl)
DESCRIBE SELECT * FROM 'C:\Users\jglen\Downloads\archive (3)\used_cars_data.csv';

-- Key columns used throughout this project:
--   vin              -- unique vehicle identifier, used for dedup
--   sp_name          -- dealer/seller name (join key to current-period data)
--   dealer_zip       -- dealer's zip code (varchar; a small number of rows
--                       use ZIP+4 format like '08816-4351' -- use LEFT(dealer_zip, 5)
--                       when comparing/joining, never CAST to INT)
--   franchise_dealer -- boolean; largely reliable but NOT perfect
--                       (see docs/methodology.md sec. 10 for confirmed errors)
--   is_new           -- boolean; MUST filter is_new = false for this study
--   city             -- unreliable for filtering alone; some zips have
--                       inconsistent city labels (e.g. 30038 shows as both
--                       "Lithonia" and "Stonecrest")
--   price, mileage, year -- core comparison metrics


-- Current-period source (auto.dev API pull)
DESCRIBE SELECT * FROM "C:/users/jglen/analytics_portfolio/08_cars/atlanta_listings_2026-09-10.csv";

-- Key columns:
--   vin        -- join key back to 2020 data is NOT this; VINs won't match
--                 across a 6-year gap for used vehicles that already existed
--   dealer, dealerId -- dealer identity; dealerId is the reliable key
--   zip        -- SCRAPED zip; unreliable, >50% NULL across the pull. DO NOT
--                 use this as the primary geography field.
--   searchZip  -- the zip you searched to produce this row; 100% populated;
--                 USE THIS as the authoritative geography field.
--   createdAt  -- pull timestamp; used as the current-period reference date
--                 for age calculations (paired with Sept 2026 pull date)
