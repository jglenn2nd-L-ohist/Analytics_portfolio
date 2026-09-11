# Metro Atlanta Used-Car Inventory Study — Methodology Log

**Purpose:** Compare franchise-dealer used-vehicle inventory (age, mileage, price) in metro Atlanta between a September 2020 snapshot and a current-period pull, to test whether dealer offerings have changed ("quality degradation" thesis).

This document exists as a teaching/reference log — it captures not just the final decisions, but the mistakes caught along the way, since the corrections are as instructive as the conclusions.

---

## 1. Data Sources

| Period | Source | Method |
|---|---|---|
| Pre/early-COVID | Kaggle "US Used Cars Dataset" — CarGurus crawl, **September 2020**, ~3M rows | Static CSV, queried via DuckDB |
| Current | auto.dev API | Live pull, radius search per zip, 1,000 calls/month cap |

**Framing correction made early on:** September 2020 is *not* a clean pre-COVID baseline — the pandemic began disrupting the auto supply chain (trade-ins, auctions, production) starting March 2020. The project is framed as **"September 2020 vs. current," not "pre-COVID vs. post-COVID."** If anything, this makes a finding of degradation a *conservative* estimate, since the true pre-pandemic baseline was likely even better than the September 2020 snapshot shows.

---

## 2. City & Zip Code Selection

### Original candidate cities (for geographic dispersion around metro Atlanta):
Duluth, Marietta, Alpharetta, Conyers, Douglasville, Stockbridge, Lithonia, Buford, Kennesaw, Stone Mountain.

### Key correction #1 — city name ≠ unique location
This is a nationwide dataset with no `state` column. City names like "Marietta" exist in multiple states. **Zip code, not city name, is the only reliable geographic filter.**

### Key correction #2 — city labels in the raw data are inconsistent
Testing zip-only (no city filter) revealed:
- Zip 30038 (Lithonia) appears in the data under **"Stonecrest"** (a newer incorporated city that absorbed the area in 2017).
- Zip 30341 appears under both **"Atlanta"** and **"Chamblee."**
- Several zips near the Perimeter appear generically as "Atlanta" (30341, 30360, 30339), which obscures real sub-market differences (Chamblee, Doraville, Vinings respectively).

**Fix:** Verified each ambiguous zip's actual common name via independent search (zip-codes.com, USPS alias data), then hardcoded a `CASE WHEN dealer_zip = 'X' THEN 'RealName' ELSE city END AS display_city` — a per-zip label, not a guess from an aggregate function.

**Pitfall caught along the way:** `MAX(city)` was tried as a shortcut to auto-resolve label conflicts. It happened to return "Chamblee" for 30341 — but only because "Chamblee" sorts alphabetically after "Atlanta." `MAX()` on a text column is alphabetical, not "most accurate." It got lucky once; it is not a reliable method and was replaced with explicit `CASE WHEN` mapping.

### Key correction #3 — zero-result cities are real findings, not errors
Douglasville and Stockbridge returned **zero** franchise-dealer listings even after removing the city filter and testing their zips directly. Confirmed as a genuine feature of the September 2020 sample, not a data-matching bug.

### Substitutions made (with reasoning trail)
- Stone Mountain → **Union City (30291)** — chosen for more southern geographic exposure.
- Douglasville / Stockbridge (zero data) → **Jonesboro (30236)** — direct outer-suburb replacement.
- Generic "Atlanta" zips → evaluated individually by character, not lumped as one city:
  - 30341 → **Chamblee** (international corridor / Buford Hwy commercial nexus) — kept.
  - 30360 → **Doraville** — later **excluded** (see outlier screening below).
  - 30339 → **Vinings** (Cumberland/Battery corridor) — flagged as possibly too commercial/affluent to match the suburban-residential character of the rest of the set; tested rather than excluded on impression alone — retained (see below).
- Jonesboro (30236) → **Morrow (30260)** — Jonesboro's *current-period* pull returned only 8 listings (see sampling section); before swapping, Morrow was independently tested against the **2020 CSV** (not just assumed to qualify) and passed cleanly: 800 franchise/used listings, price/mileage/year all within the existing distribution, no city-label ambiguity.

---

## 3. Data-Integrity Corrections (SQL lessons)

