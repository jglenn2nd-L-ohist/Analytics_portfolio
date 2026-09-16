---------------------------------------------------------
-- Project: Metro Atlanta Used-Car Inventory Study
-- File name: q3a_franchise_overrides.sql
-- Table: cars_2026, franchise_overrides
-- Business question: Q3a) Can current period franchise status and
--                    precise dealer location be recovered where
--                    the auto.dev data does not provide them
--                    directly? (part a: manual override table)
-- Purpose: manual corrections layered on top of the automated
--          2020-CSV name/zip join -- see q3c for how this table
--          gets consumed
-- Author: J.Glenn
-- Date: September 2026
---------------------------------------------------------

-- this table does four jobs:
--   1. supplies franchise status where the automated join found
--      no 2020 match at all (original 10 dealers below)
--   2. supplies a confirmed zip for cross-zip-duplicate VINs
--   3. corrects a wrong 2020 flag (Southern Star, see q2)
--   4. supplies franchise status for dealers with NO 2020 record
--      to match against in the first place -- rebrands,
--      relocations, and market entries (added second wave, see
--      docs/methodology.md sec. 12)
--
-- note: only Nalley Lexus Smyrna's zip was independently verified
-- via an outside address lookup. every other confirmed_zip below
-- comes from searchZip (which zip-search produced the listing),
-- not a verified street address.

CREATE TABLE IF NOT EXISTS franchise_overrides (
    dealerId       VARCHAR,
    dealer_name    VARCHAR,
    confirmed_zip  VARCHAR,
    is_franchise   BOOLEAN,
    note           VARCHAR
);

-- original 10: unmatched dealers, automated join found nothing
INSERT INTO franchise_overrides VALUES
    ('d_da2c46d7beb1242f', 'Global BMW',                          '30339', true, 'unmatched, manually verified'),
    ('d_502b8e552ef3fcf1', 'Atlanta Toyota',                      '30096', true, 'unmatched, manually verified'),
    ('d_1f16ed20138a9923', 'Nalley Volkswagen',                   '30009', true, 'unmatched, manually verified'),
    ('d_03ea8d40ecdd2bb1', 'Conyers Mitsubishi',                  '30094', true, 'unmatched, manually verified'),
    ('d_1901a3ee9d9892bf', 'Porsche Atlanta Perimeter',           '30341', true, 'unmatched, manually verified'),
    ('d_bc2200e21818b75c', 'Mercedes-Benz of Atlanta Northeast',  '30096', true, 'unmatched, manually verified'),
    ('d_74be6f2a0eaf03ba', 'Mercedes-Benz of Atlanta South',      '30291', true, 'unmatched, manually verified'),
    ('d_6f4a61ea535e8620', 'Palmer Dodge Chrysler Jeep Ram',      '30009', true, 'unmatched, manually verified'),
    ('d_7bfda8a27828c52d', 'John Miles Chevrolet GMC Buick',      '30012', true, 'unmatched, manually verified'),
    ('d_517869e4c5e6b864', 'Genesis of Kennesaw',                 '30144', true, 'unmatched, manually verified');

-- second wave: rebrand (1)
INSERT INTO franchise_overrides VALUES
    ('d_aa3c808ad5776409', 'Group 1 Ford of Kennesaw', '30144', true, 'rebrand of Jim Tidwell Ford, confirmed same zip');

-- second wave: relocation within study area (1)
INSERT INTO franchise_overrides VALUES
    ('d_30dc12b778ad65d1', 'Marietta Toyota', '30060', true, 'relocated from 30062 (2020) to 30060 (current), confirmed by direct knowledge');

