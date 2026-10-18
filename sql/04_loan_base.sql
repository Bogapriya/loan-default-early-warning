-- One row per loan with the account, branch district and account owner attached.
-- This is the base table for exploration, Power BI and (later) the model.

-- 95% Wilson confidence interval for a proportion: better than the normal
-- approximation when counts are small, which they are here (682 loans).
CREATE OR REPLACE FUNCTION mart.wilson_low(x BIGINT, n BIGINT, z NUMERIC DEFAULT 1.96)
RETURNS NUMERIC LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE WHEN n = 0 THEN NULL ELSE
        ((x::numeric / n) + z*z / (2*n)
         - z * sqrt((x::numeric / n) * (1 - x::numeric / n) / n + z*z / (4*n*n)))
        / (1 + z*z / n) END
$$;

CREATE OR REPLACE FUNCTION mart.wilson_high(x BIGINT, n BIGINT, z NUMERIC DEFAULT 1.96)
RETURNS NUMERIC LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE WHEN n = 0 THEN NULL ELSE
        ((x::numeric / n) + z*z / (2*n)
         + z * sqrt((x::numeric / n) * (1 - x::numeric / n) / n + z*z / (4*n*n)))
        / (1 + z*z / n) END
$$;

DROP VIEW IF EXISTS mart.loan_base;
CREATE VIEW mart.loan_base AS
SELECT l.loan_id,
       l.account_id,
       l.granted_date,
       extract(year FROM l.granted_date)::int                       AS granted_year,
       l.amount,
       l.duration_months,
       l.monthly_payment,
       l.status_code,
       l.status_desc,
       l.is_default,
       l.is_finished,
       a.statement_frequency,
       a.opened_date                                                AS account_opened_date,
       (l.granted_date - a.opened_date)                             AS account_age_days_at_loan,
       d.district_id,
       d.district_name,
       d.region,
       d.avg_salary                                                 AS district_avg_salary,
       d.unemployment_rate_96                                       AS district_unemployment_96,
       c.client_id                                                  AS owner_client_id,
       c.gender                                                     AS owner_gender,
       date_part('year', age(l.granted_date, c.birth_date))::int    AS owner_age_at_loan
FROM staging.loan l
JOIN staging.account a     ON a.account_id = l.account_id
JOIN staging.district d    ON d.district_id = a.district_id
JOIN staging.disposition x ON x.account_id = l.account_id AND x.disp_type = 'owner'
JOIN staging.client c      ON c.client_id = x.client_id;
