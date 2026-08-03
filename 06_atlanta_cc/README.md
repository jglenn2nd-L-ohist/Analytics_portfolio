# 06 —  Safe haven or Wild west: Atlanta 4yrs after Constitutional Carry

## Business Context

Since April of 2022, Georgia has adopted Constitutional carry. The story of the time was lawbreakers don't follow the law, so why hinder law abiding citizens with a "gun owner tax". Simultaneously, Andre Dickens was elected Mayor of Atlanta, seen as inexperienced. This analysis is put forth to determine under the leadership of Dickens, during the constitutional carry period, has Atlanta become a safe haven or the Wild west.

--

## Analyst Questions

| # | Question |
|---|----------|
| Q1 | How has firearm involvement in crime trended annually since constitutional carry took effect in April 2022?<br>- Total firearm-involved incidents per year<br>- As a percent of total incidents per year |
| Q2 | How has the rate of firearm-involved homicides trended annually over the same period? |
| Q3 | Under the Dickens administration and concurrent with constitutional carry, what does the overall trajectory of firearm violence look like across four years? |

--

## Data

Atlanta Police Department Open Data Portal
https://opendata.atlantapd.org/
Time frame: April 1, 2022 - March 31, 2026
--

## Key Findings
| # | Findings |
|---|----------|
| Q1 | From 2022 to 2026 firearm related incidents have fallen from 6% to 4%. However, over the same time span the number of crimes in the city has risen from ~38,000 to ~65,000. All the while firearm incidents are between 2300 and ~2600 |
| Q2 | The homicide rate from 2022-2026 (partial year) has shown a downward trend. One exception, 2023, this year correlates with a spike in firearm related incidents. Otherwise, 120 (2022) - 97 (2025) |
| Q3 | The over all trajectory of firearm related fatalities is a downward slope, since the inception of constitutional carry. This trajectory and percent of firearm incidents have fallen dramatically since the law has taken effect. The most promising number is the fall of the homicides (down ~30%) |
--

## Files

| File | Description |
|------|-------------|
| `00_profile.py` | Discover size shape and character of the working document |
| `01_etl.py` | Extract data clean and transform it then load into sqlite |
| `data_quality_summary.md` | Report the finding of the profile and transform phases |
| `acc.db` | SQLite database created through ETL process. Working file for querying |
| `q1_crimerate.sql` | Determine overall crime rate and firearm involved percentages over time |
| `q2_homicide.sql` | Determine firearm related homicide rate over time |
| `q3_trajectory.sql` | Combine queries 1 & 2 to reveal trend |
--

## Tools

--

## Status

In Process