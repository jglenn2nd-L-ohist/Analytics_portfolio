# Metro Atlanta Used-Car Inventory Study: Methodology Log

**Purpose:** Compare franchise-dealer used-vehicle inventory (age, mileage, price) in metro Atlanta between a September 2020 snapshot and a current-period pull, to test whether dealer offerings have changed ("quality degradation" thesis).

This document exists as a teaching/reference log. It captures not just the final decisions, but the mistakes caught along the way, since the corrections are as instructive as the conclusions.

---

## 1. Data Sources

| Period | Source | Method |
|---|---|---|
| Pre/early-COVID | Kaggle "US Used Cars Dataset", CarGurus crawl, **September 2020**, ~3M rows | Static CSV, queried via DuckDB |
| Current | auto.dev API | Live pull, radius search per zip, 1,000 calls/month cap |

**Framing correction made early on:** September 2020 is *not* a clean pre-COVID baseline. The pandemic began disrupting the auto supply chain (trade-ins, auctions, production) starting March 2020. The project is framed as **"September 2020 vs. current," not "pre-COVID vs. post-COVID."** If anything, this makes a finding of degradation a *conservative* estimate, since the true pre-pandemic baseline was likely even better than the September 2020 snapshot shows.

---

## 2. City & Zip Code Selection

### Original candidate cities (for geographic dispersion around metro Atlanta):
Duluth, Marietta, Alpharetta, Conyers, Douglasville, Stockbridge, Lithonia, Buford, Kennesaw, Stone Mountain.

### Key correction #1: city name ≠ unique location
This is a nationwide dataset with no `state` column. City names like "Marietta" exist in multiple states. **Zip code, not city name, is the only reliable geographic filter.**

### Key correction #2: city labels in the raw data are inconsistent
Testing zip-only (no city filter) revealed:
- Zip 30038 (Lithonia) appears in the data under **"Stonecrest"** (a newer incorporated city that absorbed the area in 2017).
- Zip 30341 appears under both **"Atlanta"** and **"Chamblee."**
- Several zips near the Perimeter appear generically as "Atlanta" (30341, 30360, 30339), which obscures real sub-market differences (Chamblee, Doraville, Vinings respectively).

**Fix:** Verified each ambiguous zip's actual common name via independent search (zip-codes.com, USPS alias data), then hardcoded a `CASE WHEN dealer_zip = 'X' THEN 'RealName' ELSE city END AS display_city`, a per-zip label, not a guess from an aggregate function.

**Pitfall caught along the way:** `MAX(city)` was tried as a shortcut to auto-resolve label conflicts. It happened to return "Chamblee" for 30341, but only because "Chamblee" sorts alphabetically after "Atlanta." `MAX()` on a text column is alphabetical, not "most accurate." It got lucky once; it is not a reliable method and was replaced with explicit `CASE WHEN` mapping.

### Key correction #3: zero-result cities are real findings, not errors
Douglasville and Stockbridge returned **zero** franchise-dealer listings even after removing the city filter and testing their zips directly. Confirmed as a genuine feature of the September 2020 sample, not a data-matching bug.

### Substitutions made (with reasoning trail)
- Stone Mountain → **Union City (30291)**: chosen for more southern geographic exposure.
- Douglasville / Stockbridge (zero data) → **Jonesboro (30236)**: direct outer-suburb replacement.
- Generic "Atlanta" zips → evaluated individually by character, not lumped as one city:
  - 30341 → **Chamblee** (international corridor / Buford Hwy commercial nexus): kept.
  - 30360 → **Doraville**: later **excluded** (see outlier screening below).
  - 30339 → **Vinings** (Cumberland/Battery corridor): flagged as possibly too commercial/affluent to match the suburban-residential character of the rest of the set; tested rather than excluded on impression alone. Retained (see below).
- Jonesboro (30236) → **Morrow (30260)**: Jonesboro's *current-period* pull returned only 8 listings (see sampling section); before swapping, Morrow was independently tested against the **2020 CSV** (not just assumed to qualify) and passed cleanly: 800 franchise/used listings, price/mileage/year all within the existing distribution, no city-label ambiguity.

---

## 3. Data-Integrity Corrections (SQL lessons)

1. **`LIKE '30%%%'`**: the extra `%` characters are redundant; a single `%` already matches any number of characters.
2. **New vs. used contamination**: an early query omitted `is_new = false`. This mixed new-vehicle inventory (near-zero mileage, current model year, MSRP-level pricing) into what was meant to be a used-only comparison, distorting every downstream average. All queries after this point explicitly filter `is_new = false`.
3. **`GROUP BY city, dealer_zip` silently double-counts a zip** when that zip has more than one raw city label in the source data (e.g., 30341 under "Atlanta" and "Chamblee" produced two separate rows instead of one combined zip-level average). Fix: group by `display_city, dealer_zip` (the *derived, deterministic* label) once the raw label is no longer being used directly.
4. **SQL aggregate rule:** once a column is not in `GROUP BY`, it must be wrapped in an aggregate function (`MAX()`, `AVG()`, etc.) or referenced through a `CASE` that resolves deterministically. SQL will not "pick one" for you silently, and if it does resolve (as with `MAX()`), the resolution logic may not mean what you assume.

---

## 4. Outlier Screening (Price)

