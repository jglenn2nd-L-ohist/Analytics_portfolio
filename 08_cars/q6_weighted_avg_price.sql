---------------------------------------------------------
-- Project: Metro Atlanta Used-Car Inventory Study
-- File name: q6_weighted_avg_price.sql
-- Table: none (single-row results, not persisted)
-- Business question: Q6) Has the weighted average price of
--                    franchise-dealer used inventory increased
--                    by $2,000 or more in real, inflation-adjusted
--                    terms between September 2020 and September
--                    2026?
-- Purpose: weighted pooled price comparison using zip_weights
--          (Q3d), with 2020 prices converted to August 2026
--          dollars. Same weighting and exclusions as Q4 and Q5:
--          zip 30062 excluded from both periods, remaining 14
--          weights renormalized here, zip_weights left unedited.
--          Part 1 is the pre-registered test. Part 2 holds two
--          sensitivity runs that test whether the result depends
--          on which 2026 dealers are counted.
-- Author: J.Glenn
-- Date: September 2026
---------------------------------------------------------

-- CPI adjustment
--   Index:  CPI-U, all items, U.S. city average, not seasonally
--           adjusted (BLS series CUUR0000SA0 / FRED CPIAUCNS)
--   Values: August 2020 = 259.918, August 2026 = 334.980
--   Why all-items, not the used cars and trucks index: the
--   used-car index measures used-car price change, which is the
--   thing being tested. Deflating by it would remove the effect
--   by construction. All-items CPI asks the right question: did
--   used-car prices outpace general inflation?
--   Why August to August: September 2026 CPI was not yet
--   published. Matching the same calendar month on both ends
--   gives an exact 72-month span, keeps seasonal effects out of
--   the ratio, and leaves both CPI months one month before their
--   listing snapshots.
--
-- Price data quality
--   NULL prices: 0 in both tables.
--   Placeholder prices: 11 rows in final_matched under $1,000
--   (9 Global BMW, 2 Rick Case Hyundai Duluth), all recent model
--   years with normal mileage, so not real prices. 0 in 2020.
--   Floor: price >= 1000 applied to BOTH periods so the rule is
--   symmetric, even though 2020 has no rows below it.


-- =====================================================
-- PART 1: PRE-REGISTERED TEST (all 2026 franchise dealers)
-- =====================================================

WITH cpi AS (
    SELECT 259.918 AS aug20
         , 334.980 AS aug26
         , aug26 / aug20 AS ratio
)
, adj_weights AS (
    SELECT dealer_zip
         , cars_in_zip / (SELECT SUM(cars_in_zip)
                          FROM zip_weights
                          WHERE dealer_zip <> '30062') AS weight
    FROM zip_weights
    WHERE dealer_zip <> '30062'
)
, zip_prices_2026 AS (
    SELECT final_zip
         , AVG(price) AS av_prices_26
    FROM final_matched
    WHERE price >= 1000
    GROUP BY final_zip
)
, zip_prices_2020 AS (
    SELECT f.dealer_zip
         , AVG(c.ratio * f.price) AS cpi_adj_2020_price
    FROM cars_2020_fltrd f
    CROSS JOIN cpi c
    WHERE f.dealer_zip <> '30062'
      AND f.price >= 1000
    GROUP BY f.dealer_zip
)
SELECT ROUND(SUM(a.weight * z20.cpi_adj_2020_price), 0) AS prices_20
     , ROUND(SUM(a.weight * z26.av_prices_26), 0) AS prices_26
     , ROUND(SUM(a.weight * z26.av_prices_26)
           - SUM(a.weight * z20.cpi_adj_2020_price), 0) AS price_variation
FROM adj_weights a
JOIN zip_prices_2020 z20
  ON a.dealer_zip = z20.dealer_zip
JOIN zip_prices_2026 z26
  ON a.dealer_zip = z26.final_zip;


-- =====================================================
-- PART 2: SENSITIVITY RUNS
-- =====================================================
-- Price is more exposed to dealer mix than age or mileage. The
-- 2026 side of Part 1 includes dealers with no 2020 counterpart
-- in the data. They fall into two groups (see q3a):
--
--   True market entries (6): opened after the 2020 snapshot.
--     Porsche Atlanta Northwest, Porsche Atlanta Northeast,
--     Alfa Romeo of Marietta, Jim Ellis Cadillac, AutoNation USA
--     Kennesaw, Genesis of Kennesaw (opened August 2024).
--     These are real market change.
--
--   Coverage gap: operating in 2020 but absent from the 2020
--     data (all Nalley stores, Jim Ellis Hyundai, Jim Ellis Buick
--     GMC Atlanta, Ed Voyles Acura, BMW of Gwinnett Place, Kia of
--     Alpharetta, Atlanta Toyota, Conyers Mitsubishi,
--     Mercedes-Benz of Atlanta Northeast, and Marietta Toyota,
--     whose 2020 inventory sits in the excluded 30062). Counting
--     them in 2026 but not 2020 compares a fuller market to a
--     thinner one. This is a data artifact, not a market change.
--
-- Both runs change only the 2026 CTE. Weights and the 2020 side
-- are identical to Part 1. Each run returns a zips column, which
-- must read 14: a zip with no qualifying dealers would drop out of
-- the join and leave the weights summing to less than 1.
--
-- Continuing dealers = csv_match = true (matched 2020 data
-- automatically, carried in final_matched from q3c) plus 10
-- override dealers with a confirmed 2020 counterpart in a study
-- zip: Global BMW, John Miles, and 8 rebrands.


-- -----------------------------------------------------
-- 2A: EQUAL COVERAGE (continuing dealers + true entrants)
-- Drops only the coverage-gap stores. Most valid market-level
-- comparison: same coverage in both periods, genuine market
-- change included.
-- -----------------------------------------------------

