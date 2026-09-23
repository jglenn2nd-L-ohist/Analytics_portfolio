# 08 - Metro Atlanta Used Car Inventory Study

## Business Context

J. hypothesized that metro Atlanta franchise dealer used vehicle inventory has shifted toward lower quality (older, higher mileage) at a higher price since September 2020. This project tests that hypothesis by matching a September 2020 CarGurus crawl against a live auto.dev pull for the current period, across a fixed set of metro Atlanta zip codes.

The comparison is framed as September 2020 vs. current, not pre-COVID vs. post-COVID. Pandemic driven supply chain disruption was already underway by September 2020, so it is not a clean undisturbed baseline.

--

## Analyst Questions

Numbered by dependency order: Q1-Q3 establish whether a valid comparison is even possible (zip set, flag reliability, franchise recovery). Q4-Q6 are the substantive hypotheses that comparison makes possible.

| # | Question |
|---|----------|
| Q1 | Which metro Atlanta zip codes contain a defensible sample of franchise dealer, used only inventory in both periods? |
| Q2 | Does the September 2020 franchise_dealer flag reliably identify true franchise dealers, and where does it fail? |
| Q3 | Can current period franchise status and precise dealer location be recovered where the auto.dev data does not provide them directly? |
| Q4 | Has average vehicle age increased by 18 months or more from September 2020 to the current period? |
| Q5 | Has average mileage increased by 15,000 miles or more? |
| Q6 | Has average price increased by $2,000 or more in real, inflation adjusted terms? |

--

## Data

Two sources, six years apart, same metro area.

| Period | Source | Rows | Location |
|---|---|---|---|
| September 2020 | Kaggle CarGurus crawl (`used_cars_data.csv`) | approx. 3M total, 8,722 across the 15 target zips (franchise, used only, `cars_2020_fltrd`) | `C:/Users/jglen/Analytics_portfolio/08_cars/data/` |
| Current (Sept 2026) | auto.dev API pull (`atlanta_listings_2026-09-10.csv`) | 6,549 raw, 6,498 after VIN dedup (`cars_2026_clean`), 3,279 in `final_matched` | `C:/Users/jglen/Analytics_portfolio/08_cars/data/` |

Both sources are loaded into a persistent DuckDB database (`08_cars.duckdb`) as base tables (`cars_2020`, `cars_2026`) rather than queried live from CSV in every script, except where a file still reads directly from the raw CSV by design (Q1, Q2).

--

## Key Findings

| # | Findings |
|---|----------|
| Q1 | 15 zips finalized: Duluth (30096), Union City (30291), Buford (30519, 30518), Kennesaw (30144), Marietta (30060, 30067, 30062), Alpharetta (30009), Conyers (30013, 30012, 30094), Chamblee (30341), Vinings (30339), Morrow (30260). Douglasville and Stockbridge returned 0 franchise listings and were dropped. Jonesboro (30236) was dropped for an insufficient current-period sample (n=8) and replaced by Morrow. Doraville (30360) was screened out as a price outlier, z-score approximately 2.70 against a +/- 2 threshold on n=16 zip level averages. |
| Q2 | The flag contains at least one confirmed error. Southern Star Automotive (30096) is flagged franchise_dealer = true but is not a franchise. Atlanta Classic Cars was suspected of the same issue on review but verified as a legitimate Mercedes-Benz franchise, the flag is correct. |
| Q3 | Recovered through a name and zip matched join against the 2020 data, loosened to substring matching in both directions after exact match under-recovered known franchises. Nalley Lexus Smyrna was excluded entirely after independent address verification placed its real location (30080) outside the 15 zip study area. A second wave of recovery, run after rebuilding the pipeline against a persistent database, found 22 additional franchise dealers missed by the original join: one confirmed rebrand (Group 1 Ford of Kennesaw, formerly Jim Tidwell Ford), one confirmed relocation within the study area (Marietta Toyota, 30062 to 30060), and 20 confirmed market entries verified as having no 2020 record under any name or manufacturer affiliation. `franchise_overrides` now holds 33 total dealers. `final_matched` grew from 2,593 rows (original 11 overrides, minus Nalley Lexus) to 3,279 rows. See `docs/methodology.md` sec. 12 for the full reasoning. |
| Q4 | No. Weighted average age rose from 2.66 years (September 2020) to 3.07 years (September 2026), an increase of 4.97 months against an 18 month threshold. Direction matches the hypothesis, magnitude does not. Zip 30062 was excluded from both periods because its only 2020 franchise dealer (Marietta Toyota) relocated to 30060; the remaining 14 zip weights were renormalized. |
| Q5 | No. Weighted average mileage rose from 41,594 miles (September 2020) to 45,962 miles (September 2026), an increase of 4,368 miles against a 15,000 mile threshold. The increase is consistent with the Q4 age shift: 4,368 miles over about 0.41 additional years is roughly 10,500 miles per year, close to typical annual driving. Inventory is older, not driven harder. |
| Q6 | Pending. Requires CPI adjustment before comparison. |