**Method:** z-score on average price per zip, using the 16-zip candidate set (n=16 zip-level averages).

**Threshold:** |z| > 2 → exclude.

**Result:**
- **30360 (Doraville): z ≈ 2.70 → excluded.**
- 30339 (Vinings): z ≈ 1.45 → retained, but flagged as the second-highest z-score in the set: a near-miss, not a comfortable retain. Documented explicitly rather than silently kept.

**Caveat documented for the write-up:** z-scores and the ±2 convention assume a reasonably large, roughly normal distribution. With only 16 zip-level data points, a single unusual value can distort the mean/SD used to judge everything else. This method is used here as a **directional screening tool**, not a statistically rigorous outlier test, stated explicitly to avoid overclaiming precision.

---

## 5. Sample Size / Reliability Checks

- **Small-n zips are not automatically unreliable.** The real test is distribution shape, not row count alone. For a thin zip (30094, n=140), checked median vs. mean of mileage: 33,518 vs. 36,603, only ~9% apart, meaning the elevated average wasn't being driven by a handful of extreme outliers. Retained.
- **Contrast case: 30236 (Jonesboro) current-period pull returned only 8 listings** from a single API call that came back short of a full page. This was read as evidence the zip's real current inventory is nearly exhausted (a population ceiling), not an artifact of stopping early. At n=8, no meaningful median/mean skew check is possible. This zip was replaced (see Morrow substitution above) rather than kept with a caveat, since the sample was judged too thin to support any average.

---

## 6. Current-Period Sampling Design (auto.dev)

- **Budget constraint discovered mid-project:** auto.dev caps at 1,000 **API calls**/month, not 1,000 listings. Each call returns roughly 20 listings.
- **Equal-weighting goal:** since the pre-COVID side was designed so no single zip's raw volume would dominate the comparison, the intent was to sample the current period with the same zip set, comparably.
- **"Water-filling" problem encountered:** an attempt to combine a minimum-floor-per-zip with proportional distribution of the remainder caused zips to fall below the floor in multiple cascading passes as the "remainder pool" shrank. Simpler resolution chosen: **flat call allocation per zip** (25 calls/zip; 15 zips × 25 = 375 of the 1,000-call budget), accepting that this produces equal *effort* per zip, not necessarily equal *listings*, since some zips exhaust their available current inventory well before 25 calls (e.g., Union City plateaued around 140 listings at just 8 calls in an early test), while others (Duluth) were still climbing past 1,300 at 66 calls in testing.
- **Result:** 11 of 15 zips returned exactly 500 listings (25 calls × 20 per call), meaning they hit the cap. Four ran out of inventory first: 30012 (89), 30013 (151), 30067 (321), and 30094 (488). An earlier version of this log said 10 of 15. The cap turned out to matter for more than sample size; see sec. 17.

---

## 7. Franchise-Dealer Identification (Current-Period Data)

The auto.dev schema (`vin`, `year`, `make`, `model`, `price`, `miles`, `dealer`, `dealerId`, `createdAt`, plus a zip field) has **no franchise/independent flag**, unlike the 2020 CSV's clean `franchise_dealer` boolean.

**Method chosen:** since franchise status is tied to the *dealer*, not each individual listing, verification only needs to happen once per unique `dealer`/`dealerId` (a manageable list of dozens, not hundreds of rows) rather than per listing:
1. Name-match first pass (dealer name contains a recognizable brand).
2. Manual verification for anything ambiguous, cross-checked against the manufacturer's own dealer locator, since some real franchise dealers (e.g., "RBM of Atlanta" for Mercedes-Benz) don't contain the brand name, and some independent lots use brand-adjacent names.

**Documented asymmetry:** the 2020 side has verified ground-truth franchise status; the current side relies on inference. This is a stated limitation, not a hidden one.

---

## 8. Geographic Precision Note

auto.dev's search is **radius-based (2-mile radius per zip centroid)**, not an exact zip match like the CSV's `dealer_zip` field. The original plan was to filter results down to the exact target zip using the scraped zip field returned with each listing.

**Superseded:** during cleaning, the scraped zip field was found to be NULL on over half of all rows (see sec. 10). `searchZip`, the zip used to generate each API call, is used as the geography field instead. Radius overspill is handled through VIN deduplication and dealer-level corrections (sec. 10 and 12), not exact zip filtering.

---

## 9. Final Zip Set (15 zips)

| Zip | Display City | Notes |
|---|---|---|
| 30096 | Duluth | original |
| 30291 | Union City | swapped in for Stone Mountain (southern exposure) |
| 30519, 30518 | Buford | original |
| 30144 | Kennesaw | original |
| 30060, 30067, 30062 | Marietta | narrowed from 7 candidate zips to the 3 with actual franchise-dealer volume |
| 30009 | Alpharetta | original |
| 30013, 30012, 30094 | Conyers | original |
| 30341 | Chamblee | corrected from generic "Atlanta" label |
| 30339 | Vinings | corrected from generic "Atlanta" label; retained after z-score check (z≈1.45, near-miss) |
| 30260 | Morrow | swapped in for Jonesboro (30236), which was itself a swap for Douglasville/Stockbridge (zero 2020 data) |

**Excluded:** 30360 (Doraville): price outlier (z≈2.70). 30236 (Jonesboro): insufficient current-period sample (n=8).

