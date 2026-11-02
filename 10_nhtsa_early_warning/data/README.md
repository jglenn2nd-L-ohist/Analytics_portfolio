# Data - NHTSA Flat Files

## Source

NHTSA Office of Defects Investigation (ODI) bulk flat files, downloaded 2026-10-30. Public domain. Dataset records:

- Recalls: https://catalog.data.gov/dataset/nhtsas-office-of-defects-investigation-odi-recalls-nhtsa-api
- Complaints: https://catalog.data.gov/dataset/nhtsas-office-of-defects-investigation-odi-complaints-nhtsa-api-b17cc

Files are tab-delimited with dates in YYYYMMDD format. The complaints and investigations files have no header row. Field layouts follow the NHTSA data dictionary for each file.

## Files

| Table | File | Bytes | Rows | Fields | Date range |
|---|---|---|---|---|---|
| complaints | FLAT_CMPL.txt | 1,616,859,222 | 2,261,650 | 51 | 1995-01-01 to 2026-10-28 by date received (LDATE, field 17); 1,511,009 rows received 2010 or later |
| recalls | FLAT_RCL_POST_2010.txt | 312,675,150 | 247,021 | 29 | 2010-01-01 to 2026-10-27 (report received date); 15,368 distinct campaigns |
| investigations (not used) | FLAT_INV.txt | 390,689,692 | 154,455 | 11 | 1972-03-10 to 2026-10-23 by open date (ODATE, field 7); 5,354 distinct IDs |

Every row in all three files has the expected field count.

Notes:
- Row counts are records. `wc -l` reports 154,454 for `FLAT_INV.txt` because its last line has no trailing newline.
- Recalls and investigations have several rows per event (one per vehicle and component), so count distinct campaign or investigation IDs, not rows.
- About 4% of complaints have a blank failure date.
- Complaints carry two record dates: LDATE (field 17) is the date NHTSA received the complaint, and DATEA (field 16) is the date it was added to the file. They differ on 212,864 rows, so the choice of date matters for spike timing.

## Not used

`RCL_FROM_2015_2019.csv` and `RCL_FROM_2020_2024.csv` are a recall document index (ID, document name, make, model, model year, summary text). They have no dates, components, or unit counts, so they are not part of this analysis.

## Reproducing

Raw files live in `data/raw/` and are gitignored. To rebuild, download the same files from NHTSA and confirm that byte sizes and row counts match the table above. Later downloads will contain newer records, so counts will differ; record the new download date and counts if you refresh.
