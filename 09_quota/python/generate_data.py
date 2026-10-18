##################################################
# Project: Quota and Commission Model (09_quota_model)
# File name: generate_data.py
# Business question: Does the flat-tier commission
#                    structure overpay, and if so,
#                    where and by how much?
# Purpose:   Generate the synthetic sales data the model
#            runs on (rules in docs/rules_spec.md).
#            Writes regions.csv, reps.csv, sales.csv and
#            calendar.csv to data/raw/. Quota is not
#            generated here; it is calculated in Excel
#            from prior-year actuals.
# Author: J.Glenn (script written with Claude)
# Date: October 2026
###################################################

from pathlib import Path

import numpy as np
import pandas as pd

# ---------------------------------------------------------------------------
# 1. CONFIG: every assumption lives here so it can be compared to the spec
# ---------------------------------------------------------------------------
CONFIG = {
    "random_seed": 42,
    "start_date": "2021-01-01",
    "end_date": "2025-12-31",
    # headcount and year-1 monthly quota seed per region (spec item 1 and 6)
    "regions": {
        1: {"name": "Region 1", "headcount": 2, "seed": 150_000},
        2: {"name": "Region 2", "headcount": 5, "seed": 275_000},
        3: {"name": "Region 3", "headcount": 5, "seed": 300_000},
        4: {"name": "Region 4", "headcount": 8, "seed": 400_000},
    },
    # growth in ACTUAL sales (spec item 6 sets the 15% quota target)
    "annual_growth": 0.15,
    "growth_wobble_sd": 0.04,   # region-year variation so regions hit and miss
    # turnover (spec item 7)
    "annual_turnover": 0.25,
    "fill_days_min": 15,
    "fill_days_max": 45,
    # rep and sales behavior
    "skill_sd": 0.15,           # spread of rep skill around 1.0
    "noise_sd": 0.12,           # month-to-month noise per rep
    "seasonality_amplitude": 0.08,
    "mean_order": 800,          # average order size in dollars
    "order_sigma": 0.9,         # skew of order sizes (lognormal)
    # returns and cancellations (spec item 2)
    "return_rate": 0.06,
    "cancel_rate": 0.03,
    "return_window_days": 30,
    "output_dir": "data/raw",
}

rng = np.random.default_rng(CONFIG["random_seed"])
START = pd.Timestamp(CONFIG["start_date"])
END = pd.Timestamp(CONFIG["end_date"])

# ---------------------------------------------------------------------------
# 2. REGIONS
# ---------------------------------------------------------------------------
regions = pd.DataFrame(
    [
        {
            "region_id": rid,
            "region_name": r["name"],
            "target_headcount": r["headcount"],
            "year1_monthly_seed": r["seed"],
        }
        for rid, r in CONFIG["regions"].items()
    ]
)

# ---------------------------------------------------------------------------
# 3. REPS: simulate turnover seat by seat
#    Each seat is a chair that always needs a rep. When a rep leaves, the seat
#    sits empty for 15 to 45 days and then a new rep starts.
#    Time-to-leave uses an exponential distribution, which gives the stated
#    annual turnover rate on average.
# ---------------------------------------------------------------------------
daily_hazard = -np.log(1 - CONFIG["annual_turnover"]) / 365

rep_rows = []
for region_id, r in CONFIG["regions"].items():
    for _seat in range(r["headcount"]):
        # initial rep was hired before the data window starts
        hire = START - pd.Timedelta(days=int(rng.integers(180, 1500)))
        while True:
            clock_start = max(hire, START)
            days_until_leave = rng.exponential(1 / daily_hazard)
            term = clock_start + pd.Timedelta(days=int(days_until_leave))
            skill = float(np.clip(rng.normal(1.0, CONFIG["skill_sd"]), 0.6, 1.4))
            if term > END:
                rep_rows.append((region_id, hire, pd.NaT, skill))
                break
            rep_rows.append((region_id, hire, term, skill))
            fill = int(rng.integers(CONFIG["fill_days_min"], CONFIG["fill_days_max"] + 1))
            hire = term + pd.Timedelta(days=fill)
            if hire > END:
                break

reps = pd.DataFrame(rep_rows, columns=["region_id", "hire_date", "term_date", "skill_factor"])
reps = reps.sort_values(["hire_date", "region_id"]).reset_index(drop=True)
reps.insert(0, "rep_id", [f"R{i + 1:03d}" for i in range(len(reps))])
reps["skill_factor"] = reps["skill_factor"].round(3)

# ---------------------------------------------------------------------------
# 4. GROWTH PATH: cumulative growth factor per region and year
#    Year 1 is 1.0. Each later year grows by about 15%, plus a random wobble.
# ---------------------------------------------------------------------------
years = list(range(START.year, END.year + 1))
growth_factor = {}
for region_id in CONFIG["regions"]:
    cum = 1.0
    for i, year in enumerate(years):
        if i > 0:
            cum *= 1 + CONFIG["annual_growth"] + rng.normal(0, CONFIG["growth_wobble_sd"])
        growth_factor[(region_id, year)] = cum

# ---------------------------------------------------------------------------
# 5. SALES: one rep-month at a time, split into individual orders
# ---------------------------------------------------------------------------
months = pd.period_range(START, END, freq="M")
loss_rate = CONFIG["return_rate"] + CONFIG["cancel_rate"]
chunks = []

