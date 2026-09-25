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
--      no 2020 match (original 7 dealers below)
--   2. supplies a confirmed zip for cross-zip-duplicate VINs
--   3. corrects a wrong 2020 flag (Southern Star, see q2)
--   4. supplies franchise status for dealers the automated join
--      cannot match: rebrands, relocations, stores missing from
--      the 2020 data, and market entries (second wave, see
--      docs/methodology.md sec. 12)
--
-- how exclusion works: a dealer with no 2020 match in a study zip
-- can only enter final_matched through a row in this table.
-- leaving a dealer out of this table excludes it. excluded dealers
-- are recorded at the bottom of this file.
--
-- zip verification: confirmed_zip values were originally taken
-- from searchZip (which radius search returned the listing), not a
-- street address. in September 2026 every override dealer was
-- checked against either (a) its 2020 record in a study zip or
-- (b) its current street address. notes below say which.

CREATE OR REPLACE TABLE franchise_overrides (
    dealerId       VARCHAR,
    dealer_name    VARCHAR,
    confirmed_zip  VARCHAR,
    is_franchise   BOOLEAN,
    note           VARCHAR
);

-- original 7: unmatched dealers, automated join found nothing
INSERT INTO franchise_overrides VALUES
    ('d_da2c46d7beb1242f', 'Global BMW',                          '30339', true, 'unmatched; 2020 record as Global Imports BMW, 30339'),
    ('d_502b8e552ef3fcf1', 'Atlanta Toyota',                      '30096', true, 'unmatched; address verified, 2345 Pleasant Hill Rd'),
    ('d_1f16ed20138a9923', 'Nalley Volkswagen',                   '30009', true, 'unmatched; address verified, 1550 Mansell Rd; no Nalley stores in 2020 data'),
    ('d_03ea8d40ecdd2bb1', 'Conyers Mitsubishi',                  '30094', true, 'unmatched; address verified, 1540 Iris Dr SW'),
    ('d_bc2200e21818b75c', 'Mercedes-Benz of Atlanta Northeast',  '30096', true, 'unmatched; address verified, 1705 Boggs Rd'),
    ('d_7bfda8a27828c52d', 'John Miles Chevrolet GMC Buick',      '30012', true, 'unmatched; 2020 record in 30012'),
    ('d_517869e4c5e6b864', 'Genesis of Kennesaw',                 '30144', true, 'unmatched; address verified, 2870 Barrett Lakes Blvd');

-- second wave: rebrand, prior name present in 2020 data (8)
INSERT INTO franchise_overrides VALUES
    ('d_aa3c808ad5776409', 'Group 1 Ford of Kennesaw',             '30144', true, 'rebrand of Jim Tidwell Ford, same zip'),
    ('d_f17a38eafcf9f604', 'Premier Nissan Mall of Georgia',       '30519', true, 'rebrand of Sutherlin Nissan, prior name in 2020 data'),
    ('d_bea2c7500677d115', 'Malcolm Cunningham Chevrolet Atlanta', '30009', true, 'rebrand, minor name change, prior name in 2020 data'),
    ('d_1bd625e0ea7fbcf7', 'ALM Ford Marietta',                    '30060', true, 'rebrand of AutoNation store, prior name in 2020 data'),
    ('d_a3ea3d7d17558de2', 'Kia South Atlanta',                    '30260', true, 'rebrand, 2020 record as Kia Atlanta South, 30260'),
    ('d_e83b59ee37c7f8b8', 'ALM GMC South',                        '30260', true, 'rebrand, prior name in 2020 data'),
    ('d_374d7b0ecf59000e', 'Heritage Cadillac/Mitsubishi',         '30260', true, 'rebrand, prior name in 2020 data'),
    ('d_3d857696dd81781d', 'ALM Mazda South',                      '30260', true, 'rebrand, prior name in 2020 data');

-- second wave: relocation within study area (1)
INSERT INTO franchise_overrides VALUES
    ('d_30dc12b778ad65d1', 'Marietta Toyota', '30060', true, 'relocated from 30062 (2020) to 30060 (current), confirmed by direct knowledge');

-- second wave: operating before 2020 but absent from the 2020
-- data (7). address verified in a study zip, so the 2026 listings
-- are valid. their 2020 inventory cannot be counted, which is a
-- documented coverage gap, not an exclusion.
INSERT INTO franchise_overrides VALUES
    ('d_eb721084fa1ffd3d', 'Jim Ellis Buick GMC Atlanta',  '30341', true, 'pre-2020 store absent from 2020 data; address verified, 5862 Peachtree Blvd'),
    ('d_859185972d9889a2', 'Jim Ellis Hyundai',            '30341', true, 'pre-2020 store absent from 2020 data; address verified, 5901 Peachtree Blvd'),
    ('d_af3d1e44b9d13eeb', 'Ed Voyles Acura',              '30341', true, 'pre-2020 store absent from 2020 data; address verified, 5700 Peachtree Blvd'),
    ('d_b7091e2767392cf0', 'Nalley INFINITI of Atlanta',   '30341', true, 'pre-2020 store absent from 2020 data (no Nalley stores in 2020 data); address verified, 2550 The Nalley Way'),
    ('d_0cd621b36668c03c', 'BMW of Gwinnett Place',        '30096', true, 'pre-2020 store absent from 2020 data; address verified, 3264 Commerce Ave NW'),
    ('d_653d519837f52532', 'Nalley Honda',                 '30291', true, 'franchise conversion from Nalley Chevrolet, same location; absent from 2020 data (no Nalley stores); address verified, 4197 Jonesboro Rd'),
    ('d_dac65c5d1cb39560', 'Kia of Alpharetta',            '30009', true, 'pre-2020 store absent from 2020 data, possibly relocated into study area; address verified, 10955 Westside Pkwy');