--

## Limitations

Both datasets are live lot inventory snapshots, not sales records. Neither reflects completed transactions.

Franchise dealer status is verified ground truth on the 2020 side, with confirmed corrections applied where the flag was wrong. On the current period side it is partially inferred through name matching, manual review, and (for the second-wave additions) a manufacturer-name heuristic rather than individual external verification against each manufacturer's own dealer locator. This is a stated tradeoff of coverage over per-dealer rigor, judged appropriate at portfolio scale.

Attrition (a dealer that closed between 2020 and 2026) is structurally invisible to this design: a closed dealer has no current-period listing to appear in the auto.dev pull at all, matched or unmatched. Market entry (a dealer that opened since 2020) is visible and is counted, provided it can be confirmed as a genuine franchise. This means the comparison may understate total inventory turnover even where it correctly counts new franchise entrants.

auto.dev's scraped zip field was NULL on more than half of all pulled rows, across nearly every target city. searchZip, the zip used to generate each API call, was fully populated and used as the geography field of record instead.

49 VINs appeared under more than one searchZip due to overlapping 2 mile radius searches on neighboring zips. Resolved to one row per VIN using a confirmed dealer zip where available, falling back to each dealer's single most common searchZip otherwise. The fallback is an assumption, not a verified address, for any dealer without a manual override.

z-scores used to screen for zip level price outliers were calculated on n=16 zip level averages. This is a directional screening tool, not a statistically rigorous outlier test at that sample size.

Current period sampling is equal weighted across zips (25 API calls each) rather than proportional to real market size, due to a monthly call budget. The final comparison corrects for this by weighting both periods using 2020 listing share, so a difference in results reflects a real shift rather than a sampling artifact.

Vehicle age is calculated from model year only (snapshot year minus model year), so it is measured in whole-year steps at the listing level. The 2020 crawl window was confirmed as September 9 to 17, which supports a flat 2020 snapshot year.

Q4 and Q5 are judged against pre-registered practical significance thresholds, not statistical significance tests. Because both observed differences (4.97 months, 4,368 miles) fall well below their thresholds, a significance test would not change either conclusion.

Mileage is missing (NULL) on 99 of 8,630 2020 rows and 37 of 3,279 2026 rows, about 1.1% on each side, and those rows are excluded from the mileage averages. In 2020, all 25 missing values in 30339 belong to Global Imports BMW, the only franchise dealer in that zip, leaving its average based on 173 of 198 listings. No zero-mileage placeholder values were found in either table.

--

## Feature Engineering (Methodology) Notes

Zip code, not city name, is the only reliable geography filter in the 2020 source. The same zip code can carry more than one raw city label (30341 appears as both "Atlanta" and "Chamblee", 30038 appears as both "Lithonia" and "Stonecrest"). Grouping by city and zip together, rather than zip alone, is what exposes this before it silently double counts a zip's listings under two labels.

dealer_zip in the 2020 source is stored as varchar, not integer. A small number of rows use ZIP+4 format (example: 08816-4351). Casting this column to an integer type fails on those rows. Comparisons and joins on dealer_zip use LEFT(dealer_zip, 5), never a numeric cast.

The current period pull's scraped zip field cannot be trusted as the primary geography key. searchZip, not zip, is the field used throughout every downstream query.

Sample size alone does not determine whether a small-n zip average is trustworthy. The check that matters is the gap between the median and the mean within that zip. A small gap means the average reflects the group as a whole. A large gap means a handful of outlier listings are driving the number.

