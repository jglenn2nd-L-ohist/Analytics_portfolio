 Data Quality Summary - Safe haven or Wild West
**Project 06 | J.Glenn | August 2026**
**Data Source:**
Atlanta Police Department Open Data Portal (public domain)
https://opendata.atlantapd.org/
Time frame: April 1, 2022 - March 31, 2026
--

## Overview
The Atlanta crime records data was sourced from the Atlanta Police Department Open Data Portal (CC0: Public Domain) as a single .csv file containing 220581 records, 29 columns.

A profiling pass was conducted via 00_profile.py before any transformation. The pass examined shape, data types, null counts, and column-level relevance across set. Some issues were identified and flagged as out of scope.

The issues documented below reflect the decisions made during that process.

--

## Known Issues

| Issue | Severity | Analytical Impact | Resolution |
|---|---|---|---|
| NIBRS_Offense - 30,526 missing values | Moderate | This column has the simple to understand criminal offenses | NibrsUcrCode has all its records intact and this entry is the police code equivalent |
| IncidentNumber - has mixed values | Low | This column serves no purpose in this analysis | the column was simply imported as a string |
| CriminalGangActivityInvolved - column has 0 entries | Low | not in scope | Drop column during transformation stage, as it adds no value |
| ReportDate - string variable  | SEVERE | As a string, impossible to manipulate | Converted to datetime variable & surfaced impossible dates to be fixed in the ETL phase | Removed during ETL date range filtering |

Profiling identified no duplicate records.
ReportDate has 6 null entries & NIBRS_Offense over 30,000
Any other issues will be handled during the ETL phase
