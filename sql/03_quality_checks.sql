-- Data-quality checks. Every row should say PASS; anything else needs a look
-- before analysis. Results are also saved to mart.quality_checks.

DROP TABLE IF EXISTS mart.quality_checks;
CREATE TABLE mart.quality_checks AS
WITH checks (check_name, expected, actual) AS (
    -- 1. Row counts match the official documentation
    SELECT 'rows: account',         4500,    (SELECT count(*) FROM staging.account)
    UNION ALL SELECT 'rows: client',          5369,    (SELECT count(*) FROM staging.client)
    UNION ALL SELECT 'rows: disposition',     5369,    (SELECT count(*) FROM staging.disposition)
    UNION ALL SELECT 'rows: permanent_order', 6471,    (SELECT count(*) FROM staging.permanent_order)
    UNION ALL SELECT 'rows: transactions',    1056320, (SELECT count(*) FROM staging.transactions)
    UNION ALL SELECT 'rows: loan',            682,     (SELECT count(*) FROM staging.loan)
    UNION ALL SELECT 'rows: card',            892,     (SELECT count(*) FROM staging.card)
    UNION ALL SELECT 'rows: district',        77,      (SELECT count(*) FROM staging.district)

    -- 2. Referential integrity: every foreign key points to an existing row
    UNION ALL SELECT 'orphans: account -> district', 0,
        (SELECT count(*) FROM staging.account a
         WHERE NOT EXISTS (SELECT 1 FROM staging.district d WHERE d.district_id = a.district_id))
    UNION ALL SELECT 'orphans: client -> district', 0,
        (SELECT count(*) FROM staging.client c
         WHERE NOT EXISTS (SELECT 1 FROM staging.district d WHERE d.district_id = c.district_id))
    UNION ALL SELECT 'orphans: disposition -> client/account', 0,
        (SELECT count(*) FROM staging.disposition x
         WHERE NOT EXISTS (SELECT 1 FROM staging.client c  WHERE c.client_id = x.client_id)
            OR NOT EXISTS (SELECT 1 FROM staging.account a WHERE a.account_id = x.account_id))
    UNION ALL SELECT 'orphans: transactions -> account', 0,
        (SELECT count(*) FROM staging.transactions t
         WHERE NOT EXISTS (SELECT 1 FROM staging.account a WHERE a.account_id = t.account_id))
    UNION ALL SELECT 'orphans: loan -> account', 0,
        (SELECT count(*) FROM staging.loan l
         WHERE NOT EXISTS (SELECT 1 FROM staging.account a WHERE a.account_id = l.account_id))
    UNION ALL SELECT 'orphans: card -> disposition', 0,
        (SELECT count(*) FROM staging.card k
         WHERE NOT EXISTS (SELECT 1 FROM staging.disposition x WHERE x.disp_id = k.disp_id))

    -- 3. Business rules from the documentation
    UNION ALL SELECT 'at most one loan per account', 0,
        (SELECT count(*) FROM (SELECT account_id FROM staging.loan
                               GROUP BY account_id HAVING count(*) > 1) s)
    UNION ALL SELECT 'every account has exactly one owner', 0,
        (SELECT count(*) FROM staging.account a
         WHERE (SELECT count(*) FROM staging.disposition x
                WHERE x.account_id = a.account_id AND x.disp_type = 'owner') <> 1)
    UNION ALL SELECT 'loan amount = duration x monthly payment', 0,
        (SELECT count(*) FROM staging.loan
         WHERE abs(amount - duration_months * monthly_payment) > 1)
    UNION ALL SELECT 'loan granted after account opened', 0,
        (SELECT count(*) FROM staging.loan l JOIN staging.account a USING (account_id)
         WHERE l.granted_date < a.opened_date)

    -- 4. Values decoded correctly (an unmapped code would become NULL)
    UNION ALL SELECT 'unmapped statement_frequency', 0,
        (SELECT count(*) FROM staging.account WHERE statement_frequency IS NULL)
    UNION ALL SELECT 'unmapped disposition type', 0,
        (SELECT count(*) FROM staging.disposition WHERE disp_type IS NULL)
    UNION ALL SELECT 'unmapped loan status', 0,
        (SELECT count(*) FROM staging.loan WHERE status_desc IS NULL)
    UNION ALL SELECT 'transactions with no operation that are not interest credits', 0,
        (SELECT count(*) FROM staging.transactions
         WHERE operation IS NULL AND purpose IS DISTINCT FROM 'interest_credited')
    UNION ALL SELECT 'transaction dates within 1993-1998', 0,
        (SELECT count(*) FROM staging.transactions
         WHERE trans_date NOT BETWEEN DATE '1993-01-01' AND DATE '1998-12-31')

    -- 5. Known gaps (documented, not errors)
    UNION ALL SELECT 'district values marked ''?'' (district 69, 1995 stats)', 2,
        (SELECT count(*) FILTER (WHERE unemployment_rate_95 IS NULL)
              + count(*) FILTER (WHERE crimes_95 IS NULL) FROM staging.district)
)
SELECT check_name, expected, actual,
       CASE WHEN expected = actual THEN 'PASS' ELSE 'CHECK' END AS result
FROM checks;

SELECT * FROM mart.quality_checks;