-- second wave: market entry, no 2020 counterpart (4)
INSERT INTO franchise_overrides VALUES
    ('d_99b977f96a96284d', 'Porsche Atlanta Northwest',  '30067', true, 'market entry; address verified, 2501 Windy Hill Rd SE'),
    ('d_311f82aaf48fd9ca', 'Porsche Atlanta Northeast',  '30519', true, 'market entry; address verified, 3680 Buford Dr'),
    ('d_88688762ce447d03', 'Alfa Romeo of Marietta',     '30060', true, 'market entry; address verified, 681 Cobb Pkwy SE'),
    ('d_d4d87e801b663020', 'Jim Ellis Cadillac',         '30341', true, 'market entry; address verified, 5880 Peachtree Blvd');

-- exception to the manufacturer-name rule: not manufacturer
-- franchises, included on business-legitimacy judgment. both are
-- used-car brands owned by large franchise dealer groups
-- (AutoNation, Sonic Automotive), treated on the same basis (2)
INSERT INTO franchise_overrides VALUES
    ('d_551adbb250d0115b', 'AutoNation USA Kennesaw',                 '30144', true, 'market entry, judgment call not manufacturer-name rule; address verified, 2275 Barrett Lakes Blvd NW'),
    ('d_bb9c5094e1906d91', 'EchoPark Automotive - Atlanta (Duluth)',  '30096', true, 'market entry (opened December 2020), Sonic Automotive used-car brand, same basis as AutoNation USA; address verified, 3296 Commerce Ave NW');

-- EXCLUDED: radius-search overspill. each dealer's verified street
-- address is outside the 15-zip study area. its 2026 listings
-- appeared under a study-zip searchZip only because a 2-mile radius
-- search reached across the zip boundary. no override row = not in
-- final_matched.
--   Nalley Lexus Smyrna                 2750 Cobb Pkwy SE, Smyrna 30080
--                                       (appeared under 30339, 30291, 30009)
--   Porsche Atlanta Perimeter           4006 Carver Dr, Atlanta 30360
--     (d_1901a3ee9d9892bf)              (appeared under 30341; 2020 record
--                                       as Jim Ellis Porsche Atlanta
--                                       Perimeter, 30360)
--   Mike Rezi Nissan                    4400 Motors Industrial Way, Atlanta 30360
--     (d_242b22a08bdeafd4)              (appeared under 30341; 2020 record
--                                       in 30360)
--   Palmer Dodge Chrysler Jeep Ram      11460 Alpharetta Hwy, Roswell 30076
--     (d_6f4a61ea535e8620)              (appeared under 30009; 2020 record
--                                       in 30076)
--   Roswell Infiniti of North Atlanta   11405 Alpharetta Hwy, Roswell 30076
--     (d_4f7616f66f7376ba)              (appeared under 30009; 2020 record
--                                       in 30076; now listed as RBM
--                                       INFINITI of North Atlanta)
--   Mercedes-Benz of Atlanta South      3800 Royal South Pkwy, Atlanta 30349
--     (d_74be6f2a0eaf03ba)              (appeared under 30291; 2020 record
--                                       as Mercedes-Benz of South Atlanta,
--                                       30349)

-- NOT INCLUDED: reviewed from the unmatched 2026 dealers and left
-- out of this table on purpose.
--   ALM Kennesaw, ALM Mall of Georgia, ALM Marietta, Atlanta Luxury
--   Motors Inc -- independent pre-owned stores. ALM also owns
--   branded franchise stores (ALM Ford, ALM GMC, ALM Mazda above),
--   but these locations are not franchises.
--   DriveTime, Enterprise Car Sales, Hertz Car Sales, Avis Car
--   Sales -- used-car and rental-fleet sales chains, not franchise
--   dealers and not the same kind of store as AutoNation USA or
--   EchoPark.
--   Ed Voyles CDJR (30060) -- one 2026 listing under a short name
--   variant. the store itself is already in final_matched through
--   the automated match as "Ed Voyles Chrysler Dodge Jeep". only
--   this one listing is missed.
--   Audi Atlanta (30341), Butler Chrysler Dodge Jeep (30291) --
--   franchise stores, one 2026 listing each. known omissions, not
--   added: single listings cannot move any result.

-- known correction to a WRONG 2020-source flag (dealer IS in the
-- 2020 CSV, but its franchise_dealer value is wrong):
--   "Southern Star Automotive" (30096) -- flagged true in source,
--   confirmed not a franchise. treat as is_franchise = false if
--   it appears in the current-period pull.
--
-- checked and found to be a FALSE ALARM (2020 flag was correct):
--   "Atlanta Classic Cars" -- verified authorized Mercedes-Benz
--   dealer in Duluth. do not override.