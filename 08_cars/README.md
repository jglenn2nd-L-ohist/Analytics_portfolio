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
| Current (Sept 2026) | auto.dev API pull (`atlanta_listings_2026-09-10.csv`, pulled by `python/00_pull_listing.py`) | 6,549 raw, 6,498 after VIN dedup (`cars_2026_clean`), 3,041 in `final_matched` | `C:/Users/jglen/Analytics_portfolio/08_cars/data/` |

Both sources are loaded into a persistent DuckDB database (`data/08_cars.duckdb`) as base tables (`cars_2020`, `cars_2026`) rather than queried live from CSV in every script, except where a file still reads directly from the raw CSV by design (Q1, Q2). The database is generated from the CSVs and the scripts, so it is excluded from Git (`.gitignore`) along with the raw data files.

--

## Key Findings

| # | Findings |
|---|----------|
| Q1 | 15 zips finalized: Duluth (30096), Union City (30291), Buford (30519, 30518), Kennesaw (30144), Marietta (30060, 30067, 30062), Alpharetta (30009), Conyers (30013, 30012, 30094), Chamblee (30341), Vinings (30339), Morrow (30260). Douglasville and Stockbridge returned 0 franchise listings and were dropped. Jonesboro (30236) was dropped for an insufficient current-period sample (n=8) and replaced by Morrow. Doraville (30360) was screened out as a price outlier, z-score approximately 2.70 against a +/- 2 threshold on n=16 zip level averages. |
| Q2 | The flag contains at least one confirmed error. Southern Star Automotive (30096) is flagged franchise_dealer = true but is not a franchise. Atlanta Classic Cars was suspected of the same issue on review but verified as a legitimate Mercedes-Benz franchise, the flag is correct. |
| Q3 | Recovered through a name and zip matched join against the 2020 data, loosened to substring matching in both directions after exact match under-recovered known franchises. Nalley Lexus Smyrna was excluded entirely after independent address verification placed its real location (30080) outside the 15 zip study area. A second wave of recovery added 23 dealers missed by the original join. A later review reclassified them: 8 rebrands whose prior names appear in the 2020 data, 1 relocation within the study area (Marietta Toyota, 30062 to 30060), 7 stores that operated before 2020 but are absent from the 2020 data, 5 true market entries, and 2 that turned out to be outside the study area. An address audit of every override dealer then found five whose street address is outside the 15 study zips (Porsche Atlanta Perimeter, Mike Rezi Nissan, Palmer Dodge, Roswell Infiniti, Mercedes-Benz of Atlanta South). Their 2026 listings had entered through 2 mile radius searches, and all five were excluded, as Nalley Lexus had been. The rebuild also replaced the 2020 match JOIN with EXISTS after Courtesy Ford's three 2020 name variants produced 114 duplicate rows. A final review of every unmatched 2026 dealer added EchoPark Automotive (Sonic Automotive's used-car brand, opened December 2020) on the same basis as AutoNation USA, and documented the stores deliberately left out (ALM's independent pre-owned stores, rental and used-car chains, and three one-listing franchise stores). `franchise_overrides` now holds 29 dealers, and `final_matched` holds 3,041 rows, one per VIN. See `docs/methodology.md` sec. 12. |
| Q4 | No, with high confidence. Weighted average age rose from 2.66 years (September 2020) to 3.10 years (September 2026), an increase of 5.31 months (95% CI 1.0 to 10.1) against an 18 month threshold. The increase is real, since the interval excludes zero, but far short of the threshold. The same-dealer comparison gives +7.03 months (CI 2.7 to 25.9), consistent in direction but too imprecise to test the threshold on its own. Zip 30062 was excluded from both periods because its only 2020 franchise dealer (Marietta Toyota) relocated to 30060; the remaining 14 zip weights were renormalized. |
| Q5 | No, with high confidence. Weighted average mileage rose from 41,594 to 47,477 miles, an increase of 5,883 miles (95% CI 1,637 to 11,620) against a 15,000 mile threshold. The same-dealer comparison gives +3,751 miles (CI 625 to 23,990). In the pre-registered comparison, 5,883 miles over about 0.44 additional years of age is roughly 13,300 miles per year, in line with typical annual driving. At continuing dealers it is about 6,400 miles per year, so the pattern is less clear there. |
| Q6 | Inconclusive. With 2020 prices in August 2026 dollars (all-items CPI-U), the weighted average rose from $34,927 to $37,448, a real increase of $2,521 against a $2,000 threshold. Restricting both periods to dealers present in both gives nearly the same figure: $29,972 to $32,439, +$2,467. But the dealer-level uncertainty is far wider than the margin: 95% CI -$2,318 to +$12,059 (pre-registered) and -$3,479 to +$4,260 (same dealer), with 42% and 63% of resamples below the threshold. The data cannot confirm the threshold, or even that real prices rose. Each zip's average rests on a handful of dealers, and redrawing which few stores are in a zip moves the result by thousands of dollars. |

--

## Limitations

Both datasets are live lot inventory snapshots, not sales records. Neither reflects completed transactions.

Franchise dealer status is verified ground truth on the 2020 side, with confirmed corrections applied where the flag was wrong. On the current period side it is partially inferred through name matching, manual review, local market knowledge, and a manufacturer-name heuristic rather than individual verification against each manufacturer's own dealer locator. This is a stated tradeoff of coverage over per-dealer rigor, judged appropriate at portfolio scale. Location, unlike franchise status, was verified: every override dealer was confirmed against either its 2020 record in a study zip or its current street address.

The 2026 sample covers only part of the franchise market. The pull was capped at 25 API calls per zip, and 11 of the 15 zips hit that cap. Dealers holding 47% of the 2020 listings do not appear in the 2026 pull at all, and 33% of 2026 listings come from stores with no 2020 counterpart in the data. A 2020 dealer missing from 2026 may have closed or may simply not have been sampled; the data cannot tell which. The same-dealer comparisons restrict both periods to dealers observed in both, which removes dealer mix as an explanation for the results.

Within each capped zip, auto.dev returned the 500 most recently updated listings (its default sort), and the rest were cut off. Among captured listings, the most recently created ones are older, higher-mileage, and cheaper, so the cut-off listings were likely newer, lower-mileage, and pricier. If so, 2026 age and mileage are overstated and 2026 price is understated. That bias works against every finding: it would make the Q4 and Q5 increases smaller and the Q6 increase larger. The inference uses listing creation date as a stand-in for update date, because the pull did not capture `updatedAt`.

The 2020 data is missing some franchise stores that were operating at the time. No Nalley store appears anywhere in the 2020 data, and several others in the study zips (Jim Ellis Hyundai, Jim Ellis Buick GMC, Ed Voyles Acura, BMW of Gwinnett Place, among others) are absent as well. The cause cannot be determined from the data. The same-dealer comparisons exclude these stores.

Confidence intervals come from a dealer-level cluster bootstrap. Six of the 14 zips have two dealers or fewer in at least one period, and in the same-dealer comparison six zips have a single continuing dealer on each side. A single-dealer group contributes no variation to the bootstrap, so the true uncertainty is likely wider than the intervals shown, and a bootstrap with few clusters per group gives approximate intervals. A few stores appear under two dealer IDs in the 2026 data (for example Global BMW), which slightly overstates the dealer count in those zips.

Q4, Q5, and Q6 were judged against pre-registered practical thresholds. The pre-registered comparison is reported as primary, with the same-dealer comparison and the confidence intervals as tests of its robustness, rather than choosing whichever version reads best after the fact.

auto.dev's scraped zip field was NULL on more than half of all pulled rows, across nearly every target city. searchZip, the zip used to generate each API call, was fully populated and used as the geography field of record instead.

49 VINs appeared under more than one searchZip due to overlapping 2 mile radius searches on neighboring zips. Resolved to one row per VIN using a confirmed dealer zip where available, falling back to each dealer's single most common searchZip otherwise. The fallback is an assumption, not a verified address, for any dealer without a manual override.

z-scores used to screen for zip level price outliers were calculated on n=16 zip level averages. This is a directional screening tool, not a statistically rigorous outlier test at that sample size.

Current period sampling is equal weighted across zips (25 API calls each) rather than proportional to real market size, due to a monthly call budget. Both periods are weighted by fixed 2020 listing share, so differences in how many listings each zip returned do not drive the pooled results.

Vehicle age is calculated from model year only (snapshot year minus model year), so it is measured in whole-year steps at the listing level. The 2020 crawl window was confirmed as September 9 to 17, which supports a flat 2020 snapshot year.

Mileage is missing (NULL) on 99 of 8,630 2020 rows and 34 of 3,041 2026 rows, about 1% on each side, and those rows are excluded from the mileage averages. In 2020, all 25 missing values in 30339 belong to Global Imports BMW, the only franchise dealer in that zip, leaving its average based on 173 of 198 listings. No zero-mileage placeholder values were found in either table.

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

searchZip records which radius search returned a listing, not where the dealer is. A dealer just outside a study zip can appear under that zip's searchZip. Any dealer admitted by manual override must have its location confirmed by a 2020 record in a study zip or by its street address. The address audit removed five dealers this way.

A join used only to test whether a match exists will repeat rows when there are several matches. Courtesy Ford appears under three name variants in the 2020 data, and the JOIN version of the franchise match returned each of its 2026 listings two or three times. EXISTS answers yes or no and cannot multiply rows. After any rebuild, COUNT(*) should equal COUNT(DISTINCT vin).

An average is sensitive to who is in the population, not just to what each member does. Price moved far more than age or mileage when the 2026 dealer mix changed. Rerunning a result with the population held constant separates real change from composition change. Holding it constant means restricting both periods, not just one: an early version of the same-dealer run filtered only the 2026 side, compared it against every 2020 dealer, and reported a real price decline of $2,488. Restricting both sides reversed it to an increase of $2,467.

A point estimate that clears a threshold is not the same as a result that clears it. Q6 cleared $2,000 by about $500, but a dealer-level bootstrap put the plausible range from a real decline to a large increase. Resampling whole dealers rather than individual listings matters: listings from one store share its pricing policy and are not independent.

A table built with CREATE TABLE IF NOT EXISTS followed by a separate INSERT appends its rows again every time the script is rerun. `cars_2020_fltrd` reached 17,444 rows this way, each VIN exactly twice. Averages were unaffected because every row doubled evenly, which is why it went unnoticed. Every pipeline script now uses CREATE OR REPLACE TABLE, and COUNT(*) against COUNT(DISTINCT key) is the check after any rebuild.

--

## Files

| File | Description |
|------|-------------|
| `docs/methodology.md` | Full decision log: zip selection and screening, every exclusion and substitution, data corrections, sampling design, second-wave franchise recovery, weighted pooling |
| `sql/00_schema_reference.sql` | Column reference for both data sources, key fields to use and avoid |
| `sql/q1_zip_selection_screening.sql` | Full zip selection process: 16-candidate pool, outlier screen, Jonesboro-to-Morrow substitution, final 15-zip set |
| `sql/q2_franchise_flag_reliability.sql` | Spot-check method for the 2020 franchise_dealer flag, confirmed error and false-alarm findings |
| `sql/q2_franchise_flag_reliability_2020.sql` | 2020-side flag reliability checks feeding the 2020 reconciled population |
| `sql/q3a_franchise_overrides.sql` | Manual dealer corrections table: 29 dealers grouped as original unmatched, rebrand, relocation, absent from 2020 data, market entry, or used-car-brand judgment call, with verified locations, the six radius-overspill exclusions, and deliberately excluded dealers recorded |
| `sql/q3a_franchise_overrides_2020.sql` | 2020-side corrections: Southern Star Automotive flag error, Courtesy Ford name variants consolidated, outputs `overrides_2020` |
| `sql/q3b_current_period_cleaning.sql` | NULL zip diagnostic, cross-zip VIN duplication resolution, outputs `cars_2026_clean` |
| `sql/q3c_final_matched_dataset.sql` | 2020 franchise match (EXISTS, one row per listing) plus overrides, zip-membership filter, disposition checkpoint, outputs `final_matched` (3,041 rows) |
| `sql/q3c_final_filtered_2020.sql` | 2020 reconciled population (franchise, used only, 15 zips, VIN-unique), rebuilt with CREATE OR REPLACE, outputs `cars_2020_fltrd` (8,722 rows) |
| `sql/q3d_zip_weights.sql` | Fixed zip weights from 2020 listing share, outputs `zip_weights`, shared by Q4-Q6 |
| `sql/q4_weighted_avg_age.sql` | Weighted average age comparison, 30062 excluded from both periods, 14 weights renormalized; pre-registered test plus same-dealer run |
| `sql/q5_weighted_avg_mileage.sql` | Weighted average mileage comparison, same weighting and exclusions as Q4; pre-registered test plus same-dealer run |
| `sql/q6_weighted_avg_price.sql` | Weighted real price comparison (all-items CPI-U, August to August); pre-registered test plus same-dealer run |
| `python/00_pull_listing.py` | auto.dev API pull: 15 zips, 2 mile radius, used only, 25 calls per zip (375 total), default sort |
| `python/q4_q6_bootstrap.py` | Dealer-level cluster bootstrap: 95% confidence intervals for age, mileage, and real price, both comparisons; reproduces the SQL point estimates before resampling |
| `data/README.md` | Raw data file locations |

--

## Tools

SQL (DuckDB), persistent database (`data/08_cars.duckdb`). Weighted pooling and the CPI adjustment are done in SQL. Python (pandas, NumPy) for the API pull and the bootstrap. Tableau planned for visuals, not yet built.

--

## Status

Zip selection and flag reliability (Q1, Q2): Complete
Franchise and zip resolution (Q3): Complete, including second-wave recovery and 2020-side reconciliation
Weighted age comparison (Q4): Complete, threshold not met (high confidence)
Weighted mileage comparison (Q5): Complete, threshold not met (high confidence)
Weighted price comparison (Q6): Complete, inconclusive (point estimate above threshold, confidence interval spans it)
Sampling-cap check and bootstrap confidence intervals: Complete
Visuals (Tableau): Not started