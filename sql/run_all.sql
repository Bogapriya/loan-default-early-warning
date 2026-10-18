-- Builds the whole database from the raw files. Run from the project root:
--   psql -U postgres -d berka -f sql/run_all.sql

\set ON_ERROR_STOP on
\echo 'Creating schemas...'
\ir 00_schemas.sql
\echo 'Loading raw files (trans.asc has about 1 million rows; this takes a minute)...'
\ir 01_load_raw.sql
\echo 'Building staging tables...'
\ir 02_staging.sql
\echo 'Running data-quality checks...'
\ir 03_quality_checks.sql
\echo 'Building mart.loan_base...'
\ir 04_loan_base.sql
\echo 'Done. Next: psql -U postgres -d berka -f sql/05_explore_defaults.sql'
