# 06 —  Safe haven or Wild west: Atlanta 4yrs after Constitutional Carry

> **Correction notice (Oct 2026):** The original version grouped data by calendar year, which split the policy windows and distorted the results. All figures below are corrected. See [Corrections](#corrections) for details.

  --- 

## Business Context

In April 2022, Georgia began allowing eligible adults to carry handguns without a permit ("constitutional carry"). Supporters said the law removed a burden on law-abiding citizens, and critics said it would put more guns on the street. Andre Dickens took office as Atlanta's mayor in January 2022, so the four years analyzed fall within the Dickens era. This project asks a descriptive question: what happened to firearm-involved crime in Atlanta over those four years?

 ---

## Analyst Questions

| # | Question |
|---|----------|
| Q1 | How has firearm involvement in crime trended annually since constitutional carry took effect in April 2022?<br>- Total firearm-involved incidents per year<br>- As a percent of total incidents per year |
| Q2 | How has the rate of firearm-involved homicides trended annually over the same period? |
| Q3 | Under the Dickens administration and concurrent with constitutional carry, what does the overall trajectory of firearm violence look like across four years? |

 ---

## Data

Atlanta Police Department Open Data Portal
https://opendata.atlantapd.org/
Entries: 219,787 total incidents   10,401 firearm-involved
Time frame: April 1, 2022 - March 31, 2026
 
 ---

## Key Findings
| # | Findings |
|---|----------|
| Q1 | From policy years 2022-23 through 2025-26 the share of firearm related incidents have fallen from 5.85% to 3.77%. However, over the same time span the number of reported incidents in the city has risen from ~50,000 to ~62,000 (cause not examined; see limitations). Firearm incidents share has fallen from 2,930 to 2,341 |
| Q2 | The firearm involved homicides per 100 firearm incidents from 2022-2026 have shown a downward trend 4.37 (per 100 incidents) to 3.33, with the 2025-2026 policy year showing the largest decline. |
| Q3 | When viewed in totality, there is a clear trend downward of firearm related incidents and firearm related homicides. Noteworthy, here, is that the number of firearm related homicides per every 100 firearm incidents has dropped from 4.37 to 3.33 over this timespan. When viewed YoY, the first two policy years were flat then the city experienced the downward trend to the current 3.33. Although the city has seen an overall increase in reported incidents, firearm related incidents and corresponding homicides are experiencing a notable decline.Taken YOY, in the first 2 policy years, the rate was steady, but years 3 and 4 have shown a downward trend. Looking at the firearm involved homicides, the numbers for each year clearly show that downward slope from 128 -> 116 -> 101 -> 78 (Policy years 2022 - 2026)  |

 ---

## Methodology

Policy year calculation - A policy year, for the purpose of this analysis is the 12 month span from April 01 through the following March 31. In this way the 48 month window is subdivided into 4 co-equal segments for purposes of analysis. 

April 2022 - The Constitutional Carry law was enacted during the month of April. For the purposes of this analysis, the entire month is treated as if the law was already in existence.

### Calculation methods

Incidents - refer to each entry in the dataset.

Firearm incidents are determined by the file's column `FireArmInvolved` = yes

Firearm homicides were determined through the NIBRS code of 09A, along with the `FireArmInvolved` = yes distinction

`pcnt_firearms` = firearm_incidents (* 100) / all incidents 

Homicide rate = firearm homicides per 100 firearm incidents

YoY change = absolute difference from the prior window

 ---

## Limitations

Policy year 2022-2023 begins April 01, 2022, the same month when the Constitutional carry law took effect, so the analysis is silent on any prior statistics & does not intend to make any claims, other than those expressly revealed through the analysis. 

For change calculation, window 1 is the baseline, there is no prior window for comparison.

Population totals were not taken into account for this analysis, so the counts are raw, not on a per capita basis.

Firearm homicide counts are small (78 to 128 per year), so any single year-over-year change could be partly chance. The decline is credible because it runs in the same direction every year and totals 50 over the period. 

Factors not taken into account: 
National crime statistics,
Rise in incidents over time period (50,118 - 62,080),
Mix of crime incidents

 ---

## Corrections

The original analysis segmented the 48 months by calendar years, thus having 9 months in 2022 & 3 months in 2026. 

Partial years cause distortions in the analysis. 1 such distortion was the 4.94% firearm involved incidents in 2026. Originally, it looked as though 2026 ticked up significantly from the 3.57% in 2025. However, this number was an artifact from comparing the winter quarter to an entire year. Applying the corrected analysis, the downward trend held and the rebound in 2026 disappeared.

The original homicide query counted all murders (484) regardless of weapon. Adding the FireArmInvolved = yes filter removed 61 non-firearm murders, leaving 423. This is a change in definition, not a decline in homicides. Because the filter was missing, the original per-year homicide counts also included non-firearm murders and are not comparable to the corrected ones.

 ---

## Files

| File | Description |
|------|-------------|
| `00_profile.py` | Discover size shape and character of the working document |
| `01_etl.py` | Extract data clean and transform it then load into sqlite |
| `data_quality_summary.md` | Report the finding of the profile and transform phases |
| `acc.db` | SQLite database created through ETL process. Working file for querying |
| `q1_crimerate.sql` | Determine overall crime rate and firearm involved percentages over time |
| `q2_homicide.sql` | Determine firearm related homicide count over time |
| `q3_trajectory.sql` | Combine queries 1 & 2 to reveal trend, renders YoY change in firearm incidents & firearm involved homicides |
| `con_carry.py` | Python script for visualization |
| `firearm.png` | Vis for Percent of firearm related crimes |
| `homicides.png` | Vis to represent the number of homicides over the years |
| `trend.png` | Total reported incidents and firearm homicides, side by side |
| `atlanta_cc_case_study.html` | HTML case study deliverable |
 
 ---

## Tools
Excel Python SQL
 
 ---

## Status

complete