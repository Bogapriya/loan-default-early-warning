# Data dictionary and cleaning decisions

Source: *PKDD'99 Discovery Challenge – Guide to the Financial Data Set* (included in the data mirror). The original codes are in Czech. The `staging` schema translates them to English.

## Default definition
| status | Meaning | `is_default` | `is_finished` |
|---|---|---|---|
| A | contract finished, no problems | false | true |
| B | contract finished, loan not paid | **true** | true |
| C | running contract, OK so far | false | false |
| D | running contract, client in debt | **true** | false |

**Caveat:** a running loan marked C can still default later. Loans granted in 1998 have had very little time to go bad (their default rate is 2.5% against about 13% in earlier years), so recent loans understate risk.

## Code translations
| Table.column | Original | English |
|---|---|---|
| account.frequency | POPLATEK MESICNE / TYDNE / PO OBRATU | monthly / weekly / after_transaction (statement frequency) |
| disposition.type | OWNER / DISPONENT | owner / user |
| transactions.type | PRIJEM | credit |
| transactions.type | VYDAJ | debit |
| transactions.type | VYBER (*not in the documentation*) | debit; see the cleaning decisions below |
| transactions.operation | VYBER KARTOU / VKLAD / PREVOD Z UCTU / VYBER / PREVOD NA UCET | card_withdrawal / cash_deposit / transfer_in / cash_withdrawal / transfer_out |
| transactions.k_symbol | POJISTNE / SLUZBY / UROK / SANKC. UROK / SIPO / DUCHOD / UVER | insurance / statement_fee / interest_credited / penalty_interest / household / pension / loan_payment |
| permanent_order.k_symbol | POJISTNE / SIPO / LEASING / UVER | insurance / household / leasing / loan_payment |
| card.type | junior / classic / gold | unchanged |

## Cleaning decisions
1. **Dates** are `YYMMDD` text. They are converted with an explicit 1900s century, because PostgreSQL's two-digit-year rule would turn birth year `45` into 2045.
2. **Client gender and birth date** are decoded from `birth_number`: women have 50 added to the month (`YYMM+50DD`).
3. **Missing codes** appear three ways in the files: `""`, `" "` and an empty field. All three become `NULL`.
4. **Transaction type `VYBER`** (16,666 rows) is undocumented. Comparing each transaction with the previous balance, the balance falls by the amount in 12,092 cases and rises in none, so these rows are treated as debits.
5. **Transactions with no operation** (183,114 rows) are all interest credits. A quality check verifies this.
6. **District 69 (Jeseník)** has `?` for 1995 unemployment and 1995 crimes. These become `NULL`, and the 1996 values are used in analysis.
7. **Card issue date** looks like `931107 00:00:00`. Only the date part is kept.
8. **Currency:** the documentation does not state one. Amounts are reported as-is (most likely Czech koruna) and labelled "amount", never with a currency symbol.

## Quality checks
`sql/03_quality_checks.sql` runs 24 checks: row counts against the documentation, orphaned keys, one loan per account, one owner per account, loan amount equal to duration × payment, and that every code maps to a translation. All 24 pass. Results are stored in `mart.quality_checks`.
