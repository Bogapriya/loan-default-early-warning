# Data

**Source:** the PKDD'99 Discovery Challenge Financial Data Set (the "Berka dataset"). It contains real, anonymised data from a Czech bank for 1993–1998, prepared by Petr Berka and Marta Sochorová.

The 8 raw files are not stored in this repository. Download them from the public mirror at https://github.com/jlacko/berka-dataset, which also includes the original documentation PDF.

In Git Bash, from the project root:
```bash
git clone --depth 1 https://github.com/jlacko/berka-dataset.git /tmp/berka
cp /tmp/berka/*.asc data/raw/
ls data/raw
```
You should see: `account.asc card.asc client.asc disp.asc district.asc loan.asc order.asc trans.asc`.

| File | Rows | One row per |
|---|---:|---|
| account.asc | 4,500 | bank account |
| client.asc | 5,369 | client |
| disp.asc | 5,369 | client–account link (owner or user) |
| order.asc | 6,471 | standing payment order |
| trans.asc | 1,056,320 | transaction |
| loan.asc | 682 | loan (at most one per account) |
| card.asc | 892 | credit card |
| district.asc | 77 | district (demographics) |

Column meanings, code translations and cleaning decisions are in [`docs/data_dictionary.md`](../docs/data_dictionary.md).