1. **`LIKE '30%%%'`** — the extra `%` characters are redundant; a single `%` already matches any number of characters.
2. **New vs. used contamination** — an early query omitted `is_new = false`. This mixed new-vehicle inventory (near-zero mileage, current model year, MSRP-level pricing) into what was meant to be a used-only comparison, distorting every downstream average. All queries after this point explicitly filter `is_new = false`.
3. **`GROUP BY city, dealer_zip` silently double-counts a zip** when that zip has more than one raw city label in the source data (e.g., 30341 under "Atlanta" and "Chamblee" produced two separate rows instead of one combined zip-level average). Fix: group by `display_city, dealer_zip` — using the *derived, deterministic* label — once the raw label is no longer being used directly.
4. **SQL aggregate rule:** once a column is not in `GROUP BY`, it must be wrapped in an aggregate function (`MAX()`, `AVG()`, etc.) or referenced through a `CASE` that resolves deterministically — SQL will not "pick one" for you silently, and if it does resolve (as with `MAX()`), the resolution logic may not mean what you assume.

---

## 4. Outlier Screening (Price)

**Method:** z-score on average price per zip, using the 16-zip candidate set (n=16 zip-level averages).

**Threshold:** |z| > 2 → exclude.

**Result:**
- **30360 (Doraville): z ≈ 2.70 → excluded.**
- 30339 (Vinings): z ≈ 1.45 → retained, but flagged as the second-highest z-score in the set — a near-miss, not a comfortable retain. Documented explicitly rather than silently kept.

**Caveat documented for the write-up:** z-scores and the ±2 convention assume a reasonably large, roughly normal distribution. With only 16 zip-level data points, a single unusual value can distort the mean/SD used to judge everything else. This method is used here as a **directional screening tool**, not a statistically rigorous outlier test — stated explicitly to avoid overclaiming precision.

---

## 5. Sample Size / Reliability Checks

- **Small-n zips are not automatically unreliable.** The real test is distribution shape, not row count alone. For a thin zip (30094, n=140), checked median vs. mean of mileage: 33,518 vs. 36,603 — only ~9% apart, meaning the elevated average wasn't being driven by a handful of extreme outliers. Retained.
- **Contrast case: 30236 (Jonesboro) current-period pull returned only 8 listings** from a single API call that came back short of a full page — read as evidence the zip's real current inventory is nearly exhausted (a population ceiling), not an artifact of stopping early. At n=8, no meaningful median/mean skew check is possible. This zip was replaced (see Morrow substitution above) rather than kept with a caveat, since the sample was judged too thin to support any average.

---

## 6. Current-Period Sampling Design (auto.dev)

- **Budget constraint discovered mid-project:** auto.dev caps at 1,000 **API calls**/month — not 1,000 listings. Each call returns roughly 20 listings.
- **Equal-weighting goal:** since the pre-COVID side was designed so no single zip's raw volume would dominate the comparison, the intent was to sample the current period with the same zip set, comparably.
- **"Water-filling" problem encountered:** an attempt to combine a minimum-floor-per-zip with proportional distribution of the remainder caused zips to fall below the floor in multiple cascading passes as the "remainder pool" shrank. Simpler resolution chosen: **flat call allocation per zip** (25 calls/zip; 15 zips × 25 = 375 of the 1,000-call budget), accepting that this produces equal *effort* per zip, not necessarily equal *listings*, since some zips exhaust their available current inventory well before 25 calls (e.g., Union City plateaued around 140 listings at just 8 calls in an early test), while others (Duluth) were still climbing past 1,300 at 66 calls in testing.
- **Result:** 10 of 15 zips returned the full ~500 listings (25 calls × ~20/call with no early exhaustion); 5 zips returned fewer, reflecting real market-size differences rather than sampling error.

---

## 7. Franchise-Dealer Identification (Current-Period Data)

The auto.dev schema (`vin`, `year`, `make`, `model`, `price`, `miles`, `dealer`, `dealerId`, `createdAt`, plus a zip field) has **no franchise/independent flag**, unlike the 2020 CSV's clean `franchise_dealer` boolean.

**Method chosen:** since franchise status is tied to the *dealer*, not each individual listing, verification only needs to happen once per unique `dealer`/`dealerId` (a manageable list — dozens, not hundreds of rows) rather than per listing:
1. Name-match first pass (dealer name contains a recognizable brand).
2. Manual verification for anything ambiguous, cross-checked against the manufacturer's own dealer locator — since some real franchise dealers (e.g., "RBM of Atlanta" for Mercedes-Benz) don't contain the brand name, and some independent lots use brand-adjacent names.

**Documented asymmetry:** the 2020 side has verified ground-truth franchise status; the current side relies on inference. This is a stated limitation, not a hidden one.

