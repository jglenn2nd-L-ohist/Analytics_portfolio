# Metro Atlanta Franchise Used-Car Inventory, September 2020 vs. September 2026

**Technical write-up** | J. Glenn | September 2026
**Dashboard:** [Tableau Public](https://public.tableau.com/views/MetroAtlantaPre-OwnedCarAnalysisSept2020-Sept2026/MetroAtlantaused-carstudy) | **Full decision log:** `docs/methodology.md`

---

## Summary

The question was whether franchise dealers in metro Atlanta now offer older, higher-mileage used cars at higher real prices than they did in September 2020. Three thresholds were set before any results were seen: +18 months of age, +15,000 miles, and +$2,000 in inflation-adjusted price.

| Metric | Change | 95% confidence interval | Threshold | Verdict |
|---|---|---|---|---|
| Age | +5.3 months | 1.0 to 10.1 | +18 months | Not met, high confidence |
| Mileage | +5,883 miles | 1,637 to 11,620 | +15,000 miles | Not met, high confidence |
| Real price | +$2,521 | -$2,318 to +$12,059 | +$2,000 | Inconclusive |

Inventory is measurably older and has more miles, but both changes are far smaller than hypothesized. The price estimate sits just above its threshold, but the dealer-level uncertainty runs from a real decline to a large increase, so the data cannot confirm it. An audit of the data during the analysis cut the headline price figure from +$5,624 to +$2,521 before the uncertainty was even measured.

---

## 1. Data

| Period | Source | Scope after filtering |
|---|---|---|
| September 2020 | Kaggle CarGurus crawl, about 3M U.S. listings, crawled September 9 to 17, 2020 | 8,722 franchise, used-only listings in the study zips |
| September 2026 | auto.dev API, pulled September 10, 2026 | 3,041 franchise, used-only listings in the study zips |

Both are live-lot inventory snapshots, not sales records. The 2020 source has a verified `franchise_dealer` flag. The 2026 source has no franchise flag and no reliable zip field, so both had to be reconstructed.

**Framing:** September 2020 was already six months into pandemic supply disruption, so the comparison is framed as September 2020 vs. current, not pre-COVID vs. post-COVID.

---

## 2. Study design

**Geography.** Zip code, not city name, is the geography key. The 2020 source has no state column, and city labels are inconsistent (30341 appears as both "Atlanta" and "Chamblee"). Sixteen candidate zips were screened for franchise volume in both periods and for price outliers (z-score on zip-level averages). Doraville (30360) was excluded as an outlier, and Jonesboro (30236) was replaced by Morrow (30260) after its 2026 pull returned only 8 listings. Fifteen zips were finalized. One of them, 30062, was later excluded from the comparisons because its only 2020 franchise dealer relocated to 30060, leaving it with no 2026 listings. The remaining 14 zips carry the analysis.

**Weighting.** The 2026 pull allocated a flat 25 API calls per zip, so its listing counts reflect the call budget, not market size. Both periods are therefore pooled with fixed weights equal to each zip's share of the 2020 listing population, renormalized over the 14 zips. Zip averages are computed first and then weighted, so no zip's listing volume is counted twice.

**Inflation.** 2020 prices are converted to August 2026 dollars with the all-items CPI-U (259.918 to 334.980, a ratio of about 1.289). The used-cars-and-trucks CPI was deliberately not used: it measures used-car price change, which is the thing being tested, so deflating by it would remove the effect by construction. August was used on both ends because September 2026 CPI had not been published, and matching months gives an exact 72-month span.

**Pre-registration.** The three thresholds were fixed before any comparison was run. The pre-registered comparison is reported as the primary result throughout, and every later check is presented as a test of it, not a replacement for it.

---

## 3. Pipeline

```
CSV files ──> DuckDB base tables ──> cleaning and matching ──> analysis queries ──> bootstrap ──> dashboard exports ──> Tableau
             cars_2020, cars_2026    SQL (q2, q3a to q3d)       SQL (q4 to q6)      Python        SQL                  display only
```

All data rules live in SQL: the franchise match, the overrides, the CPI conversion, the price floor, and the exclusions. Python only resamples. Tableau only displays exported results. Every calculation therefore exists in exactly one place.

| Table | Built by | Contents |
|---|---|---|
| `cars_2020_fltrd` | `q3c_final_filtered_2020.sql` | 8,722 reconciled 2020 listings, one per VIN |
| `zip_weights` | `q3d_zip_weights.sql` | 2020 listing share per zip |
| `franchise_overrides` | `q3a_franchise_overrides.sql` | 29 manually verified 2026 dealers |
| `cars_2026_clean` | `q3b_current_period_cleaning.sql` | 6,498 2026 listings after VIN deduplication |
| `final_matched` | `q3c_final_matched_dataset.sql` | 3,041 2026 franchise listings in the study zips, one per VIN |

**Reconstructing franchise status for 2026.** Each 2026 listing is matched to the 2020 data by dealer name and zip, using case-insensitive substring matching in both directions, since dealer names drift over time ("Palmer Dodge" vs. "Palmer Dodge Chrysler Jeep Ram"). Dealers the automated match cannot place enter only through `franchise_overrides`, where each one is classified (rebrand, relocation, market entry, or store missing from the 2020 data) and its location verified against either its 2020 record or its current street address. The match is written with `EXISTS` rather than a join, for the reason in section 4.

---

## 4. The audit: what the data got wrong, and what it cost

Most of the project's effort went into finding problems that did not announce themselves. Each row below produced no error message. Every one was found by a check.

| Problem | How it was found | Effect |
|---|---|---|
| Five override dealers were outside the study area. The 2026 pull searched a 2 mile radius around each zip, so dealers just across a zip boundary were tagged with a study zip. | Name search of the full 2020 data across all zips, then a street address check of every override dealer | Two luxury stores (Porsche Atlanta Perimeter, Mercedes-Benz of Atlanta South) had inflated the 2026 price average. Removing the five cut the price result from +$5,624 to +$2,570. |
| One dealer's listings were duplicated two or three times. Courtesy Ford has three name variants in 2020, and a join returns one row per match. | `COUNT(*)` vs. `COUNT(DISTINCT vin)` after a rebuild: 3,138 vs. 3,024 | 114 duplicate rows. Fixed by replacing the join with `EXISTS`, which answers yes or no and cannot multiply rows. |
| The 2020 population was stored twice (17,444 rows, each VIN exactly twice). A script created the table with `CREATE TABLE IF NOT EXISTS` and then ran a separate `INSERT`, so a rerun appended everything again. | Row count vs. distinct VINs | None, because every row doubled evenly and averages were unchanged. Every script now uses `CREATE OR REPLACE`. |
| Most "market entries" were not new. Of 20 dealers classified as new since 2020, most had existed under older names or were simply missing from the 2020 data. | Review of each dealer with local market knowledge | No change to results, but the record and the same-dealer comparison both depended on the correct classification. |
| 11 listings had placeholder prices under $1,000 (a 2025 Range Rover, a 2025 RAV4). | Low-price scan, then the vehicles themselves | Excluded from price with a symmetric $1,000 floor. |

The headline price figure moved at each stage of the audit:

| Stage | Real price change |
|---|---|
| Initial build | +$5,624 |
| Radius-overspill dealers removed | +$2,570 |
| EchoPark added (final dealer review) | +$2,521 |

---

## 5. Robustness checks

### Same-dealer comparison

The 2026 pull did not capture the whole market. Dealers holding 47% of the 2020 listings do not appear in the 2026 pull at all, and 33% of 2026 listings come from stores with no 2020 counterpart. Dealer mix could therefore drive the results.

The same-dealer comparison restricts **both** periods to dealers observed in both snapshots. An early version restricted only the 2026 side and compared it against every 2020 dealer. It reported a real price decline of $2,488. The 2020 dealers missing from 2026 had skewed pricier, so leaving them in made continuing dealers look like they cut prices. Restricting both sides reversed the result to +$2,467. That error is recorded in the methodology because it is the easiest one in the project to make.

| Metric | Pre-registered | Same dealer |
|---|---|---|
| Age | +5.31 months | +7.03 months |
| Mileage | +5,883 miles | +3,751 miles |
| Real price | +$2,521 | +$2,467 |

The two comparisons agree in direction on every metric, and on price they agree within $54. Composition effects are large on both sides but largely cancel.

### Sampling cap and sort order

In 11 of the 15 zips, the pull hit its 25-call cap, so the API chose which listings were returned. The pull set no sort parameter, and auto.dev's default is most recently updated first. Within the capped zips, the most recently created listings are older, higher-mileage, and cheaper:

| Recency quartile | Avg age | Avg miles | Avg price |
|---|---|---|---|
| 1 (most recent) | 3.86 | 51,644 | $33,784 |
| 4 (oldest captured) | 2.61 | 42,822 | $41,153 |

If that trend continues past the cut, the listings not returned were newer, lower-mileage, and pricier. The 2026 sample would then overstate age and mileage and understate price. That bias works against every finding: it would shrink the Q4 and Q5 increases and enlarge the Q6 increase. The pull did not capture `updatedAt`, so creation date stands in for update date, and this is an inference, not a measurement.

### Confidence intervals

A point estimate that clears a threshold by $500 is not the same as a result that clears it. Intervals came from a dealer-level cluster bootstrap (`python/q4_q6_bootstrap.py`):

- Within each zip and period, dealers are redrawn with replacement, taking all of a drawn dealer's listings. Listings from one store share its pricing policy, so resampling individual listings would treat them as independent and make the intervals too narrow.
- Every resample keeps all 28 zip-period groups and the fixed weights, mirroring how the point estimate is built.
- 2,000 resamples per metric per comparison, with a fixed seed.
- Before any interval was computed, the Python point estimates were confirmed to reproduce the SQL results exactly.

| Metric | Comparison | Point | 95% CI | Share of resamples below threshold |
|---|---|---|---|---|
| Age (months) | Pre-registered | +5.3 | 1.0 to 10.1 | 100.0% |
| Age (months) | Same dealer | +7.0 | 2.7 to 25.9 | 75.2% |
| Mileage | Pre-registered | +5,883 | 1,637 to 11,620 | 99.7% |
| Mileage | Same dealer | +3,751 | 625 to 23,990 | 75.0% |
| Real price | Pre-registered | +$2,521 | -$2,318 to +$12,059 | 42.0% |
| Real price | Same dealer | +$2,467 | -$3,479 to +$4,260 | 63.4% |

The price intervals are wide because each zip's average rests on a handful of dealers. Six of the 14 zips have two dealers or fewer in at least one period, and redrawing which few stores are in a zip moves its average by thousands of dollars. The same-dealer intervals are wider still, because six zips have a single continuing dealer on each side. The same-dealer run confirms that the point estimates are not a composition artifact, but it is too thin to test thresholds on its own.

---

## 6. Limitations

- **Snapshots, not sales.** Both sources show what was on lots, not what sold or at what price.
- **Partial 2026 coverage.** The call cap and the API's sort order shaped which 2026 listings were captured. The likely bias works against the findings, but its size is unknown.
- **Missing 2020 dealers.** No Nalley store appears anywhere in the 2020 data, and several other operating stores are absent. The cause cannot be determined.
- **Inferred franchise status.** Franchise status for 2026 override dealers relies on name matching, manual review, and local knowledge, not each manufacturer's dealer locator. Their locations, unlike their status, were verified.
- **Approximate intervals.** Single-dealer zips contribute no variation to the bootstrap, so the true uncertainty is likely wider than shown.
- **Whole-year age.** Age is snapshot year minus model year, so it moves in whole-year steps at the listing level.

---

## 7. What I would do next

- **Pull the full market.** A pull without the call cap, or proportional to market size, would remove the sampling-cap question entirely. Capturing `updatedAt` would turn the sort-order inference into a measurement.
- **Widen the geography.** More zips means more dealers per stratum, which is what the price uncertainty needs most.
- **Model dealers directly.** A multilevel model with dealers nested in zips would use the dealer structure more efficiently than a bootstrap and handle thin zips more gracefully.
- **Add transaction data.** Sale prices and days on lot would answer what buyers actually paid, not just what dealers asked.

---

## 8. Technical lessons

1. **A join that only tests for a match will multiply rows when there are several matches.** Use `EXISTS` for existence tests, and check `COUNT(*)` against `COUNT(DISTINCT key)` after every rebuild.
2. **A search radius is not an address.** Any record admitted by manual override needs its location verified independently.
3. **Hold the population constant on both sides.** Restricting only one period to continuing dealers produced a finding with the wrong sign.
4. **Measure uncertainty before declaring a threshold met.** The price estimate cleared its threshold in every comparison and still could not be confirmed.
5. **Rerunnable scripts must rebuild, not append.** `CREATE OR REPLACE` makes a rerun safe. `CREATE TABLE IF NOT EXISTS` plus `INSERT` does not.
6. **Reproduce before extending.** The bootstrap was trusted only after it matched the SQL point estimates exactly.

---

## Reproducing the analysis

Raw CSVs go in `data/`. The base tables `cars_2020` and `cars_2026` are loaded with `read_csv()` into `data/08_cars.duckdb`. Then, in order:

1. `sql/q3a_franchise_overrides_2020.sql`, then `sql/q3c_final_filtered_2020.sql`, then `sql/q3d_zip_weights.sql` (2020 side)
2. `sql/q3a_franchise_overrides.sql`, then `sql/q3b_current_period_cleaning.sql`, then `sql/q3c_final_matched_dataset.sql` (2026 side)
3. `sql/q4_weighted_avg_age.sql`, `sql/q5_weighted_avg_mileage.sql`, `sql/q6_weighted_avg_price.sql`
4. `python/q4_q6_bootstrap.py`
5. `sql/tableau_exports.sql`

Every table-building script uses `CREATE OR REPLACE`, so any step can be rerun safely. After step 2, `COUNT(*)` and `COUNT(DISTINCT vin)` on `final_matched` should both be 3,041.
