-- Load the 8 source files as-is. Every column is TEXT so nothing is lost or
-- silently converted; all fixing happens in 02_staging.sql.
-- Run psql from the project root: the \copy paths are relative to it.

DROP TABLE IF EXISTS raw.account, raw.client, raw.disposition, raw.permanent_order,
                     raw.transactions, raw.loan, raw.card, raw.district;

CREATE TABLE raw.account (account_id TEXT, district_id TEXT, frequency TEXT, date TEXT);
CREATE TABLE raw.client (client_id TEXT, birth_number TEXT, district_id TEXT);
CREATE TABLE raw.disposition (disp_id TEXT, client_id TEXT, account_id TEXT, type TEXT);
CREATE TABLE raw.permanent_order (order_id TEXT, account_id TEXT, bank_to TEXT,
                                  account_to TEXT, amount TEXT, k_symbol TEXT);
CREATE TABLE raw.transactions (trans_id TEXT, account_id TEXT, date TEXT, type TEXT,
                               operation TEXT, amount TEXT, balance TEXT, k_symbol TEXT,
                               bank TEXT, account TEXT);
CREATE TABLE raw.loan (loan_id TEXT, account_id TEXT, date TEXT, amount TEXT,
                       duration TEXT, payments TEXT, status TEXT);
CREATE TABLE raw.card (card_id TEXT, disp_id TEXT, type TEXT, issued TEXT);
CREATE TABLE raw.district (a1 TEXT, a2 TEXT, a3 TEXT, a4 TEXT, a5 TEXT, a6 TEXT, a7 TEXT, a8 TEXT,
                           a9 TEXT, a10 TEXT, a11 TEXT, a12 TEXT, a13 TEXT, a14 TEXT, a15 TEXT, a16 TEXT);

\copy raw.account         FROM 'data/raw/account.asc'  WITH (FORMAT csv, DELIMITER ';', HEADER true)
\copy raw.client          FROM 'data/raw/client.asc'   WITH (FORMAT csv, DELIMITER ';', HEADER true)
\copy raw.disposition     FROM 'data/raw/disp.asc'     WITH (FORMAT csv, DELIMITER ';', HEADER true)
\copy raw.permanent_order FROM 'data/raw/order.asc'    WITH (FORMAT csv, DELIMITER ';', HEADER true)
\copy raw.transactions    FROM 'data/raw/trans.asc'    WITH (FORMAT csv, DELIMITER ';', HEADER true)
\copy raw.loan            FROM 'data/raw/loan.asc'     WITH (FORMAT csv, DELIMITER ';', HEADER true)
\copy raw.card            FROM 'data/raw/card.asc'     WITH (FORMAT csv, DELIMITER ';', HEADER true)
\copy raw.district        FROM 'data/raw/district.asc' WITH (FORMAT csv, DELIMITER ';', HEADER true)
