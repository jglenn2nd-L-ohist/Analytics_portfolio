# 10 - NHTSA Complaint Surge Early-Warning Test

## Business Context

Supplier-quality and category managers see a steady stream of consumer complaints. Most never turn into recalls. A few do, and catching those early protects parts supply and warranty reserves. The hard part is telling the two apart.

This project tests whether a spike in consumer complaints on a vehicle component is a reliable early warning of an NHTSA recall, and how much lead time it gives. The question is framed as a manager's decision: when a complaint alert fires, act or wait?

The result is a signal-reliability test, not an average lag: precision lift over the base rate, sensitivity, and lead time as median and IQR. A weak signal is reported as a weak signal.

---

## Analyst Questions

Numbered by dependency order: Q1-Q3 establish that the data supports a valid test (load, crosswalk, event dates). Q4-Q6 are the substantive questions that test makes possible.

| # | Question |
|---|----------|
| Q1 | Do the loaded raw tables reconcile to the source files (row counts, field counts, date ranges)? |
| Q2 | Can complaint components be mapped to recall components at a defensible level (the crosswalk)? |
| Q3 | Are the event dates and the leakage rule defined so that no complaint filed after a recall is counted? |
| Q4 | Which make-model-component clusters show a spike under the pre-registered rule? |
| Q5 | How often does a spike precede a recall within 6, 12, and 24 months (precision, lift over base rate), and what share of recalls had a prior spike (sensitivity)? |
| Q6 | For true positives, what is the lead-time distribution (median, IQR) by subsystem? |

Rules are set in [`docs/rules_spec.md`](docs/rules_spec.md) before any results are run.

---

## Data

NHTSA Office of Defects Investigation bulk flat files, downloaded 2026-10-30. Provenance, row counts, field counts, and date ranges: [`data/README.md`](data/README.md).

| Table | Source file | Rows | Role |
|---|---|---|---|
| complaints | FLAT_CMPL.txt | 2,261,650 | Core |
| recalls | FLAT_RCL_POST_2010.txt | 247,021 | Core (one row per campaign, vehicle, and component) |

The analysis window is 2010 to October 2026, set by the start of the recalls file. Raw files are not in the repository (the complaints file is 1.6 GB, over GitHub's 100 MB limit). `data/raw/` is gitignored.

---

## Deliverables

| Deliverable | Description |
|---|---|
| One-page brief | Signal-reliability table by subsystem (precision lift, sensitivity, median and IQR lead time) with a plain-language recommendation for a supplier-quality or category manager. |
| Early-warning dashboard | Tableau Public view of complaint curves with the recall date marked, filtered by make and subsystem. Built from aggregated monthly counts. |

---

## Out of Scope

- Warranty cost savings. The public data has no cost information.
- Supplier-level fault attribution. NHTSA files identify the vehicle manufacturer, not the part supplier.
- Inventory replenishment orders. The public data has no safety stock or minimum order information.
- NHTSA investigations (`FLAT_INV.txt`). Downloaded, not used in this version.

---

## Project Structure

```
10_nhtsa_early_warning/
  data/raw/          NHTSA flat files, untouched (gitignored)
  data/processed/    derived tables and exports
  docs/              rules_spec.md
  sql/               question-mapped queries (q1_, q2_, ...)
  python/            load script
  images/            charts
  deliverables/      one-page brief, dashboard export, case study
```

---

## Status

In progress. Scaffold created 2026-10-30. Next: load the raw tables and reconcile row counts (Q1).
