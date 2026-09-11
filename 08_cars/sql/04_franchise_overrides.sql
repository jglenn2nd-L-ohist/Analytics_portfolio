-- ============================================================
-- 04_franchise_overrides.sql
-- Purpose: manual corrections layered on top of the automated
-- 2020-CSV join, for current-period dealers that either (a) had
-- no clean name+zip match in the 2020 data, or (b) had a confirmed
-- WRONG franchise flag in the 2020 data itself.
--
-- This table does THREE jobs at once:
--   1. Supplies franchise_dealer status where the automated join
--      returned NULL (unmatched dealer).
--   2. Supplies a confirmed zip for cross-zip-duplicate VINs.
--   3. Overrides a wrong 2020 flag (see Southern Star note below).
--
-- IMPORTANT: only Nalley Lexus Smyrna's zip was INDEPENDENTLY
-- confirmed via an outside address lookup. Every other confirmed_zip
-- value below is taken from searchZip (i.e. "which zip search
-- produced this dealer's listings"), not a verified street address.
-- That distinction matters if a future duplicate-VIN check surfaces
-- another dealer with the same radius-overspill problem Nalley Lexus
-- Smyrna had -- don't assume the rest of this table is bulletproof.
-- ============================================================

CREATE TABLE IF NOT EXISTS franchise_overrides (
    dealerId       VARCHAR,
    dealer_name    VARCHAR,
    confirmed_zip  VARCHAR,
    is_franchise   BOOLEAN
);

INSERT INTO franchise_overrides VALUES
    ('d_da2c46d7beb1242f', 'Global BMW',                          '30339', true),
    ('d_502b8e552ef3fcf1', 'Atlanta Toyota',                      '30096', true),
    ('d_1f16ed20138a9923', 'Nalley Volkswagen',                   '30009', true),
    ('d_03ea8d40ecdd2bb1', 'Conyers Mitsubishi',                  '30094', true),
    ('d_1901a3ee9d9892bf', 'Porsche Atlanta Perimeter',           '30341', true),
    ('d_bc2200e21818b75c', 'Mercedes-Benz of Atlanta Northeast',  '30096', true),
    ('d_74be6f2a0eaf03ba', 'Mercedes-Benz of Atlanta South',      '30291', true),
    ('d_6f4a61ea535e8620', 'Palmer Dodge Chrysler Jeep Ram',      '30009', true),
    ('d_7bfda8a27828c52d', 'John Miles Chevrolet GMC Buick',      '30012', true),
    ('d_517869e4c5e6b864', 'Genesis of Kennesaw',                 '30144', true);
    -- Nalley Lexus Smyrna (d_1852bc615f5076d1) deliberately NOT included --
    -- independently verified real address is 2750 Cobb Pkwy SE, Smyrna GA
    -- 30080, outside the 15-zip study area. All its listings are excluded
    -- via the zip-membership filter in 06_final_matched_dataset.sql, not
    -- via this override table.

-- Known correction to a WRONG 2020-source flag (not an unmatched dealer --
-- this dealer IS in the 2020 CSV, but its franchise_dealer value is
-- incorrect):
--   "Southern Star Automotive" (30096) -- flagged franchise_dealer = true
--   in the source data; confirmed NOT a franchise dealer. If this dealer
--   appears in the current-period pull, treat it as is_franchise = false
--   regardless of what a straight 2020-CSV join would return.
--
-- Checked and found to be a FALSE ALARM (i.e. the 2020 flag was correct,
-- despite initial suspicion):
--   "Atlanta Classic Cars" -- verified as the authorized Mercedes-Benz
--   dealership in Duluth, GA. Do not override this one.
