# 01 — Lead Attribution Analysis | Data In Motion

## Business Context
Data In Motion is a data analytics bootcamp. This analysis joins four datasets
across YouTube content, paid ads, and a third-party attribution platform (Hyros)
to identify which content channels and videos are actually driving leads and enrollments.

## Analyst Questions
- Q01: Which YouTube videos drive the most leads?
- Q02: What is the cost per lead by paid ad channel?
- Q03: How do videos classify as Closers vs. Validators based on first- and last-touch attribution?
- Q04: What is the cost per lead across paid channels?
- Q05: Where is the attribution gap — leads that entered the funnel but can't be sourced?

## Data
- Source: YouTube analytics export, Hyros attribution export, paid ad spend data
- ~2,737 leads analyzed

## Key Findings
- ~40% of leads attributed to YouTube content
- 32% attribution gap identified — leads with no traceable source
- Top Closer and Validator videos identified by first- and last-touch lead count

## Files
| File | Purpose |
|------|---------|
| `sql/01_top_videos.sql` | Top YouTube videos by lead volume |
| `sql/02_cost_per_lead.sql` | Cost per lead by paid channel |
| `sql/03_content_taxonomy.sql` | Closer vs. Validator classification using CTE chaining |
| `sql/04_paid_ads.sql` | Paid ad performance aggregation |
| `sql/05_attribution_gap.sql` | LEFT JOIN to surface unattributed leads |
| `python/` | Supporting visualizations |

## Tools
SQL (SQLite) · Python (pandas, matplotlib) · Tableau

## Status
✅ Complete — [View Tableau Dashboard](https://public.tableau.com/shared/XM7H3HQ3K?:display_count=n&:origin=viz_share_link)