#---------------------------------------------------------
# Project: Metro Atlanta Used-Car Inventory Study
# File name: q4_q6_bootstrap.py
# Table: none (reads cars_2020_fltrd, final_matched, and
#        zip_weights from data/08_cars.duckdb, read-only)
# Business question: Q4-Q6) How much uncertainty surrounds the
#                    weighted age, mileage, and real price changes,
#                    and does each verdict hold once it is measured?
# Purpose: 95% confidence intervals for all three metrics, for
#          both the pre-registered comparison and the same-dealer
#          comparison, using a dealer-level cluster bootstrap
#          stratified by zip and period.
# Author: J.Glenn
# Date: September 2026
#---------------------------------------------------------
#
# Design
#   - All data rules stay in SQL: the CPI conversion, the $1,000
#     price floor, the 30062 exclusion, and the continuing-dealer
#     definition match q4, q5, and q6. Python only resamples.
#   - The price floor blanks real_price on placeholder rows instead
#     of dropping them, because Q4 and Q5 do not use the floor.
#     pandas mean() skips blanks the way SQL AVG() skips NULLs.
#   - Resampling draws whole dealers, not single listings. Listings
#     from one dealer share that store's pricing and stocking
#     policy, so treating them as independent would make the
#     intervals too narrow.
#   - Each resample keeps every period-zip group and redraws the
#     same number of dealers within it, mirroring how the point
#     estimate is built. Weights never change.
#   - Before any interval is trusted, the point estimates must
#     reproduce the SQL results exactly.
#
# Limitation
#   A period-zip group with one dealer contributes no variation
#   (redrawing one dealer always returns it). Six of the 14 zips
#   have two dealers or fewer in at least one period, so the true
#   uncertainty is, if anything, wider than these intervals.

from pathlib import Path

import duckdb
import numpy as np
import pandas as pd

# ---- settings ----
DB_PATH = Path(__file__).resolve().parent.parent / "data" / "08_cars.duckdb"
N_REPS = 2000   # resamples per metric per comparison
SEED = 42       # fixed so every run returns the same intervals

# (column, display scale, threshold, unit)
# age is stored in years and scaled x12 to compare against the
# 18-month threshold.
METRICS = [
    ("age",        12, 18,     "months"),
    ("mileage",     1, 15000,  "miles"),
    ("real_price",  1, 2000,   "dollars"),
]


# ---- SQL ----
LISTINGS_SQL = """
WITH cpi AS (
    SELECT 259.918 AS aug20
         , 334.980 AS aug26
         , aug26 / aug20 AS ratio
)
, t2020 AS (
    SELECT 2020                                               AS period
         , f.dealer_zip                                       AS zip
         , f.sp_name                                          AS dealer
         , 2020 - CAST(f.mod_year AS DOUBLE)                  AS age
         , f.mileage                                          AS mileage
         , CASE WHEN f.price >= 1000 THEN c.ratio * f.price END AS real_price
         , ( EXISTS (
                 SELECT 1
                 FROM final_matched m
                 WHERE m.csv_match = true
                   AND m.final_zip = f.dealer_zip
                   AND ( LOWER(TRIM(m.dealer)) = LOWER(TRIM(f.sp_name))
                      OR f.sp_name ILIKE '%' || TRIM(m.dealer) || '%'
                      OR m.dealer ILIKE '%' || TRIM(f.sp_name) || '%' )
             )
          OR f.sp_name IN (
                 'Global Imports BMW'
               , 'John Miles Chevrolet Buick GMC'
               , 'Jim Tidwell Ford'
               , 'Sutherlin Nissan Mall of Georgia'
               , 'Malcolm Cunningham Chevrolet North Point'
               , 'AutoNation Ford Marietta'
               , 'Kia Atlanta South'
               , 'Heritage Cadillac Mitsubishi'
               , 'Hennessy Buick GMC Mazda'
               , 'Hennessy Mazda'
             )
           )                                                  AS continuing
    FROM cars_2020_fltrd f
    CROSS JOIN cpi c
    WHERE f.dealer_zip <> '30062'
)
, t2026 AS (
    SELECT 2026                                               AS period
         , final_zip                                          AS zip
         , dealerId                                           AS dealer
         , 2026 - CAST(year AS DOUBLE)                        AS age
         , miles                                              AS mileage
         , CASE WHEN price >= 1000 THEN price END             AS real_price
         , ( csv_match = true
          OR dealerId IN (
                 'd_da2c46d7beb1242f', 'd_7bfda8a27828c52d', 'd_aa3c808ad5776409'
               , 'd_f17a38eafcf9f604', 'd_bea2c7500677d115', 'd_1bd625e0ea7fbcf7'
               , 'd_a3ea3d7d17558de2', 'd_e83b59ee37c7f8b8', 'd_374d7b0ecf59000e'
               , 'd_3d857696dd81781d'
             )
           )                                                  AS continuing
    FROM final_matched
)
SELECT * FROM t2020
UNION ALL
SELECT * FROM t2026
"""