**Correction:** an earlier version of this table listed Alpharetta as 30009 and 30004. 30004 was never in the candidate pool (`sql/q1_zip_selection_screening.sql`) and was never screened, sampled, or weighted. The table now matches the zip set used in every query.

---

## 10. Post-Pull Cleaning (Current-Period Data)

After the initial ~6,549-row auto.dev pull, several additional issues surfaced during cleaning:

- **NULL zips:** over half the raw pull (roughly 3,450+ rows) had a NULL scraped `zip` field, despite `city` being populated, spanning nearly every target city, not an isolated case. Root cause traced to the scraped `zip` field itself being unreliable; the API's own `searchZip` field (recording which zip-radius search produced each row) was found to be 100% populated and used as the authoritative geography field going forward instead.
- **Cross-zip VIN duplication:** 49 VINs appeared under more than one `searchZip` (max 2 zips each, 49 duplicate rows total, ~0.75% of the dataset), caused by 2-mile radius searches for neighboring zips overlapping geographically.
- **Franchise-status gap:** auto.dev's schema has no franchise/independent flag. Resolved via a join against the 2020 CSV's `sp_name` + `dealer_zip` (matched against `searchZip`), using partial/substring name matching (loosened from exact match after discovering current-period dealer names are often shortened versions of the 2020 full names, e.g., "Palmer Dodge" vs. "Palmer Dodge Chrysler Jeep Ram"). Remaining unmatched dealers (161 initially, reduced after the loosened join) required manual verification. See `sql/q3a_franchise_overrides.sql` and `sql/q2_franchise_flag_reliability.sql`.
- **Ground-truth errors found in the 2020 flag itself:** "Southern Star Automotive" was flagged `franchise_dealer = true` in the 2020 CSV despite being a known non-franchise lot, a confirmed data error, corrected via override. ("Atlanta Classic Cars," initially suspected of the same issue, was independently verified as a legitimate Mercedes-Benz franchise; the original flag was correct.)
- **Radius-search overspill:** "Nalley Lexus Smyrna" appeared under three different `searchZip` values (30339, 30291, 30009), none of which is its real location. Independently verified address: 2750 Cobb Pkwy SE, Smyrna, GA **30080**, outside the 15-zip study area. All listings tied to this dealer were excluded rather than assigned to any of the three zips it happened to appear under. A later address audit found five more dealers in the same situation (sec. 12).

## 11. Open Limitations to Carry Into the Write-Up

