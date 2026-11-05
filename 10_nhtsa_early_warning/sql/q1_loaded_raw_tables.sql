--============================================================
--Project: 10_NHTSA_early_warning 
--File name: q1_loaded_raw_tables.sql
--Files used: FLAT_CMPL.txt, FLAT_RCL_POST_2010.txt
-- Table(s): complaints, recalls
-- Business question: Do the loaded raw tables reconcile to 
--                    the source files (row counts, field 
--                    counts, date ranges)?
--Purpose: Load data from NHTSA into duckdb for analysis, 
--           added column headers from NHTSA file system.
--           confirm each reconciles with original counts in
--           `data/README.md`  
--          (files must be run from project root)
--Author: J.Glenn
-- Date: November 2026
--============================================================

-- Create & load complaints table into duckdb from FLAT_CMPL.txt file
CREATE OR REPLACE TABLE complaints AS (
        SELECT *
        FROM read_csv('data/raw/FLAT_CMPL.txt'
           , delim = '\t'
           , header = false
           , names = ['CMPLID','ODINO','MFR_NAME',
           'MAKETXT','MODELTXT','YEARTXT','CRASH',
           'FAILDATE','FIRE','INJURED','DEATHS','COMPDESC',
           'CITY','STATE','VIN','DATEA','LDATE','MILES',
           'OCCURENCES','CDESCR','CMPL_TYPE','POLICE_RPT_YN',
           'PURCH_DT','ORIG_OWNER_YN','ANTI_BRAKES_YN',
           'CRUISE_CONT_YN','NUM_CYLS','DRIVE_TRAIN','FUEL_SYS',
           'FUEL_TYPE','TRANS_TYPE','VHE_SPEED','DOT',
           'TIRE_SIZE','LOC_OF_TIRE','TIRE_FAIL_TYPE',
           'ORIG_EQUIP_YN','MANUF_DT','SEAT_TYPE','RESTRAINT_TYPE',
           'DEALER_NAME','DEALER_TEL','DEALER_CITY',
           'DEALER_STATE','DEALER_ZIP','PROD_TYPE','REPAIRED_YN',
           'MEDICAL_ATTN','VEHICLES_TOWED_YN','STATE_OF_INCIDENT',
           'VEHICLE_OPERATOR']
           , all_varchar = true)
)
;

-- Confirm all entries from .txt file are in complaints table. (Expected count per data/README.md 2,261,650)
SELECT COUNT(*)
FROM complaints
;

-- Create & load recalls table into duckdb from FLAT_RCL_POST_2010.txt file
CREATE OR REPLACE TABLE recalls AS (  
        SELECT *
        FROM read_csv('data/raw/FLAT_RCL_POST_2010.txt'
           , delim = '\t'
           , header = false
           , names = ['RECORD_ID','CAMPNO','MAKETXT','MODELTXT','YEARTXT',
            'MFGCAMPNO','COMPNAME','MFGNAME','BGMAN','ENDMAN','RCLTYPECD',
            'POTAFF','ODATE','INFLUENCED_BY','MFGTXT','RCDATE','DATEA','RPNO',
            'FMVSS','DESC_DEFECT','CONEQUENCE_DEFECT','CORRECTIVE_ACTION','NOTES',
            'RCL_CMPT_ID','MFR_COMP_NAME','MFR_COMP_DESC','MFR_COMP_PTNO',
            'DO_NOT_DRIVE','PARK_OUTSIDE']
            , all_varchar = true)
)
;

-- Confirm all entries from .txt file are in recall table. (Expected count 247,021 per data/README.md)
SELECT COUNT(*)
FROM recalls
;

-- Count distinct recall campaigns. (Expected count 15,368 per data/README.md) 
SELECT COUNT(DISTINCT campno) AS Distinct_campaigns
FROM recalls
;

-- Confirm date range in recalls table & count to ensure no silent drops due to bad date format (Expected count: 247,021)
SELECT MIN(CAST(try_strptime(RCDATE, '%Y%m%d') AS DATE)) AS Oldest_recall
,      MAX(CAST(try_strptime(RCDATE, '%Y%m%d') AS DATE)) AS Newest_recall
,      COUNT(CAST(try_strptime(RCDATE, '%Y%m%d') AS DATE)) AS Count_dates 
FROM recalls
;

-- Confirm date range in complaints table & count to ensure no silent drops due to bad date format (Expected count: 2,261,650)
SELECT MIN(CAST(try_strptime(LDATE, '%Y%m%d') AS DATE)) AS Oldest_complaint
,      MAX(CAST(try_strptime(LDATE, '%Y%m%d') AS DATE)) AS Newest_complaint
,      COUNT(CAST(try_strptime(LDATE, '%Y%m%d') AS DATE)) AS Count_dates
FROM complaints
;

-- Count of entries between 2010-01-01 and 2026-10-28. (Expected 1,511,009 per data/README.md)
SELECT COUNT(*) AS Scope
FROM complaints
WHERE LDATE BETWEEN '20100101' AND '20261028' -- 20261028 used as end of the snapshot
;

-- Reconciling the number of Null faildate entries before and after 2010/01/01
SELECT 
       SUM(CASE WHEN LDATE < '20100101' THEN 1 ELSE 0 END) AS oos
,      SUM(CASE WHEN LDATE >= '20100101' THEN 1 ELSE 0 END) AS in_scope
FROM complaints
WHERE FAILDATE IS NULL 
;

-- confirmation complaints table loaded with headers and data, properly
-- Expected output: 1 / 958241 / VOLVO / 760 / 1987 / 19950103
SELECT CMPLID, ODINO, MAKETXT, MODELTXT, YEARTXT, LDATE
FROM complaints
WHERE CMPLID = '1'
;

-- Confirmation recall table loaded with headers and data, properly
-- Expected output: 10V224000/ FLEETWOOD / JAMBOREE SPORT / 2009 / 20100525
SELECT CAMPNO, MAKETXT, MODELTXT, YEARTXT, RCDATE 
FROM recalls
WHERE RECORD_ID = '81716'
;

-- Confirms column name/counts for complaints and recalls tables
DESCRIBE complaints; --(Expected 51 columns per data/README.md)
DESCRIBE recalls; --(Expected 29 columns per data/README.md)