WEIGHTS_SQL = """
SELECT dealer_zip AS zip
     , cars_in_zip / (SELECT SUM(cars_in_zip)
                      FROM zip_weights
                      WHERE dealer_zip <> '30062') AS weight
FROM zip_weights
WHERE dealer_zip <> '30062'
"""


# ---- functions ----
def weighted_diff(df, weights, col):
    """Weighted 2026 minus 2020 difference for one metric.

    Mirrors the SQL: average by period and zip, attach each zip's
    fixed weight, sum weight x average within each period, then
    subtract.
    """
    zip_avg = df.groupby(["period", "zip"])[col].mean().reset_index()
    zip_avg = zip_avg.merge(weights, on="zip")
    zip_avg["weighted"] = zip_avg["weight"] * zip_avg[col]
    totals = zip_avg.groupby("period")["weighted"].sum()
    return totals[2026] - totals[2020]


def cluster_bootstrap(df, weights, col, n_reps=N_REPS, seed=SEED):
    """Resample dealers within each period-zip group and return
    n_reps recomputed weighted differences."""
    rng = np.random.default_rng(seed)

    # split each period-zip group into one DataFrame per dealer,
    # once, before resampling
    groups = {}
    for key, g in df.groupby(["period", "zip"]):
        groups[key] = [d for _, d in g.groupby("dealer")]

    results = []
    for _ in range(n_reps):
        pieces = []
        for dealer_frames in groups.values():
            n = len(dealer_frames)
            picks = rng.integers(0, n, size=n)   # with replacement
            pieces.extend(dealer_frames[i] for i in picks)
        sample = pd.concat(pieces, ignore_index=True)
        results.append(weighted_diff(sample, weights, col))

    return np.array(results)


# ---- run ----
if __name__ == "__main__":
    con = duckdb.connect(str(DB_PATH), read_only=True)
    listings = con.execute(LISTINGS_SQL).df()
    weights = con.execute(WEIGHTS_SQL).df()
    con.close()

    continuing = listings[listings["continuing"]]
    comparisons = [("Pre-registered", listings), ("Same dealer", continuing)]

    # sanity checks: expect 2020 = 8,630 rows, 2026 = 3,041 rows,
    # 14 zips per period, weights summing to 1
    print("Rows by period and continuing flag:")
    print(listings.groupby(["period", "continuing"]).size(), "\n")
    print("Zips per period:")
    print(listings.groupby("period")["zip"].nunique(), "\n")
    print(f"Weights: {len(weights)} zips, sum = {weights['weight'].sum():.6f}\n")

    # dealers per period-zip group: shows how thin each zip is
    for label, data in comparisons:
        print(f"Dealers per zip ({label}):")
        print(data.groupby(["period", "zip"])["dealer"].nunique()
                  .unstack("period"), "\n")

    # point estimates must match the SQL before intervals are trusted:
    #   age          +5.31 months (pre-registered), +7.03 (same dealer)
    #   mileage      +5,883 (pre-registered),       +3,751 (same dealer)
    #   real_price   +2,521 (pre-registered),       +2,467 (same dealer)
    print("Results (95% CI from dealer-level cluster bootstrap):")
    for col, scale, threshold, unit in METRICS:
        for label, data in comparisons:
            point = weighted_diff(data, weights, col) * scale
            boots = cluster_bootstrap(data, weights, col) * scale
            lo, hi = np.percentile(boots, [2.5, 97.5])
            median = np.median(boots)
            below = (boots < threshold).mean()
            print(f"  {col:<10} | {label:<14} | point {point:>10,.1f} {unit:<7} | "
                  f"95% CI {lo:>10,.1f} to {hi:>10,.1f} | median {median:>10,.1f} | "
                  f"below threshold {below:6.1%}")