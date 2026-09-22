---------------------------------------------------------
-- Project: Metro Atlanta Used-Car Inventory Study
-- File name: q3a_franchise_overrides_2020.sql
-- Table: overrides_2020 (persistent DuckDB table)
-- Business question: Q3a) Correct the known cars_2020 franchise_dealer
--                    flag errors identified in
--                    q2_franchise_flag_reliability_2020.sql, so
--                    cars_2020_fltrd can be built on a reconciled
--                    dealer list rather than the raw flag.
-- Purpose: exclude confirmed non-franchise mislabels and collapse
--          duplicate name variants to one canonical dealer name.
-- Author: J.Glenn
-- Date: September 2026
---------------------------------------------------------

CREATE TABLE IF NOT EXISTS overrides_2020 (
    sp_name     VARCHAR,
    dealer_name VARCHAR,
    franchise   BOOLEAN
);

INSERT INTO overrides_2020 (sp_name, dealer_name, franchise)
VALUES
    ('Southern Star Automotive', NULL, false),
    ('Courtesy Ford', 'Courtesy Ford', true),
    ('Courtesy Ford Conyers', 'Courtesy Ford', true),
    ('Courtesy Ford Mitsubishi', 'Courtesy Ford', true);