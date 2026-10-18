-- Typed, cleaned and translated tables (Czech codes -> English).
-- Cleaning decisions are listed in docs/data_dictionary.md.

-- Dates arrive as YYMMDD text. All dates in this dataset are 19xx, so the
-- century is set explicitly (Postgres' 'YY' would turn birth year 45 into 2045).
CREATE OR REPLACE FUNCTION staging.yymmdd_to_date(v TEXT) RETURNS DATE
LANGUAGE sql IMMUTABLE AS $$
    SELECT make_date(1900 + substr(v, 1, 2)::int, substr(v, 3, 2)::int, substr(v, 5, 2)::int)
$$;

-- Blank, single-space and empty-string codes all mean "missing".
CREATE OR REPLACE FUNCTION staging.blank_to_null(v TEXT) RETURNS TEXT
LANGUAGE sql IMMUTABLE AS $$
    SELECT NULLIF(trim(v), '')
$$;

-- District (77 rows). District 69 has '?' for two values -> NULL.
DROP TABLE IF EXISTS staging.district CASCADE;
CREATE TABLE staging.district AS
SELECT a1::int                           AS district_id,
       a2                                AS district_name,
       a3                                AS region,
       a4::int                           AS inhabitants,
       a5::int                           AS municipalities_lt_500,
       a6::int                           AS municipalities_500_1999,
       a7::int                           AS municipalities_2000_9999,
       a8::int                           AS municipalities_ge_10000,
       a9::int                           AS n_cities,
       a10::numeric                      AS urban_ratio_pct,
       a11::int                          AS avg_salary,
       NULLIF(a12, '?')::numeric         AS unemployment_rate_95,
       a13::numeric                      AS unemployment_rate_96,
       a14::int                          AS entrepreneurs_per_1000,
       NULLIF(a15, '?')::int             AS crimes_95,
       a16::int                          AS crimes_96
FROM raw.district;
ALTER TABLE staging.district ADD PRIMARY KEY (district_id);

-- Account (4,500 rows)
DROP TABLE IF EXISTS staging.account CASCADE;
CREATE TABLE staging.account AS
SELECT account_id::int                       AS account_id,
       district_id::int                      AS district_id,
       CASE frequency
            WHEN 'POPLATEK MESICNE'   THEN 'monthly'
            WHEN 'POPLATEK TYDNE'     THEN 'weekly'
            WHEN 'POPLATEK PO OBRATU' THEN 'after_transaction'
       END                                   AS statement_frequency,
       staging.yymmdd_to_date(date)          AS opened_date
FROM raw.account;
ALTER TABLE staging.account ADD PRIMARY KEY (account_id);

-- Client (5,369 rows). birth_number is YYMMDD for men and YY(MM+50)DD for women.
DROP TABLE IF EXISTS staging.client CASCADE;
CREATE TABLE staging.client AS
SELECT client_id::int AS client_id,
       CASE WHEN substr(birth_number, 3, 2)::int > 50 THEN 'F' ELSE 'M' END AS gender,
       make_date(1900 + substr(birth_number, 1, 2)::int,
                 substr(birth_number, 3, 2)::int
                   - CASE WHEN substr(birth_number, 3, 2)::int > 50 THEN 50 ELSE 0 END,
                 substr(birth_number, 5, 2)::int)                           AS birth_date,
       district_id::int AS district_id
FROM raw.client;
ALTER TABLE staging.client ADD PRIMARY KEY (client_id);

-- Disposition (5,369 rows): links clients to accounts.
DROP TABLE IF EXISTS staging.disposition CASCADE;
CREATE TABLE staging.disposition AS
SELECT disp_id::int    AS disp_id,
       client_id::int  AS client_id,
       account_id::int AS account_id,
       CASE type WHEN 'OWNER' THEN 'owner' WHEN 'DISPONENT' THEN 'user' END AS disp_type
FROM raw.disposition;
ALTER TABLE staging.disposition ADD PRIMARY KEY (disp_id);

-- Permanent order (6,471 rows)
DROP TABLE IF EXISTS staging.permanent_order CASCADE;
CREATE TABLE staging.permanent_order AS
SELECT order_id::int     AS order_id,
       account_id::int   AS account_id,
       bank_to,
       account_to,
       amount::numeric(12, 2) AS amount,
       CASE staging.blank_to_null(k_symbol)
            WHEN 'POJISTNE' THEN 'insurance'
            WHEN 'SIPO'     THEN 'household'
            WHEN 'LEASING'  THEN 'leasing'
            WHEN 'UVER'     THEN 'loan_payment'
       END AS purpose
FROM raw.permanent_order;
ALTER TABLE staging.permanent_order ADD PRIMARY KEY (order_id);

-- Transactions (1,056,320 rows).
-- 'VYBER' is not in the documentation as a type; the balance always falls by the
-- amount for these rows, so they are treated as debits (cash withdrawals).
DROP TABLE IF EXISTS staging.transactions CASCADE;
CREATE TABLE staging.transactions AS
SELECT trans_id::int                     AS trans_id,
       account_id::int                   AS account_id,
       staging.yymmdd_to_date(date)      AS trans_date,
       CASE WHEN type = 'PRIJEM' THEN 'credit' ELSE 'debit' END AS direction,
       amount::numeric(12, 2)            AS amount,
       CASE WHEN type = 'PRIJEM' THEN amount::numeric(12, 2)
            ELSE -amount::numeric(12, 2) END                     AS signed_amount,
       balance::numeric(12, 2)           AS balance,
       CASE staging.blank_to_null(operation)
            WHEN 'VYBER KARTOU'   THEN 'card_withdrawal'
            WHEN 'VKLAD'          THEN 'cash_deposit'
            WHEN 'PREVOD Z UCTU'  THEN 'transfer_in'
            WHEN 'VYBER'          THEN 'cash_withdrawal'
            WHEN 'PREVOD NA UCET' THEN 'transfer_out'
       END                               AS operation,
       CASE staging.blank_to_null(k_symbol)
            WHEN 'POJISTNE'    THEN 'insurance'
            WHEN 'SLUZBY'      THEN 'statement_fee'
            WHEN 'UROK'        THEN 'interest_credited'
            WHEN 'SANKC. UROK' THEN 'penalty_interest'
            WHEN 'SIPO'        THEN 'household'
            WHEN 'DUCHOD'      THEN 'pension'
            WHEN 'UVER'        THEN 'loan_payment'
       END                               AS purpose,
       staging.blank_to_null(bank)       AS partner_bank,
       staging.blank_to_null(account)    AS partner_account
FROM raw.transactions;
ALTER TABLE staging.transactions ADD PRIMARY KEY (trans_id);
CREATE INDEX ON staging.transactions (account_id, trans_date);

-- Loan (682 rows). Default = finished unpaid (B) or running and in debt (D).
DROP TABLE IF EXISTS staging.loan CASCADE;
CREATE TABLE staging.loan AS
SELECT loan_id::int                   AS loan_id,
       account_id::int                AS account_id,
       staging.yymmdd_to_date(date)   AS granted_date,
       amount::numeric(12, 2)         AS amount,
       duration::int                  AS duration_months,
       payments::numeric(12, 2)       AS monthly_payment,
       status                         AS status_code,
       CASE status
            WHEN 'A' THEN 'finished - paid'
            WHEN 'B' THEN 'finished - not paid'
            WHEN 'C' THEN 'running - OK'
            WHEN 'D' THEN 'running - in debt'
       END                            AS status_desc,
       status IN ('B', 'D')           AS is_default,
       status IN ('A', 'B')           AS is_finished
FROM raw.loan;
ALTER TABLE staging.loan ADD PRIMARY KEY (loan_id);

-- Card (892 rows). issued looks like '931107 00:00:00'; only the date part is used.
DROP TABLE IF EXISTS staging.card CASCADE;
CREATE TABLE staging.card AS
SELECT card_id::int                               AS card_id,
       disp_id::int                               AS disp_id,
       type                                       AS card_type,
       staging.yymmdd_to_date(left(issued, 6))    AS issued_date
FROM raw.card;
ALTER TABLE staging.card ADD PRIMARY KEY (card_id);

ANALYZE staging.transactions;
