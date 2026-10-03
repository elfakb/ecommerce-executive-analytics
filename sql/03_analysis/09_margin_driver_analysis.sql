-- ============================================================
-- Margin bridge: Jan-Aug 2017 (p0) vs Jan-Aug 2018 (p1)
-- margin change = SUM(mix_effect) + SUM(rate_effect)
--   mix_effect  = (share1 - share0) * (margin0 - total_margin0)
--   rate_effect = share1 * (margin1 - margin0)
-- ============================================================
CREATE OR REPLACE VIEW v_margin_bridge AS
WITH base AS (
    SELECT (EXTRACT(YEAR FROM order_month) = 2018) AS is_2018,
           category,
           CASE
               WHEN customer_state IN ('SP','RJ','MG','ES')                          THEN 'Southeast'
               WHEN customer_state IN ('PR','SC','RS')                               THEN 'South'
               WHEN customer_state IN ('BA','SE','AL','PE','PB','RN','CE','PI','MA') THEN 'Northeast'
               WHEN customer_state IN ('DF','GO','MT','MS')                          THEN 'Central-West'
               ELSE 'North'
           END AS region,
           revenue, est_profit
    FROM v_order_items_enriched
    WHERE EXTRACT(MONTH FROM order_month) BETWEEN 1 AND 8
),
long AS (
    SELECT 'category' AS dim, category AS member, is_2018, revenue, est_profit FROM base
    UNION ALL
    SELECT 'region', region, is_2018, revenue, est_profit FROM base
),
agg AS (
    SELECT dim, member,
           COALESCE(SUM(revenue)    FILTER (WHERE NOT is_2018), 0) AS rev0,
           COALESCE(SUM(revenue)    FILTER (WHERE is_2018), 0)     AS rev1,
           COALESCE(SUM(est_profit) FILTER (WHERE NOT is_2018), 0) AS prof0,
           COALESCE(SUM(est_profit) FILTER (WHERE is_2018), 0)     AS prof1
    FROM long
    GROUP BY dim, member
),
calc AS (
    SELECT dim, member, rev0, rev1,
           rev0 / SUM(rev0) OVER (PARTITION BY dim) AS s0,
           rev1 / SUM(rev1) OVER (PARTITION BY dim) AS s1,
           COALESCE(prof0 / NULLIF(rev0, 0), prof1 / NULLIF(rev1, 0)) AS m0,
           COALESCE(prof1 / NULLIF(rev1, 0), prof0 / NULLIF(rev0, 0)) AS m1,
           SUM(prof0) OVER (PARTITION BY dim) / SUM(rev0) OVER (PARTITION BY dim) AS tot_m0
    FROM agg
)
SELECT dim, member, rev0, rev1, s0, s1, m0, m1,
       (s1 - s0) * (m0 - tot_m0) AS mix_effect,
       s1 * (m1 - m0)            AS rate_effect
FROM calc;

-- A) Headline bridge: how many pp of margin change come from mix vs rate?
--    (both dimensions should add up to the same total change)
SELECT dim,
       ROUND(100 * SUM(mix_effect), 2)                    AS mix_effect_pp,
       ROUND(100 * SUM(rate_effect), 2)                   AS rate_effect_pp,
       ROUND(100 * (SUM(mix_effect) + SUM(rate_effect)), 2) AS total_margin_change_pp
FROM v_margin_bridge
GROUP BY dim;

-- B) Cost structure per period: where does each revenue unit go?
SELECT CASE WHEN EXTRACT(YEAR FROM order_month) = 2018 THEN 'Jan-Aug 2018' ELSE 'Jan-Aug 2017' END AS period,
       ROUND(SUM(revenue), 0)                               AS revenue,
       ROUND(100.0 * SUM(est_cogs) / SUM(revenue), 2)       AS cogs_pct,
       ROUND(100.0 * SUM(freight) / SUM(revenue), 2)        AS freight_pct,
       ROUND(100.0 * SUM(est_profit) / SUM(revenue), 2)     AS margin_pct
FROM v_order_items_enriched
WHERE EXTRACT(MONTH FROM order_month) BETWEEN 1 AND 8
GROUP BY 1
ORDER BY 1;

-- C) Top 12 categories by total contribution to the margin change
SELECT member AS category,
       ROUND(100 * s0, 1) AS share_2017_pct,
       ROUND(100 * s1, 1) AS share_2018_pct,
       ROUND(100 * m0, 1) AS margin_2017_pct,
       ROUND(100 * m1, 1) AS margin_2018_pct,
       ROUND(100 * mix_effect, 3)  AS mix_effect_pp,
       ROUND(100 * rate_effect, 3) AS rate_effect_pp
FROM v_margin_bridge
WHERE dim = 'category'
ORDER BY ABS(mix_effect) + ABS(rate_effect) DESC
LIMIT 12;

-- D) Region view (geographic mix vs freight intensity)
SELECT member AS region,
       ROUND(100 * s0, 1) AS share_2017_pct,
       ROUND(100 * s1, 1) AS share_2018_pct,
       ROUND(100 * m0, 1) AS margin_2017_pct,
       ROUND(100 * m1, 1) AS margin_2018_pct,
       ROUND(100 * mix_effect, 3)  AS mix_effect_pp,
       ROUND(100 * rate_effect, 3) AS rate_effect_pp
FROM v_margin_bridge
WHERE dim = 'region'
ORDER BY s1 DESC;