Name-matching between the two periods must check both directions (2020 name containing the current name, and current name containing the 2020 name). Checking only one direction misses real matches whose naming convention runs the other way (a dealer that grew a more specific name over time, or vice versa). Both name conditions and the zip condition must be grouped together with explicit parentheses in the join, since SQL evaluates AND before OR by default, and an ungrouped version silently drops the zip requirement from two of the three name conditions.

A name search alone cannot distinguish "this dealer is new to the market" from "this dealer exists under an unrelated name." Confirming genuine absence from the 2020 data requires checking both the dealer's business name (`sp_name`) and the brand it sells (`franchise_make`) independently. A dealer confirmed absent from the 2020 data by both methods is still counted as a real current-period franchise if it meets the manufacturer-name heuristic; it is not disqualified for lacking a 2020 counterpart.

Pooled averages are weighted at the zip level, not the row level. Each period's per-zip average is computed first, then multiplied by that zip's fixed 2020 weight and summed. Weighting individual rows would let zips with more listings count twice.

Exclusions filter on the zip itself (`dealer_zip <> '30062'`), not on a weight cutoff. A cutoff happened to isolate 30062 but sat about one thousandth above the next smallest weight (30094), so a small data correction could have silently dropped a second zip.

Because the zip weights are the 2020 listing shares, the weighted 2020 average must equal the plain average across all 2020 rows in the included zips. This was verified for Q4 (2.66 years both ways) and serves as a built-in check on the weighting mechanics. It does not hold exactly for Q5: the weights count every listing, but AVG() skips NULL mileage rows, so a small gap between the weighted and plain 2020 averages is expected there.

A missing value can hide as a zero. Some dealer feeds write 0 when mileage was not entered, and AVG() counts a 0 as a real reading while it skips a NULL. Both tables were checked for exact-zero mileage before Q5 was built.

--

## Files

| File | Description |
|------|-------------|
| `docs/methodology.md` | Full decision log: zip selection and screening, every exclusion and substitution, data corrections, sampling design, second-wave franchise recovery, weighted pooling |
| `sql/00_schema_reference.sql` | Column reference for both data sources, key fields to use and avoid |
| `sql/q1_zip_selection_screening.sql` | Full zip selection process: 16-candidate pool, outlier screen, Jonesboro-to-Morrow substitution, final 15-zip set |
| `sql/q2_franchise_flag_reliability.sql` | Spot-check method for the 2020 franchise_dealer flag, confirmed error and false-alarm findings |
| `sql/q2_franchise_flag_reliability_2020.sql` | 2020-side flag reliability checks feeding the 2020 reconciled population |
| `sql/q3a_franchise_overrides.sql` | Manual dealer corrections table: original 10 unmatched dealers plus 22 second-wave additions (rebrand, relocation, market entry) |
| `sql/q3a_franchise_overrides_2020.sql` | 2020-side corrections: Southern Star Automotive flag error, Courtesy Ford name variants consolidated, outputs `overrides_2020` |
| `sql/q3b_current_period_cleaning.sql` | NULL zip diagnostic, cross-zip VIN duplication resolution, outputs `cars_2026_clean` |
| `sql/q3c_final_matched_dataset.sql` | Franchise join against 2020 data plus overrides, zip-membership filter, outputs `final_matched` |
| `sql/q3c_final_filtered_2020.sql` | 2020 reconciled population (franchise, used only, 15 zips, VIN-unique), outputs `cars_2020_fltrd` (8,722 rows) |
| `sql/q3d_zip_weights.sql` | Fixed zip weights from 2020 listing share, outputs `zip_weights`, shared by Q4-Q6 |
| `sql/q4_weighted_avg_age.sql` | Weighted average age comparison, 30062 excluded from both periods, 14 weights renormalized |
| `sql/q5_weighted_avg_mileage.sql` | Weighted average mileage comparison, same weighting and exclusions as Q4 |
| `data/README.md` | Raw data file locations |

--

## Tools

SQL (DuckDB), persistent database (`08_cars.duckdb`). Weighted pooling is done in SQL. Python planned for CPI adjustment and any statistical testing, not yet built.

--

## Status

Zip selection and flag reliability (Q1, Q2): Complete
Franchise and zip resolution (Q3): Complete, including second-wave recovery and 2020-side reconciliation
Weighted age comparison (Q4): Complete, threshold not met
Weighted mileage comparison (Q5): Complete, threshold not met
Price comparison (Q6): Not started