# 10 - Rules Spec (pre-registered before any results are run)

Author: J. Glenn
Date: November 2026
Status: Skeleton. No decisions are recorded yet.
Rule: Once decisions are filled in and committed, this file is not edited after results are seen. Changes go in a dated Amendments section at the bottom, with the reason.

## 1. Question and stakeholder
- Stakeholder / decision: Category manager (parts manager). Decides whether to act on a complaint alert or wait.
- One-sentence question: When complaints on a make, model and component spike, how often does a recall follow, and how much lead time does the spike give?

## 2. Unit of analysis (grain)
- Starting grain: make x model x component group x month
- Decision:
- Why:

## 3. Scope filters
- Analysis window (recalls file starts 2010-01-01):
- Recall types in scope (type-code field: vehicle / equipment / child restraint / tire):
- Recall initiator split (MFR vs ODI): primary analysis or sensitivity only:

## 4. Event definitions
- Recall event date (report received date, owner notification date, or record creation date):
- Complaint date used as "received" (LDATE, date received by NHTSA, or DATEA, date added to file):
- Handling of the ~4% of complaints with a blank failure date:
- Leakage rule (complaints counted only if received before the cluster's event date):

## 5. Component crosswalk
- Complaint component to recall component mapping level (top-level segment or finer):
- Handling of complaints that list more than one component:
- Make-name standardization rule:

## 6. Spike definition
- Baseline window per cluster:
- Threshold (sigma multiple, or count-based / Poisson-style):
- Minimum monthly count floor (sparse cells make sigma unstable):
- Handling of the natural complaint ramp-up as a model year ages:

## 7. Outcome match rule
- A spike hits if a recall on the same cluster occurs within the primary horizon (6, 12, or 24 months):
- Right-censoring rule for spikes too close to the end of the data to have a full horizon:
- Base-rate comparison (how the random-flag benchmark is built):

## 8. Success criteria (set before results)
- Precision lift over base rate considered useful:
- Median lead time considered useful (IQR reported alongside):
- Result that counts as "signal is not reliable enough to act on":

## 9. Out of scope
- Warranty cost savings (no cost data)
- Supplier-level fault attribution
- Inventory orders (no safety stock or minimum order data)
- NHTSA investigations (downloaded, not used in this version)

## Amendments
(none)
