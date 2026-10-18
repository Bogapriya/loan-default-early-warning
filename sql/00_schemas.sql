-- Three layers, each with its own job:
--   raw     : files loaded exactly as delivered (all text, nothing fixed)
--   staging : typed, translated, cleaned tables (one per source file)
--   mart    : analysis-ready tables and views for Power BI and modelling

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS mart;