---

## 8. Geographic Precision Note

auto.dev's search is **radius-based (2-mile radius per zip centroid)**, not an exact zip match like the CSV's `dealer_zip` field. The returned data does include a zip field per listing, so results are filtered down to the exact target zip after pulling — preserving exact-match geography consistent with the historical side, despite the looser initial search method.

---

## 9. Final Zip Set (15 zips)

| Zip | Display City | Notes |
|---|---|---|
| 30096 | Duluth | original |
| 30291 | Union City | swapped in for Stone Mountain (southern exposure) |
| 30519, 30518 | Buford | original |
| 30144 | Kennesaw | original |
| 30060, 30067, 30062 | Marietta | narrowed from 7 candidate zips to the 3 with actual franchise-dealer volume |
| 30009, 30004 | Alpharetta | original |
| 30013, 30012, 30094 | Conyers | original |
| 30341 | Chamblee | corrected from generic "Atlanta" label |
| 30339 | Vinings | corrected from generic "Atlanta" label; retained after z-score check (z≈1.45, near-miss) |
| 30260 | Morrow | swapped in for Jonesboro (30236), which was itself a swap for Douglasville/Stockbridge (zero 2020 data) |

**Excluded:** 30360 (Doraville) — price outlier (z≈2.70). 30236 (Jonesboro) — insufficient current-period sample (n=8).

---

## 10. Post-Pull Cleaning (Current-Period Data)

After the initial ~6,549-row auto.dev pull, several additional issues surfaced during cleaning:

- **NULL zips:** over half the raw pull (roughly 3,450+ rows) had a NULL scraped `zip` field, despite `city` being populated — spanning nearly every target city, not an isolated case. Root cause traced to the scraped `zip` field itself being unreliable; the API's own `searchZip` field (recording which zip-radius search produced each row) was found to be 100% populated and used as the authoritative geography field going forward instead.
- **Cross-zip VIN duplication:** 49 VINs appeared under more than one `searchZip` (max 2 zips each, 49 duplicate rows total, ~0.75% of the dataset) — caused by 2-mile radius searches for neighboring zips overlapping geographically.
- **Franchise-status gap:** auto.dev's schema has no franchise/independent flag. Resolved via a join against the 2020 CSV's `sp_name` + `dealer_zip` (matched against `searchZip`), using partial/substring name matching (loosened from exact match after discovering current-period dealer names are often shortened versions of the 2020 full names, e.g., "Palmer Dodge" vs. "Palmer Dodge Chrysler Jeep Ram"). Remaining unmatched dealers (161 initially, reduced after the loosened join) required manual verification — see `sql/04_franchise_overrides.sql`.
- **Ground-truth errors found in the 2020 flag itself:** "Southern Star Automotive" was flagged `franchise_dealer = true` in the 2020 CSV despite being a known non-franchise lot — a confirmed data error, corrected via override. ("Atlanta Classic Cars," initially suspected of the same issue, was independently verified as a legitimate Mercedes-Benz franchise — the original flag was correct.)
- **Radius-search overspill:** "Nalley Lexus Smyrna" appeared under three different `searchZip` values (30339, 30291, 30009) — none of which is its real location. Independently verified address: 2750 Cobb Pkwy SE, Smyrna, GA **30080** — outside the 15-zip study area. All listings tied to this dealer were excluded rather than assigned to any of the three zips it happened to appear under.

## 11. Open Limitations to Carry Into the Write-Up

- September 2020 baseline is early-pandemic, not true pre-COVID — framed accordingly throughout.
- Nominal price comparison requires inflation adjustment (CPI) to avoid conflating currency devaluation with real price/quality change — flagged, not yet executed.
- Both datasets are live-lot inventory snapshots (right-censored: what hasn't sold yet), not sales records — this makes them comparable to each other, but means neither reflects true transaction activity.
- "Degradation" is the stated thesis being tested, not an assumed conclusion — the data may show a supply-constraint story (fewer trade-ins/off-lease vehicles reaching dealers) as easily as a "dealers chose to lower standards" story. The data can show *that* something changed; it can't alone explain *why*.
- USPS-designated primary city ("Atlanta") differs from the colloquial names used in this analysis (Chamblee, Doraville, Vinings, Morrow) — noted so the discrepancy isn't mistaken for an error if cross-checked later.
- Franchise-dealer status on the current-period side is inferred (name-match + manual verification), not a verified field, unlike the 2020 side.
