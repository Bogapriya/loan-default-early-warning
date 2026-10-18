# Loan Default Early Warning (SQL + Power BI)

**Question:** Using only what a bank knows *before* it approves a loan, which warning signs predict default, and how many defaults could a simple review rule catch?

**Data:** 682 real loans, 4,500 accounts and 1.06 million transactions from a Czech bank, 1993–1998 (the PKDD'99 "Berka" dataset, anonymised).
**Stack:** PostgreSQL (CTEs, window functions), Power BI (star schema, DAX), Python for validation.

> 🚧 **Status: in progress.** Week 1 (load, clean, quality checks, first exploration) is complete. See the [roadmap](#roadmap).

## Early findings (week 1)
- **11.1% of loans defaulted** (76 of 682; 95% CI 9.0–13.7%). "Default" means finished unpaid (B) or running and in debt (D).
- **Large loans are the clearest risk signal so far.** Loans in the top amount quartile default at **20.0%** (CI 14.7–26.6%), against **7.6%** for each of the two lowest quartiles (CI 4.5–12.6%).
- **Loan length shows no clear effect.** Default rates are 8–12% across 12- to 60-month terms, and the intervals overlap.
- **Regional differences are mostly noise.** Rates range from 1.6% to 15.8%, but every region has fewer than 130 loans, so the intervals are wide.
- **Watch the timeline.** Loans granted in 1998 show only 2.5% default because they have had little time to go bad. Recent loans understate risk.

## How it's built
```
raw (files as delivered) ──► staging (typed, translated, cleaned) ──► mart (analysis tables)
```
| Step | File | What it does |
|---|---|---|
| 0 | `sql/00_schemas.sql` | Creates the `raw`, `staging` and `mart` layers |
| 1 | `sql/01_load_raw.sql` | Loads the 8 files as text, so nothing is silently converted |
| 2 | `sql/02_staging.sql` | Fixes types and dates, decodes gender from birth numbers, translates Czech codes |
| 3 | `sql/03_quality_checks.sql` | Runs 24 checks (row counts, orphaned keys, business rules); all pass |
| 4 | `sql/04_loan_base.sql` | Builds one row per loan with account, district and owner, plus a Wilson confidence-interval function |
| 5 | `sql/05_explore_defaults.sql` | Default rates by segment, each with a 95% confidence interval |

Cleaning decisions (for example, the undocumented `VYBER` transaction type and district 69's missing values) are explained in [`docs/data_dictionary.md`](docs/data_dictionary.md).

## Run it
1. Install PostgreSQL (version 15 or later).
2. Download the data into `data/raw/` (see [`data/README.md`](data/README.md)).
3. From the project root:
```bash
createdb -U postgres berka
psql -U postgres -d berka -f sql/run_all.sql
psql -U postgres -d berka -f sql/05_explore_defaults.sql
```

## Roadmap
- [x] **Week 1:** load, clean and quality-check the 8 tables; first default-rate exploration
- [ ] **Week 2:** pre-loan behaviour features from transactions *before* the loan date (balances, negative-balance months, penalty interest, income vs. repayment). Using later data would leak the outcome.
- [ ] **Week 3:** Power BI star schema (fact_loan plus district, date and client dimensions) with DAX measures. Two pages: portfolio overview and an early-warning watchlist.
- [ ] **Week 4:** a simple review rule and how many defaults it catches for a given review workload, validated in Python
- [ ] **Week 5:** final findings, limitations, dashboard screenshots

## Limitations
- Only 682 loans (76 defaults), so segment results carry wide uncertainty. Confidence intervals are always shown.
- 1990s Czech banking data, so the patterns and methods transfer but the exact numbers don't.
- The currency is not stated in the source documentation, so amounts are unlabelled.

---
Bogapriya Muralikannan · [LinkedIn](YOUR-LINKEDIN-URL)