for rep in reps.itertuples():
    region = CONFIG["regions"][rep.region_id]
    base_per_rep = region["seed"] / region["headcount"]

    for period in months:
        month_start = period.start_time.normalize()
        month_end = period.end_time.normalize()

        # days this rep was active in the month (hire and term dates are inclusive)
        active_start = max(rep.hire_date, month_start)
        active_end = month_end if pd.isna(rep.term_date) else min(rep.term_date, month_end)
        if active_end < active_start:
            continue
        active_days = (active_end - active_start).days + 1
        fraction = active_days / month_end.day

        # expected NET sales for this rep this month
        season = 1 + CONFIG["seasonality_amplitude"] * np.sin(2 * np.pi * (period.month - 3) / 12)
        noise = max(0.3, rng.normal(1.0, CONFIG["noise_sd"]))
        target_net = (
            base_per_rep
            * growth_factor[(rep.region_id, period.year)]
            * rep.skill_factor
            * season
            * noise
            * fraction
        )
        # order for enough GROSS sales that net lands near the target after losses
        target_gross = target_net / (1 - loss_rate)

        n_orders = max(1, int(round(target_gross / CONFIG["mean_order"])))
        amounts = rng.lognormal(0, CONFIG["order_sigma"], n_orders)
        amounts = amounts * (target_gross / amounts.sum())

        day_offsets = rng.integers(0, active_days, n_orders)
        sale_dates = active_start + pd.to_timedelta(day_offsets, unit="D")

        u = rng.random(n_orders)
        status = np.where(
            u < CONFIG["return_rate"], "returned",
            np.where(u < loss_rate, "canceled", "completed"),
        )
        lag = rng.integers(1, CONFIG["return_window_days"] + 1, n_orders)
        status_date = sale_dates + pd.to_timedelta(lag, unit="D")
        status_date = status_date.where(status != "completed", pd.NaT)

        chunks.append(
            pd.DataFrame(
                {
                    "sale_date": sale_dates,
                    "rep_id": rep.rep_id,
                    "region_id": rep.region_id,
                    "amount": amounts.round(2),
                    "status": status,
                    "status_date": status_date,
                }
            )
        )

sales = pd.concat(chunks, ignore_index=True)
sales = sales.sort_values(["sale_date", "rep_id"]).reset_index(drop=True)
sales.insert(0, "sale_id", [f"S{i + 1:06d}" for i in range(len(sales))])

# ---------------------------------------------------------------------------
# 6. CALENDAR: month boundaries and payout dates (spec item 5)
# ---------------------------------------------------------------------------
calendar = pd.DataFrame(
    {
        "month_start": [p.start_time.normalize() for p in months],
        "month_end": [p.end_time.normalize() for p in months],
    }
)
calendar["payout_date"] = calendar["month_end"] + pd.Timedelta(days=30)

# ---------------------------------------------------------------------------
# 7. SAVE
# ---------------------------------------------------------------------------
# - resolve from the repo root so it works from any folder
out = Path(__file__).resolve().parent.parent / CONFIG["output_dir"]
out.mkdir(parents=True, exist_ok=True)
for name, df in [("regions", regions), ("reps", reps), ("sales", sales), ("calendar", calendar)]:
    df.to_csv(out / f"{name}.csv", index=False, date_format="%Y-%m-%d")

# ---------------------------------------------------------------------------
# 8. VALIDATION: sanity checks against the spec
# ---------------------------------------------------------------------------
print("Rows:", {k: len(v) for k, v in [("regions", regions), ("reps", reps), ("sales", sales)]})

print("\nDepartures per year:")
print(reps["term_date"].dropna().dt.year.value_counts().sort_index().to_string())

print("\nReps active in any part of each month, min/max by region:")
rows = []
for period in months:
    ms, me = period.start_time.normalize(), period.end_time.normalize()
    active = reps[(reps["hire_date"] <= me) & (reps["term_date"].isna() | (reps["term_date"] >= ms))]
    rows.append(active.groupby("region_id").size().rename(period))
hc = pd.DataFrame(rows).fillna(0).astype(int)
print(hc.agg(["min", "max"]).to_string())

done = sales[sales["status"] == "completed"].copy()
done["month"] = done["sale_date"].dt.to_period("M")

print("\nNet sales by year, and YoY growth:")
by_year = done.groupby(done["sale_date"].dt.year)["amount"].sum()
print(pd.DataFrame({"net_sales": by_year.round(0), "yoy": by_year.pct_change().round(3)}).to_string())

print("\nNet sales by region and year (millions):")
print((done.groupby([done["sale_date"].dt.year, "region_id"])["amount"].sum().unstack() / 1e6).round(2).to_string())

rep_month = done.groupby(["rep_id", "month"])["amount"].sum().reset_index()
print("\nShare of rep-months by tier, by year:")
rep_month["year"] = rep_month["month"].dt.year
tiers = pd.cut(
    rep_month["amount"],
    [0, 25_000, 50_000, 75_000, 100_000, np.inf],
    right=False,
    labels=["<25K", "25-50K", "50-75K", "75-100K", "100K+"],
)
print(pd.crosstab(rep_month["year"], tiers, normalize="index").round(3).to_string())

print("\nCliff test: rep-months within $2,000 of each threshold (either side):")
for t in [25_000, 50_000, 75_000, 100_000]:
    near = rep_month[(rep_month["amount"] - t).abs() <= 2_000]
    print(f"  ${t:>7,}: {len(near)} of {len(rep_month)} rep-months")
