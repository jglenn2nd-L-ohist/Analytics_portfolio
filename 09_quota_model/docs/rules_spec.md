# Project 09: Quota and Commission Model, Rules Specification

## Project principles

**1. Business and structure.** The business sells automotive replacement parts. The market is divided into 4 distinct regions. Territories are subsets of each region, but they are not predefined: they emerge from the work of the sales reps. The company has 20 sales reps in total (regional breakdown: 2, 5, 5, 8). The period under analysis is 60 months covering 5 calendar years. The calendar year is the fiscal year. Analysis is done at the **rep and region** level; territory is a descriptive label only.

**2. Completed sales.** A completed sale is one that has not been canceled or returned. The return window is 30 days. Only completed sales count as **net sales**.

**3. Margin.** Company gross margin is 50% across the board, with no variance for product mix.

**4. Commission.** Commission is paid on **gross margin dollars**, not on sales dollars. The rate is selected from the tier table below using the rep's **monthly net sales**. The selected rate applies to **all** of that month's margin dollars (a flat structure, not marginal). The maximum commission rate is 60%. There is no cap on total payout and no minimum sales threshold before commission begins. There are no bonuses: commission is the only pay.

| Monthly net sales | Rate on margin dollars |
|---|---|
| $0 to $24,999 | 25% |
| $25,000 to $49,999 | 33% |
| $50,000 to $74,999 | 42% |
| $75,000 to $99,999 | 51% |
| $100,000 and above | 60% (maximum rate) |

A commission rate above **45% of margin** is the company's warning line. The warning line sits on the $75,000 threshold.

**5. Payout timing.** Commission for a sales month is calculated after that month's sales have cleared the 30-day return window, so it is not affected by pending returns. It is paid in a single monthly payout. The payout date is 30 days after the end of the sales month. There are no clawbacks.

**6. Quota.** Quotas are set at the **regional** level and have no effect on rep pay. They are a growth benchmark only. A region's monthly quota equals its net sales in the same month of the prior year multiplied by 1.15 (15% year-over-year growth target). Year 1 has no prior year, so each region's monthly quota is seeded from a stated base (placeholder values below, to be adjusted before data generation):

| Region | Reps | Year 1 monthly quota seed |
|---|---|---|
| Region 1 | 2 | $150,000 |
| Region 2 | 5 | $275,000 |
| Region 3 | 5 | $300,000 |
| Region 4 | 8 | $400,000 |

The seeds intentionally give Region 1 the highest sales per rep, so thinly staffed regions sit nearer the upper tiers.

**7. Turnover.** Annual turnover is 25%, which is about 5 departures per year across 20 seats. A vacant position is filled within 45 days of the vacancy, so regional headcount can briefly dip below target. A departing rep is paid normally for their final partial month. A new hire starts at zero sales with no ramp period and no quota.

**8. Growth.** The generator grows each region’s actual sales 15% per year plus a random region-year wobble (SD 4 points). Realized company net sales growth came out near 13% per year (12.9% compounded, 2021 to 2025). The data was not re-tuned to hit 15%. The quota growth target (spec item 6) is also 15%.

**9. Question and definition of overpay.**

*Question:* Does the commission structure overpay because of its flat-tier structure? If so, where and how much?

*Overpay* is the additional income a rep gains by crossing a threshold into the next tier, because the higher rate applies to all margin dollars rather than only to the dollars above the threshold. It is measured two ways:

- **Threshold jump (the cliff).** The change in commission caused by crossing a tier edge. Example: a rep at $74,999 in net sales earns about $15,750. At $75,005 the same rep earns about $19,126, a jump of about **$3,376** for $6 of additional sales.
- **Total overpay (headline measure).** Commission paid under the flat structure minus the commission a marginal structure would have paid on the same sales, where each rate applies only to the dollars inside its band. For the $75,005 example, flat pays about $19,126 and marginal pays about $12,501, an overpay of about **$6,625**.

Total overpay is summarized by region, by year, and in aggregate. The blended payout rate (total commission divided by total margin) is compared against the 45% warning line and the 60% maximum.

**10. Skill_fator** Rep skill factor (generator only). Each rep gets a hidden skill_factor, drawn once from a normal distribution (mean 1.0, SD 0.15, clipped to 0.6 to 1.4) when the rep is created. A replacement rep gets a new draw. It multiplies that rep’s expected monthly net sales. It is stored in reps.csv, is not in rep_month.csv, and the Excel model does not use it.

## Assumptions and limits

- All data is synthetic.
- The calendar year is the fiscal year.
- Gross margin is a flat 50%, with no product mix.
- Commission is calculated on margin dollars, not sales dollars.
- There are no bonuses and no clawbacks.
- Quotas are a regional benchmark and do not affect pay.
- Tier bands are fixed for all 5 years, so growth pushes more rep-months into higher tiers over time. This is intended.
- The year-1 quota seeds in item 6 are placeholders.