WITH cpi AS (
    SELECT 259.918 AS aug20
         , 334.980 AS aug26
         , aug26 / aug20 AS ratio
)
, adj_weights AS (
    SELECT dealer_zip
         , cars_in_zip / (SELECT SUM(cars_in_zip)
                          FROM zip_weights
                          WHERE dealer_zip <> '30062') AS weight
    FROM zip_weights
    WHERE dealer_zip <> '30062'
)
, zip_prices_2026 AS (
    SELECT final_zip
         , AVG(price) AS av_prices_26
    FROM final_matched
    WHERE price >= 1000
      AND ( csv_match = true
         OR dealerId IN (
              -- continuing dealers, confirmed 2020 counterpart
              'd_da2c46d7beb1242f'  -- Global BMW
            , 'd_7bfda8a27828c52d'  -- John Miles
            , 'd_aa3c808ad5776409'  -- Group 1 Ford
            , 'd_f17a38eafcf9f604'  -- Premier Nissan
            , 'd_bea2c7500677d115'  -- Malcolm Cunningham
            , 'd_1bd625e0ea7fbcf7'  -- ALM Ford Marietta
            , 'd_a3ea3d7d17558de2'  -- Kia South Atlanta
            , 'd_e83b59ee37c7f8b8'  -- ALM GMC South
            , 'd_374d7b0ecf59000e'  -- Heritage Cadillac/Mitsubishi
            , 'd_3d857696dd81781d'  -- ALM Mazda South
              -- true market entries
            , 'd_99b977f96a96284d'  -- Porsche Atlanta Northwest
            , 'd_311f82aaf48fd9ca'  -- Porsche Atlanta Northeast
            , 'd_88688762ce447d03'  -- Alfa Romeo of Marietta
            , 'd_d4d87e801b663020'  -- Jim Ellis Cadillac
            , 'd_551adbb250d0115b'  -- AutoNation USA Kennesaw
            , 'd_517869e4c5e6b864'  -- Genesis of Kennesaw
         ) )
    GROUP BY final_zip
)
, zip_prices_2020 AS (
    SELECT f.dealer_zip
         , AVG(c.ratio * f.price) AS cpi_adj_2020_price
    FROM cars_2020_fltrd f
    CROSS JOIN cpi c
    WHERE f.dealer_zip <> '30062'
      AND f.price >= 1000
    GROUP BY f.dealer_zip
)
SELECT ROUND(SUM(a.weight * z20.cpi_adj_2020_price), 0) AS prices_20
     , ROUND(SUM(a.weight * z26.av_prices_26), 0) AS prices_26
     , ROUND(SUM(a.weight * z26.av_prices_26)
           - SUM(a.weight * z20.cpi_adj_2020_price), 0) AS price_variation
     , COUNT(*) AS zips
FROM adj_weights a
JOIN zip_prices_2020 z20
  ON a.dealer_zip = z20.dealer_zip
JOIN zip_prices_2026 z26
  ON a.dealer_zip = z26.final_zip;


-- -----------------------------------------------------
-- 2B: SAME DEALER (continuing dealers only)
-- Drops true entrants and coverage-gap stores. Like-for-like
-- comparison: how pricing changed at stores present in both
-- snapshots.
-- -----------------------------------------------------

WITH cpi AS (
    SELECT 259.918 AS aug20
         , 334.980 AS aug26
         , aug26 / aug20 AS ratio
)
, adj_weights AS (
    SELECT dealer_zip
         , cars_in_zip / (SELECT SUM(cars_in_zip)
                          FROM zip_weights
                          WHERE dealer_zip <> '30062') AS weight
    FROM zip_weights
    WHERE dealer_zip <> '30062'
)
, zip_prices_2026 AS (
    SELECT final_zip
         , AVG(price) AS av_prices_26
    FROM final_matched
    WHERE price >= 1000
      AND ( csv_match = true
         OR dealerId IN (
              -- continuing dealers, confirmed 2020 counterpart
              'd_da2c46d7beb1242f'  -- Global BMW
            , 'd_7bfda8a27828c52d'  -- John Miles
            , 'd_aa3c808ad5776409'  -- Group 1 Ford
            , 'd_f17a38eafcf9f604'  -- Premier Nissan
            , 'd_bea2c7500677d115'  -- Malcolm Cunningham
            , 'd_1bd625e0ea7fbcf7'  -- ALM Ford Marietta
            , 'd_a3ea3d7d17558de2'  -- Kia South Atlanta
            , 'd_e83b59ee37c7f8b8'  -- ALM GMC South
            , 'd_374d7b0ecf59000e'  -- Heritage Cadillac/Mitsubishi
            , 'd_3d857696dd81781d'  -- ALM Mazda South
         ) )
    GROUP BY final_zip
)
, zip_prices_2020 AS (
    SELECT f.dealer_zip
         , AVG(c.ratio * f.price) AS cpi_adj_2020_price
    FROM cars_2020_fltrd f
    CROSS JOIN cpi c
    WHERE f.dealer_zip <> '30062'
      AND f.price >= 1000
    GROUP BY f.dealer_zip
)
SELECT ROUND(SUM(a.weight * z20.cpi_adj_2020_price), 0) AS prices_20
     , ROUND(SUM(a.weight * z26.av_prices_26), 0) AS prices_26
     , ROUND(SUM(a.weight * z26.av_prices_26)
           - SUM(a.weight * z20.cpi_adj_2020_price), 0) AS price_variation
     , COUNT(*) AS zips
FROM adj_weights a
JOIN zip_prices_2020 z20
  ON a.dealer_zip = z20.dealer_zip
JOIN zip_prices_2026 z26
  ON a.dealer_zip = z26.final_zip;