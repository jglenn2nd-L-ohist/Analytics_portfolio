# Data Quality Summary - Customer Lifetime Value Analysis
**Project 04 | J.Glenn | July 2026**


--

## Overview
--
## Known Issues

| Issue | Severity | Analytical Impact | Resolution |
|---|---|---|---|
| 135,080 missing CustomerIDs | Critical | 24.9% of data unusable for cohort and LTV analysis | Drop rows where CustomerID is null |
| 1,454 missing Descriptions | Low | Minimal impact — Description not used in cohort or LTV calculations | Flag and retain |
| 5286 Duplicate entries | Medium | Minor impact - Under 1% duplication | Drop where duplicates are encountered |
| 9288 Cancelled orders | Medium | Moderate impact - Under 2% Cancelled orders | Drop so as not to skew calculations |
| Quantity & UnitPrice negative values | Medium | Impact is considerable - The negative quantities will corrupt the analysis | Dropping along with the Cancelled orders, 1336 quantity & 2 UnitPrice live outside of cancelled orders. These will be explicitly droppped |
| Improper InvoiceDate formatting | Critical | Unable to do cohort calculations | Date time formatting to be done |