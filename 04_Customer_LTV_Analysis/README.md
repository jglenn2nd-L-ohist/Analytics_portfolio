# 04 Customer LTV Analysis

## Business Context
Based in the UK with an international footprint spanning greater than 4,000 distinct customers. It is imperative to know the customer base and their patterns to best allocate resources and maximize revenue. The goal of this analysis is to reveal customer habits and patterns across borders.

## Business Questions
**Q1** What is the profile of our customers?
**Q2** What are customer buying habits: frequency, recency, and order value?
**Q3** Do purchasing patterns vary by country?
**Q4** How do customer cohorts retain over time?
**Q5** What is the average lifetime value by cohort?

## Data
- **Source:** Kaggle — UCI Online Retail Dataset
- **Raw:** 541,909 entries across 8 columns
- **Cleaned:** 392,692 processable entries (`ltvclean.csv`)
- **Customers:** 4,338 unique customers across 37 countries
- **Period:** December 2010 through December 2011

## Key Findings
- **Early cohorts outperform later ones.** The December 2010 cohort leads on both retention rates and average spend per transaction (£27/month). Average spend has declined consistently across cohorts through the observation period.
- **Geographic concentration carries risk.** Netherlands and EIRE dominate international revenue, but EIRE's figures are driven by 3 wholesale accounts. Volume and customer quality tell different stories.
- **Retention drops sharply after month 1.** Across all cohorts, the largest retention decline occurs between period 0 and period 1. Winning the second purchase is the critical inflection point.
- **Later cohort patterns are indeterminate.** Cohorts from July 2011 onward show compressed, similar behavior. Whether this reflects market saturation, seasonality, or data truncation cannot be determined from this dataset alone.

## Implications
- **Invest in Australia.** Australia ranks 4th or 5th across all three geographic metrics consistently: total revenue, average spend per customer, and purchase frequency. That consistency signals an engaged customer base with room to grow.
- **Investigate the August 2011 cohort.** The 2011-08 cohort shows 59% and 58% retention at periods 2 and 3, well above surrounding cohorts. Identifying what drove that behavior could provide a repeatable playbook.
- **Replace email with direct outreach after first purchase.** A phone-based contact campaign after first purchase builds a personal relationship before the customer goes dormant. The goal is to make the second purchase a natural next step rather than a response to a marketing event.

## Files
```
python/
    00_profile.py           — EDA pass, raw data shape and quality issues
    01_clean.py             — Six discrete cleaning operations in sequence
    q1_customer_profile.py  — Customer profile: spend distribution, purchase frequency
    q2_buying_habits.py     — Recency, frequency, monetary value per customer
    q3_country_habits.py    — Country-level segmentation, three horizontal bar charts
    q4_cohort.py            — Cohort retention matrix (13x13), seaborn heatmap
    q5_ltv.py               — Cohort average revenue matrix and executive bar chart

outputs/
    q1_purchase_distribution.png
    q1_customer_profile.csv
    q2_buying_habits.csv
    q3a_rev_by_country.png
    q3b_cus_spend_country.png
    q3c_purc_customer_country.png
    q4_cohort.png
    q5_ltv.png
    q5b_ltv_avg.png
```

## Dashboard
- PowerPoint Executive Briefing: `deliverables/ltv_analysis.pdf`

## Tools
- Python (Pandas, NumPy, Matplotlib, Seaborn)

## Status
Complete