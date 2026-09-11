# Metro Atlanta Used-Car Inventory Study

## What this project is

A hypothesis-driven comparison of franchise-dealer used-vehicle inventory in metro Atlanta, testing whether dealer offerings have shifted toward lower quality (older, higher-mileage, pricier) between **September 2020** and the **current period (Sept 2026)**.

**This is deliberately framed as "September 2020 vs. current," not "pre-COVID vs. post-COVID."** The pandemic's supply-chain effects were already underway by September 2020, so that snapshot is not a clean undisturbed baseline. See `docs/methodology.md` for the full reasoning.

## Hypotheses

Three independent tests, each with a pre-registered practical-significance threshold (set before results were seen, to avoid post-hoc rationalization):

| Metric | H₀ | Threshold for "meaningful" |
|---|---|---|
| Age | Mean vehicle age unchanged | ≥ 18 months increase |
| Mileage | Mean mileage unchanged | ≥ 15,000 miles increase |
| Price | Mean inflation-adjusted price unchanged | ≥ $2,000 increase |

Metrics are pooled **metro-wide**, using 2020 zip-level listing volume as fixed weights applied to both periods — this avoids conflating a real market shift with an artifact of the two periods having different sampling designs (2020 = natural volume; current period = deliberately equal-weighted across zips).

## Project status (as of this writeup)

- ✅ Zip/city selection finalized and fully traced (see `docs/methodology.md`)
- ✅ 2020 data cleaned (new/used contamination, city-label mismatches, ZIP+4 formatting)
- ✅ Current-period data pulled (auto.dev, ~6,549 raw listings across 15 zips)
- ✅ Current-period data cleaned (NULL-zip issue resolved via `searchZip`, cross-zip VIN duplicates identified and resolved)
- ✅ Franchise-dealer status cross-referenced between periods; manual overrides applied for unmatched/mislabeled dealers
- ⬜ **Not yet done:** final weighted comparison calculation, inflation adjustment, hypothesis test execution, write-up/visualization

## Folder structure

```
metro_atlanta_used_car_study/
├── README.md                          — this file
├── docs/
│   └── methodology.md                 — full decision log: zip selection, exclusions, corrections
├── sql/
│   ├── 01_schema_reference.sql        — DESCRIBE output for both data sources
│   ├── 02_zip_selection_screening.sql — zip candidate testing, franchise/used filters
│   ├── 03_outlier_zscore.sql          — price outlier screen (±2 SD threshold)
│   ├── 04_franchise_overrides.sql     — manual dealer corrections (create + seed data)
│   ├── 05_current_period_cleaning.sql — NULL-zip fix, cross-zip VIN dedup
│   └── 06_final_matched_dataset.sql   — combined join: franchise status + zip, both periods
└── data/
    └── README.md                      — file locations (raw data not stored in repo — too large)
```

## Data sources

| Period | File | Location |
|---|---|---|
| Sept 2020 | `used_cars_data.csv` (Kaggle, CarGurus crawl, ~3M rows) | `C:\Users\jglen\Downloads\archive (3)\` |
| Current | `atlanta_listings_2026-09-10.csv` (auto.dev API pull) | `C:/users/jglen/analytics_portfolio/08_cars/` |

## Known limitations (carry into the write-up)

- Sept 2020 baseline is early-pandemic, not true pre-COVID.
- Price comparison requires CPI adjustment — flagged, not yet executed.
- Both datasets are live-lot snapshots (right-censored), not sales records.
- "Degradation" is the thesis under test, not an assumed conclusion — a supply-constraint story is equally consistent with the same data.
- Franchise-dealer status is verified ground truth on the 2020 side (with a small number of confirmed corrections) but partially inferred (name-match + manual review) on the current-period side.
- One dealer (Nalley Lexus Smyrna) was found via radius-search overspill and excluded — its real location (30080) falls outside the 15-zip study area. Other current-period zip assignments rely on `searchZip`, not independently confirmed addresses, except where noted.

## Next step

Build the 2020-weighted pooled comparison (age, mileage, price) across both periods, apply the CPI adjustment to price, and test each metric against its threshold. See `docs/methodology.md` §10 for full context before starting.