-- second wave: market entry, no 2020 record, manufacturer-name
-- heuristic (verified: name search + franchise_make search both
-- empty within the 15-zip set -- see docs/methodology.md sec. 12
-- for why both methods matter, not just a name search)
INSERT INTO franchise_overrides VALUES
    ('d_f17a38eafcf9f604', 'Premier Nissan Mall of Georgia',       '30519', true, 'market entry, manufacturer-name heuristic'),
    ('d_4f7616f66f7376ba', 'Roswell Infiniti of North Atlanta',    '30009', true, 'market entry, manufacturer-name heuristic'),
    ('d_eb721084fa1ffd3d', 'Jim Ellis Buick GMC Atlanta',          '30341', true, 'market entry, manufacturer-name heuristic'),
    ('d_859185972d9889a2', 'Jim Ellis Hyundai',                    '30341', true, 'market entry, manufacturer-name heuristic'),
    ('d_1bd625e0ea7fbcf7', 'ALM Ford Marietta',                    '30060', true, 'market entry, manufacturer-name heuristic'),
    ('d_99b977f96a96284d', 'Porsche Atlanta Northwest',            '30067', true, 'market entry, manufacturer-name heuristic'),
    ('d_a3ea3d7d17558de2', 'Kia South Atlanta',                    '30260', true, 'market entry, manufacturer-name heuristic'),
    ('d_e83b59ee37c7f8b8', 'ALM GMC South',                        '30260', true, 'market entry, manufacturer-name heuristic'),
    ('d_0cd621b36668c03c', 'BMW of Gwinnett Place',                '30096', true, 'market entry, manufacturer-name heuristic'),
    ('d_88688762ce447d03', 'Alfa Romeo of Marietta',               '30060', true, 'market entry, manufacturer-name heuristic'),
    ('d_d4d87e801b663020', 'Jim Ellis Cadillac',                   '30341', true, 'market entry, manufacturer-name heuristic'),
    ('d_dac65c5d1cb39560', 'Kia of Alpharetta',                    '30009', true, 'market entry, manufacturer-name heuristic'),
    ('d_374d7b0ecf59000e', 'Heritage Cadillac/Mitsubishi',         '30260', true, 'market entry, manufacturer-name heuristic'),
    ('d_242b22a08bdeafd4', 'Mike Rezi Nissan Atlanta',             '30341', true, 'market entry, manufacturer-name heuristic'),
    ('d_af3d1e44b9d13eeb', 'Ed Voyles Acura',                      '30341', true, 'market entry, manufacturer-name heuristic'),
    ('d_b7091e2767392cf0', 'Nalley INFINITI of Atlanta',           '30341', true, 'market entry, manufacturer-name heuristic'),
    ('d_311f82aaf48fd9ca', 'Porsche Atlanta Northeast',            '30519', true, 'market entry, manufacturer-name heuristic'),
    ('d_3d857696dd81781d', 'ALM Mazda South',                      '30260', true, 'market entry, manufacturer-name heuristic'),
    ('d_653d519837f52532', 'Nalley Honda',                         '30291', true, 'market entry, manufacturer-name heuristic'),
    ('d_bea2c7500677d115', 'Malcolm Cunningham Chevrolet Atlanta', '30009', true, 'market entry, manufacturer-name heuristic');

-- exception to the manufacturer-name rule: not a manufacturer
-- franchise, included on business-legitimacy judgment (used-car
-- supercenter brand, not a brand-affiliated dealer)
INSERT INTO franchise_overrides VALUES
    ('d_551adbb250d0115b', 'AutoNation USA Kennesaw', '30144', true, 'market entry, judgment call not manufacturer-name rule -- see methodology sec. 12');

-- known correction to a WRONG 2020-source flag (dealer IS in the
-- 2020 CSV, but its franchise_dealer value is wrong):
--   "Southern Star Automotive" (30096) -- flagged true in source,
--   confirmed not a franchise. treat as is_franchise = false if
--   it appears in the current-period pull.
--
-- checked and found to be a FALSE ALARM (2020 flag was correct):
--   "Atlanta Classic Cars" -- verified authorized Mercedes-Benz
--   dealer in Duluth. do not override.
