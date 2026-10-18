-- Week 1 exploration: how often do loans default, and does it differ by segment?
-- Every rate comes with a 95% confidence interval: with only 76 defaults,
-- many segment differences are noise.

\echo '1. Overall default rate'
SELECT count(*)                                              AS loans,
       count(*) FILTER (WHERE is_default)                    AS defaults,
       round(100.0 * avg(is_default::int), 1)                AS default_rate_pct,
       round(100 * mart.wilson_low(count(*) FILTER (WHERE is_default), count(*)), 1)  AS ci_low_pct,
       round(100 * mart.wilson_high(count(*) FILTER (WHERE is_default), count(*)), 1) AS ci_high_pct
FROM mart.loan_base;

\echo '2. Loan status breakdown'
SELECT status_code, status_desc, count(*) AS loans,
       round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS share_pct
FROM mart.loan_base
GROUP BY status_code, status_desc
ORDER BY status_code;

\echo '3. Default rate by loan duration'
SELECT duration_months,
       count(*)                                              AS loans,
       count(*) FILTER (WHERE is_default)                    AS defaults,
       round(100.0 * avg(is_default::int), 1)                AS default_rate_pct,
       round(100 * mart.wilson_low(count(*) FILTER (WHERE is_default), count(*)), 1)  AS ci_low_pct,
       round(100 * mart.wilson_high(count(*) FILTER (WHERE is_default), count(*)), 1) AS ci_high_pct
FROM mart.loan_base
GROUP BY duration_months
ORDER BY duration_months;

\echo '4. Default rate by loan amount quartile'
WITH q AS (
    SELECT *, ntile(4) OVER (ORDER BY amount) AS amount_quartile FROM mart.loan_base
)
SELECT amount_quartile,
       min(amount)::int AS min_amount, max(amount)::int AS max_amount,
       count(*) AS loans,
       count(*) FILTER (WHERE is_default) AS defaults,
       round(100.0 * avg(is_default::int), 1) AS default_rate_pct,
       round(100 * mart.wilson_low(count(*) FILTER (WHERE is_default), count(*)), 1)  AS ci_low_pct,
       round(100 * mart.wilson_high(count(*) FILTER (WHERE is_default), count(*)), 1) AS ci_high_pct
FROM q
GROUP BY amount_quartile
ORDER BY amount_quartile;

\echo '5. Default rate by region of the account branch'
SELECT region,
       count(*) AS loans,
       count(*) FILTER (WHERE is_default) AS defaults,
       round(100.0 * avg(is_default::int), 1) AS default_rate_pct,
       round(100 * mart.wilson_low(count(*) FILTER (WHERE is_default), count(*)), 1)  AS ci_low_pct,
       round(100 * mart.wilson_high(count(*) FILTER (WHERE is_default), count(*)), 1) AS ci_high_pct
FROM mart.loan_base
GROUP BY region
ORDER BY default_rate_pct DESC;

\echo '6. Loans by year granted (watch out: recent loans have had less time to go bad)'
SELECT granted_year,
       count(*) AS loans,
       count(*) FILTER (WHERE is_finished) AS finished,
       count(*) FILTER (WHERE is_default)  AS defaults,
       round(100.0 * avg(is_default::int), 1) AS default_rate_pct
FROM mart.loan_base
GROUP BY granted_year
ORDER BY granted_year;