- September 2020 baseline is early-pandemic, not true pre-COVID, framed accordingly throughout.
- Nominal price comparison requires inflation adjustment (CPI) to avoid conflating currency devaluation with real price/quality change. Executed in Q6 with all-items CPI-U (sec. 15).
- The 2020 data is missing some franchise stores that were operating at the time, including every Nalley store (sec. 12). Their 2026 listings are counted and their 2020 inventory cannot be. The same-dealer comparisons in Q4 through Q6 exclude them.
- The 2026 sample covers only part of the franchise market, and within capped zips the API returned the most recently updated listings first (sec. 17).
- Confidence intervals are approximate and likely too narrow where zips have only one or two dealers (sec. 18).
- Both datasets are live-lot inventory snapshots (right-censored: what hasn't sold yet), not sales records. This makes them comparable to each other, but means neither reflects true transaction activity.
- "Degradation" is the stated thesis being tested, not an assumed conclusion. The data may show a supply-constraint story (fewer trade-ins/off-lease vehicles reaching dealers) as easily as a "dealers chose to lower standards" story. The data can show *that* something changed; it can't alone explain *why*.
- USPS-designated primary city ("Atlanta") differs from the colloquial names used in this analysis (Chamblee, Doraville, Vinings, Morrow), noted so the discrepancy isn't mistaken for an error if cross-checked later.
- Franchise-dealer status on the current-period side is inferred (name-match + manual verification), not a verified field, unlike the 2020 side.

---

## 12. Persistent Database Rebuild and Second-Wave Franchise Recovery

**Why a rebuild was needed:** all early DuckDB work ran in memory with no database file, so the override table and matched dataset were never saved. A persistent database (`08_cars.duckdb`) was created, with base tables `cars_2020` and `cars_2026` loaded via `read_csv()`, and the full pipeline was rerun against it.

**Crawl window check:** `listed_date + daysonmarket` places the 2020 crawl between September 9 and 17, 2020. This supports using a flat 2020 snapshot year for age calculations.

**Key correction: franchise status does not require a 2020 match.** The original method only counted a current-period dealer as franchise if it matched a 2020 record. That silently excluded genuine franchises that opened after 2020. A real 2026 franchise dealer is counted whether or not it existed in 2020.

**How the gap was found:** a disposition-breakdown checkpoint query classified every current-period row into exhaustive, non-overlapping categories by match reason. This located a block of unmatched rows belonging to real franchise dealers. This query should be the first tool used if the `final_matched` row count ever needs re-auditing.

**Second-wave additions (23 dealers):** first recorded as 1 rebrand (Group 1 Ford of Kennesaw, formerly Jim Tidwell Ford), 1 relocation within the study area (Marietta Toyota, 30062 to 30060; see sec. 13), and 20 market entries, plus AutoNation USA Kennesaw as a judgment-call entry. The market entries were confirmed as absent from the 2020 data by checking both dealer name (`sp_name`) and brand (`franchise_make`) within the study zips.

**Key correction: "absent from the 2020 data" is not the same as "new to the market."** A later review with local market knowledge found that most of the 20 "market entries" existed before 2020. Some were in the 2020 data under a prior name the name check had missed. Others were operating but missing from the 2020 data entirely. Final classification of the 23 second-wave dealers:
- **Rebrand, prior name in the 2020 data (8):** Group 1 Ford (Jim Tidwell Ford), Premier Nissan Mall of Georgia (Sutherlin Nissan), Malcolm Cunningham Chevrolet, ALM Ford Marietta (AutoNation), Kia South Atlanta, ALM GMC South, Heritage Cadillac/Mitsubishi, ALM Mazda South. Their 2020 inventory is already in the 2020 averages.
- **Relocation within the study area (1):** Marietta Toyota.
- **Operating before 2020, absent from the 2020 data (7):** Jim Ellis Buick GMC Atlanta, Jim Ellis Hyundai, Ed Voyles Acura, Nalley INFINITI of Atlanta, BMW of Gwinnett Place, Nalley Honda (a franchise conversion from Nalley Chevrolet at the same location), and Kia of Alpharetta (possibly relocated into the study area). Their 2026 listings are valid; their 2020 inventory cannot be counted.
- **True market entries (5):** Porsche Atlanta Northwest, Porsche Atlanta Northeast, Alfa Romeo of Marietta, Jim Ellis Cadillac, AutoNation USA Kennesaw.
- **Excluded as radius overspill (2):** Mike Rezi Nissan and Roswell Infiniti (see address audit below).

Genesis of Kennesaw, one of the original unmatched dealers, is also a true market entry (opened August 2024).

**Final review of unmatched 2026 dealers.** A separate check asked whether large 2020 dealers missing from the 2026 continuing set were in the 2026 pull under new names and simply unmatched. Every unmatched 2026 dealer in the study zips (166 rows) was exported and reviewed. None of the large missing 2020 dealers appeared, so their absence is a sampling gap, not a matching gap (see sec. 17). The unmatched list was almost entirely independent lots, rental and used-car chains, out-of-state strays returned by the API, and the known exclusions. Decisions from that review:
- **Added:** EchoPark Automotive, Duluth (3296 Commerce Ave NW, 30096, 17 listings), Sonic Automotive's used-car brand, on the same judgment-call basis as AutoNation USA. EchoPark's first Georgia location opened in December 2020, after the 2020 snapshot, so it is a true market entry.
- **Not added, independent:** ALM Kennesaw, ALM Mall of Georgia, ALM Marietta, Atlanta Luxury Motors Inc. ALM owns branded franchise stores (ALM Ford, ALM GMC, ALM Mazda), but these pre-owned locations are not franchises.
- **Not added, not franchise dealers:** DriveTime, Enterprise Car Sales, Hertz Car Sales, Avis Car Sales.
- **Not added, one listing each:** Audi Atlanta and Butler Chrysler Dodge Jeep, documented as known omissions. "Ed Voyles CDJR" was a single stray listing under a short name for a store already matched automatically as "Ed Voyles Chrysler Dodge Jeep."

**No Nalley store appears anywhere in the 2020 data.** This is a whole dealer group absent from one period, not scattered misses. The cause cannot be determined from the data. It affects Nalley Volkswagen, Nalley INFINITI, and Nalley Honda.

**Address audit and radius-overspill exclusions.** The `confirmed_zip` values in `franchise_overrides` had come from `searchZip`, which records which 2 mile radius search returned a listing, not where the dealer is. Only Nalley Lexus had been verified by address. Every override dealer was then checked two ways: a name search of raw `cars_2020` across all zips (no zip or franchise filter), and a current street address lookup. Five dealers are located outside the study area:

| Dealer | Override zip | Verified address |
|---|---|---|
| Porsche Atlanta Perimeter | 30341 | 4006 Carver Dr, Atlanta 30360 |
| Mike Rezi Nissan | 30341 | 4400 Motors Industrial Way, Atlanta 30360 |
| Palmer Dodge Chrysler Jeep Ram | 30009 | 11460 Alpharetta Hwy, Roswell 30076 |
| Roswell Infiniti of North Atlanta | 30009 | 11405 Alpharetta Hwy, Roswell 30076 |
| Mercedes-Benz of Atlanta South | 30291 | 3800 Royal South Pkwy, Atlanta 30349 |

Each also appears in the 2020 data at the same outside zip. The automated match had correctly rejected them because their 2020 zip did not match; the manual overrides had pulled them back in. All five were excluded by removing their override rows. A dealer with no 2020 match in a study zip can only enter `final_matched` through an override, so removing the row excludes it. This is also how Nalley Lexus had been excluded. The exclusions and their addresses are recorded in `q3a_franchise_overrides.sql`.

**Key correction: JOIN fan-out on Courtesy Ford.** The rebuild after the exclusions returned 3,138 rows but only 3,024 distinct VINs. All 114 extra rows belonged to Courtesy Ford in 30013, listed in 2026 as both "Courtesy Ford" and "Courtesy Ford Conyers." The 2020 data carries three name variants for that store. With bidirectional substring matching, the short name matched all three variants (every listing tripled) and the longer name matched two (every listing doubled). The franchise match only needs to answer whether at least one matching 2020 record exists, so the `LEFT JOIN` was replaced with `EXISTS`, which cannot multiply rows. `EXISTS` is computed in its own CTE because DuckDB does not allow a later column in the same SELECT to reference an alias whose expression contains a subquery. The previous build had recorded 3,279 rows and 3,279 distinct VINs; why the JOIN version did not duplicate Courtesy Ford in that build was not determined. The `EXISTS` version removes the risk regardless.

**Current state:** `franchise_overrides` holds 29 dealers. `final_matched` holds 3,041 rows with `COUNT(*) = COUNT(DISTINCT vin)`. The disposition checkpoint sums to 6,498 (3,457 unmatched, 1,724 rescued by override, 1,317 matched to 2020 data), equal to `cars_2026_clean`. Row history: 2,593 (original overrides), 3,279 (second wave), 3,024 (overspill exclusions and EXISTS fix), 3,041 (EchoPark added).

**Continuing dealers.** The same-dealer comparisons in Q4 through Q6 need the set of stores present in both snapshots, on both sides:
- **2026 side:** listings matched to 2020 data automatically (`csv_match = true`, carried in `final_matched`) plus the 10 override dealers with a confirmed 2020 counterpart in a study zip (Global BMW, John Miles, and the 8 rebrands).
- **2020 side:** listings whose dealer matches a 2026 `csv_match` dealer by the same name-and-zip rule, plus the 2020 names of those 10 override dealers: Global Imports BMW, John Miles Chevrolet Buick GMC, Jim Tidwell Ford, Sutherlin Nissan Mall of Georgia, Malcolm Cunningham Chevrolet North Point, AutoNation Ford Marietta, Kia Atlanta South, Heritage Cadillac Mitsubishi, and Hennessy Buick GMC Mazda plus Hennessy Mazda (the 2020 identity of ALM GMC South and ALM Mazda South, confirmed by direct knowledge).

Every automatically matched 2020 and 2026 name pair (34) was reviewed by eye. All are the same store: exact matches, capitalization differences, or longer and shorter forms of one name. Two involve ownership rebrands at the same location, confirmed by direct knowledge: Honda South to Krause Honda South, and Nissan of Union City to Bella Nissan of Union City. Two independent counts agree: the 2020 dealers outside the continuing set hold 4,077 listings in both a SQL query and the Python flag.

**Pitfall caught along the way: AND/OR precedence in the franchise join.** SQL evaluates AND before OR. With three OR'd name conditions and an AND'd zip condition, the zip requirement only applied to the last name condition. The match count inflated to the full raw total. Fix: wrap all three name conditions in parentheses before AND'ing the zip condition.

**Pitfall caught along the way: new-vehicle contamination in the lookup.** The `is_new = false` filter must be applied to `cars_2020` inside the lookup CTE, or new-vehicle listings silently inflate the 2020 comparison population.

**Repo restructure:** analyst questions were renumbered by dependency order rather than the original hypothesis-first order. `q4_outlier_zscore.sql` was merged into `q1_zip_selection_screening.sql`, and the cleaning and matching files became `q3a/b/c`. `q3b` was rewritten to implement the VIN dedup fix rather than only diagnose it.

**2020-side reconciliation:** `cars_2020` had never been filtered into a clean comparison population the way `final_matched` had for 2026. `overrides_2020` corrects two issues: Southern Star Automotive mislabeled as franchise, and Courtesy Ford appearing under three name variants for one physical location (confirmed by matching dealer zip). The result, `cars_2020_fltrd`, holds 8,722 rows, VIN-unique. `zip_weights` (15 rows, summing to 1.000) was then built from 2020 listing share as the shared input for Q4 through Q6.

---

## 13. Q4: Weighted Average Age

**Method:** Average vehicle age is computed per zip for each period, then pooled using the fixed 2020 zip weights from `zip_weights` (Q3d). Age = snapshot year minus model year (2020 for `cars_2020_fltrd`, 2026 for `final_matched`). Weighted average per period = SUM(weight x zip average age). The difference is reported in months.

**Why zip-level weighting, not row-level:** the weights already reflect each zip's 2020 listing share. Weighting individual rows would apply listing volume twice, letting high-volume zips dominate further.

**Key correction: a weighted zip with no current-period rows.** `final_matched` returned 14 zips, not 15. Zip 30062 (Marietta) carries a 2020 weight of approximately .011 but has no 2026 rows. Its only 2020 franchise dealer, Marietta Toyota, relocated to 30060 between snapshots (see sec. 12). Left alone, the 14 present weights would sum to about .989 and understate the 2026 weighted average.

Three options were considered:
1. Exclude 30062 from both periods and renormalize the remaining 14 weights. **Chosen.**
2. Move 30062's weight into 30060, following the dealer. Rejected: the 2020 listings would still be coded to 30062, so the weight would move without the data behind it. Making it coherent would require recoding 2020 rows and rebuilding `zip_weights`, which feeds Q5 and Q6. Not justified at a weight of .011.
3. Renormalize on the 2026 side only. Rejected: the two periods would cover different geographies, so part of any difference would come from zip mix rather than the market.

`zip_weights` is left unedited, since it records the true 2020 listing shares. The exclusion and renormalization live inside `q4_weighted_avg_age.sql`, where the decision is visible.

**Pitfall caught along the way:** the first version excluded 30062 with `WHERE weight > .015`. It worked, but it filtered on a value, not on the zip. The next smallest weight (30094, approximately .0161) sat about one thousandth above the cutoff, so a small correction to the 2020 data could have silently dropped a second zip. Replaced with `WHERE dealer_zip <> '30062'`, so the code states what the comment says.

**Pitfall caught along the way:** an intermediate version carried `cars_in_zip` from the weights table into the 2026 per-zip CTE, so the 2026 column showed 2020 listing counts. Fixed by counting from `final_matched` directly and by keeping weight-related columns out of the per-zip CTEs entirely.

**Verification:** because the weights are the 2020 listing shares, the weighted 2020 average must equal the plain average age across all 8,630 2020 rows in the 14 zips. Both return 2.66 years.

**Result:**

| Period | Weighted average age |
|---|---|
| September 2020 | 2.66 years |
| September 2026 | 3.10 years |
| Difference | +5.31 months (95% CI 1.0 to 10.1) |

Threshold: +18 months (pre-registered). **Not met, with high confidence.** The whole interval sits below the threshold, and it excludes zero, so the increase is real but far smaller than hypothesized.

**Same-dealer comparison:** 2.83 to 3.41 years, +7.03 months (95% CI 2.7 to 25.9). Consistent in direction, but too imprecise to test the threshold on its own (sec. 18).

**Result history:** 3.07 years and +4.97 months on the 3,279-row `final_matched`; 3.11 and +5.36 after the overspill exclusions (two excluded luxury stores had newer inventory); 3.10 and +5.31 after EchoPark was added. The 2020 value never changed, since every rebuild touched only the 2026 side.

---

## 14. Q5: Weighted Average Mileage

**Method:** identical to Q4 (sec. 13). Per-zip average mileage is computed for each period, then pooled with the same renormalized 14-zip weights. 30062 is excluded from both periods for the same reason. Mileage columns differ by source: `mileage` in `cars_2020_fltrd`, `miles` in `final_matched`.

**Data quality checks run before building the query:**

- **NULL mileage, 2020:** 99 rows (about 1.1%), spread across six zips. Five of the six are at or below 2.7% of their zip. 30339 (Vinings) is the exception at 25 of 198 (12.6%).
- **30339 follow-up:** all 25 NULLs belong to Global Imports BMW, which is also the only 2020 franchise dealer in 30339 (198 listings). The dealer is still represented in the 2020 average by 173 cars, so there is no dealer-mix asymmetry between periods. It is thinner data within one dealer. 30339 carries a weight of about .023, so the effect on the metro result is negligible.
- **NULL mileage, 2026:** 34 rows of 3,041 (about 1.1%). History: 37 of 3,279 before the sec. 12 rebuild, 29 of 3,024 after the overspill exclusions, 34 after EchoPark's 17 listings were added (5 of them lack mileage).
- **Zero-mileage placeholders:** none in either table.

**Why check for zeros:** a real low reading (a demo with 40 miles) is a valid used car and stays in. The concern is placeholders. Some dealer feeds write 0 when mileage was not entered. `AVG()` skips a NULL but counts a 0 as a real reading, so placeholder zeros would pull averages down without appearing as missing data.

**Note on the built-in check:** the Q4 verification (weighted 2020 average equals the plain 2020 average) does not hold exactly for mileage. The weights count all listings, but `AVG()` skips the NULL rows. A small gap is expected and explained.

**Result:**

| Period | Weighted average mileage |
|---|---|
| September 2020 | 41,594 miles |
| September 2026 | 47,477 miles |
| Difference | +5,883 miles (95% CI 1,637 to 11,620) |

Threshold: +15,000 miles (pre-registered). **Not met, with high confidence.** The whole interval sits below the threshold and excludes zero.

**Same-dealer comparison:** 47,171 to 50,922 miles, +3,751 (95% CI 625 to 23,990). Consistent in direction, too imprecise to test the threshold on its own.

**Result history:** 45,962 and +4,368 on the 3,279-row `final_matched`; 47,475 and +5,882 after the overspill exclusions; 47,477 and +5,883 after EchoPark. The 2020 value never changed.

**Cross-check with Q4:** in the pre-registered comparison, 5,883 additional miles over about 0.44 additional years of age is roughly 13,300 miles per year, in line with typical annual driving: older inventory, not harder-driven inventory. In the same-dealer comparison it is 3,751 miles over about 0.59 years, roughly 6,400 miles per year. At continuing dealers, cars aged faster than they gained miles, so the cross-check holds for the full market but not clearly for continuing stores.

---

## 15. Q6: Weighted Average Real Price

**Method:** same structure as Q4 and Q5. Per-zip average price for each period, pooled with the renormalized 14-zip weights, 30062 excluded from both periods. 2020 prices are converted to August 2026 dollars before averaging:

real 2020 price = nominal 2020 price x (CPI August 2026 / CPI August 2020)

**CPI choices:**
- **Index:** CPI-U, all items, U.S. city average, not seasonally adjusted. August 2020 = 259.918, August 2026 = 334.980. Ratio about 1.2888, so general prices rose about 28.9%.
- **Why all-items, not the used cars and trucks index:** the used-car index measures used-car price change, which is the thing being tested. Deflating by it would remove the effect by construction.
- **Why national:** more frequent and less noisy than the Atlanta metro series, and the more common default.
- **Why August to August:** September 2026 CPI was not yet published. Matching the same calendar month gives an exact 72-month span, keeps seasonal effects out of the ratio, and leaves both CPI months one month before their listing snapshots.

The CPI values are held in their own one-row CTE and attached with a `CROSS JOIN`, rather than hardcoding the ratio, so a reader can see where the adjustment comes from.

**Data quality:** no NULL prices in either table. `final_matched` has 11 prices under $1,000 (9 Global BMW, 2 Rick Case Hyundai Duluth), all on recent model years with normal mileage, so they are placeholders or payment figures, not prices. A `price >= 1000` floor is applied to both periods so the rule is symmetric. Global BMW is also the dealer behind the 2020 NULL mileage in 30339 (sec. 14), so its listing data is unreliable across both snapshots.

**Pitfall caught along the way:** multiplying `AVG(price)` by the CPI ratio in a grouped SELECT raised a `GROUP BY` error, because the ratio column is neither grouped nor aggregated. Moving the ratio inside the aggregate, `AVG(c.ratio * f.price)`, fixes it and reads as intended: every 2020 price in 2026 dollars.

**Pre-registered result (all 2026 franchise dealers):**

| Period | Weighted average price (August 2026 dollars) |
|---|---|
| September 2020 | $34,927 |
| September 2026 | $37,448 |
| Difference | +$2,521 (95% CI -$2,318 to +$12,059) |

**Same-dealer comparison:** $29,972 to $32,439, +$2,467 (95% CI -$3,479 to +$4,260).

Threshold: +$2,000 (pre-registered). **Inconclusive.** Both point estimates clear the threshold by about $500, and they nearly agree, so dealer mix is not what produces the increase. But the dealer-level uncertainty is far wider than that margin: 42% of pre-registered resamples and 63% of same-dealer resamples fall below $2,000, and both intervals include zero. The data cannot confirm the threshold, or even that real prices rose.

**Result history:** +$5,624 on the 3,279-row `final_matched`; +$2,570 after the overspill exclusions (more than half of the original figure came from two luxury dealers outside the study area); +$2,521 after EchoPark, which adds nearly new cars at below-average prices.

**How the sensitivity runs evolved.** Price is more exposed to dealer mix than age or mileage, so two sensitivity runs were built. Both were later found to be flawed, and the history is recorded here because the corrections changed the conclusion twice.

- **First same-dealer run (one-sided): -$2,488.** It restricted the 2026 side to continuing dealers but compared them against every 2020 dealer. The 2020 dealers with no 2026 counterpart averaged about $5,000 more than those that continued, so leaving them in made continuing dealers look like they cut prices. Restricting both sides gives +$2,467. This error briefly produced a finding that existing dealers priced below inflation, which was wrong.
- **Equal-coverage run: +$1,319, dropped.** It kept continuing dealers plus true market entries on the 2026 side and dropped stores missing from the 2020 data, to compare the two periods at equal coverage. It removed 2026 stores missing from the 2020 data but left in every 2020 store missing from the 2026 data. Some of those closed, but many were likely just not sampled (sec. 17). A fair version would keep closed stores and drop unsampled ones, and the data cannot tell them apart, so the run cannot be built symmetrically. A decomposition built on it (continuing dealers below inflation, luxury entrants driving the rise) was withdrawn with it.

**Conclusion:** the point estimates say real used-car prices at Atlanta franchise dealers rose about $2,500 more than general inflation, whether measured on the full sample or on dealers present in both periods. That is above the $2,000 threshold. But at the dealer level the evidence is too thin to confirm it: each zip's average rests on a handful of stores, and the plausible range runs from a real decline to a large increase (sec. 18). The sampling-cap check suggests the 2026 price is, if anything, understated (sec. 17).

**On reporting:** the thresholds were set against the full comparison before any results were seen. The pre-registered figure is reported as the primary result, with the same-dealer comparison and the confidence intervals as tests of its robustness, rather than substituting whichever version reads best after the fact.

---

## 16. Pipeline Integrity Fixes

**Duplicated 2020 population.** A check of `cars_2020_fltrd` returned 17,444 rows for 8,722 distinct VINs, with every VIN exactly twice. The script created the table with `CREATE TABLE IF NOT EXISTS` and filled it with a separate `INSERT`, so a second run skipped the create and appended every row again. Averages were unaffected because every row doubled evenly, which is why no result had moved. `zip_weights` had been built before the duplication and was confirmed correct (`SUM(cars_in_zip)` = 8,722). The script now uses `CREATE OR REPLACE TABLE ... AS SELECT`, with explicit casts to keep the original column types, and `overrides_2020` was checked for duplicate `sp_name` values first, since a duplicate there would fan out through the join. Every pipeline script now uses `CREATE OR REPLACE`.

**Database location and the write-ahead log.** The database had been created in the user folder rather than the project, because the CLI creates the file in whatever folder the terminal is in. When it was moved into `data/`, the write-ahead log (`08_cars.duckdb.wal`), which held that day's changes not yet folded into the main file, was left behind, and the moved database was missing `cars_2020_fltrd`. Moving the `.wal` next to the database and reopening it replayed the changes, and every table was verified at its current count. Lessons: move the `.wal` with the database, run `CHECKPOINT` before moving or copying it, and open the CLI with the full path, since `duckdb <name>` silently creates a new empty database if the name is not found in the current folder. The database is generated from the CSVs and scripts and is excluded from Git. Two stray tables (`cars_2020_fltr`, `test`) and a stray empty database from a typo were removed.

---

## 17. Sampling Cap and Sort Order

**The question:** in the 11 zips that hit the 25-call cap, the API decided which listings were returned. If it returns listings in an order related to age, mileage, or price, the 2026 averages are skewed even at continuing dealers, and no dealer restriction can fix that.

**Coverage:** dealers holding 4,077 of the 8,630 2020 listings (47%) do not appear in the 2026 pull at all, and 1,010 of 3,030 priced 2026 listings (33%) come from stores with no 2020 counterpart in the data. The export of unmatched 2026 dealers (sec. 12) confirmed that the missing 2020 dealers were never pulled, not pulled and mismatched.

**Sort order:** the pull script (`python/00_pull_listing.py`) sets no sort parameter, and auto.dev's documented default is most recently updated first. Each capped zip therefore returned its 500 most recently updated listings.

**Recency gradient:** within the capped zips, listings were split into quartiles by creation date:

| Quartile (most recent first) | Avg age | Avg miles | Avg price |
|---|---|---|---|
| 1 | 3.86 | 51,644 | $33,784 |
| 2 | 3.70 | 51,284 | $37,557 |
| 3 | 3.06 | 47,840 | $33,574 |
| 4 | 2.61 | 42,822 | $41,153 |

Recently listed cars are older, higher-mileage, and cheaper; older listings are newer, lower-mileage, and pricier. That fits normal lot dynamics: cheaper, older cars sell quickly, while newer, pricier cars sit longer. If the trend continues past the cut, the listings not returned were newer, lower-mileage, and pricier, so the 2026 sample in capped zips likely overstates age and mileage and understates price.

**Effect on the verdicts:** the likely bias works against every finding. It would make the true Q4 and Q5 increases smaller (still not met) and the true Q6 increase larger.

**Limitation:** the API sorted by update date, but the pull did not capture `updatedAt`, so creation date is used as a stand-in. A price cut can refresh an old listing without changing its creation date, so the conclusion is an inference, not a measurement. An uncapped-zips-only rerun was considered and not used: the four uncapped zips carry about 8% of the weight and three are in Conyers, so they cannot speak for the other eleven.

---

## 18. Bootstrap Confidence Intervals

**Why:** Q6 cleared its threshold by about $500 in both comparisons. A point estimate that clears a threshold is not the same as a result that clears it, so the uncertainty had to be measured before any verdict could stand. Q4 and Q5 were measured the same way so all three metrics are reported alike.

**Method (`python/q4_q6_bootstrap.py`):** a dealer-level cluster bootstrap, stratified by zip and period, 2,000 resamples per metric per comparison, fixed seed.
- All data rules stay in SQL; Python pulls one listing-level table and only resamples.
- Each resample keeps all 28 period-zip groups and redraws the same number of dealers within each, with replacement, taking all of a drawn dealer's listings. Listings from one dealer share its pricing and stocking policy, so resampling individual listings would treat them as independent and make the intervals too narrow.
- Weights never change.
- The Python point estimates were confirmed to reproduce the SQL results exactly before any interval was computed.

**Dealers per zip:** six of the 14 zips (30012, 30013, 30067, 30094, 30339, 30518) have two dealers or fewer in at least one period. In the same-dealer comparison, six zips have a single continuing dealer on each side.

**Results:**

| Metric | Comparison | Point | 95% CI | Median | Share below threshold |
|---|---|---|---|---|---|
| Age (months) | Pre-registered | +5.3 | 1.0 to 10.1 | 5.1 | 100.0% |
| Age (months) | Same dealer | +7.0 | 2.7 to 25.9 | 7.8 | 75.2% |
| Mileage | Pre-registered | +5,883 | 1,637 to 11,620 | 6,047 | 99.7% |
| Mileage | Same dealer | +3,751 | 625 to 23,990 | 5,194 | 75.0% |
| Real price | Pre-registered | +$2,521 | -$2,318 to +$12,059 | $2,520 | 42.0% |
| Real price | Same dealer | +$2,467 | -$3,479 to +$4,260 | $1,289 | 63.4% |

**Reading them:** the pre-registered intervals for age and mileage sit entirely below their thresholds and exclude zero, so both increases are real and both "not met" verdicts hold with high confidence. The price intervals span the threshold and include zero, so Q6 is inconclusive. The same-dealer intervals are wide because the continuing set is often one store per zip, and redrawing among the three to eight stores in the remaining zips swings the averages. The same-dealer run confirms that the point estimates are not a composition artifact, but it is too thin to test thresholds on its own. For same-dealer price, the median ($1,289) sits well below the point estimate, meaning the observed figure depends heavily on which specific stores are in the thin zips.

**Limitations:** a single-dealer group contributes no variation, since redrawing one dealer always returns it, so the true uncertainty is likely wider than shown. A bootstrap with few clusters per group gives approximate intervals. A few stores appear under two dealer IDs in the 2026 data (for example Global BMW in 30339), which slightly overstates the dealer count in those zips.