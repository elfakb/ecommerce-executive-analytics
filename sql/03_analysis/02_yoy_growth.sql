-- ------------------------------------------------------------
-- A) Monthly YoY: each 2018 month vs the same month of 2017
-- ------------------------------------------------------------
WITH monthly AS (
    SELECT order_month,
           SUM(revenue)             AS revenue,
           SUM(est_profit)          AS profit,
           COUNT(DISTINCT order_id) AS orders
    FROM v_order_items_enriched
    GROUP BY order_month
)
SELECT
    cur.order_month,
    ROUND(cur.revenue, 0)  AS revenue,
    ROUND(prev.revenue, 0) AS revenue_prev_year,
    ROUND(100.0 * (cur.revenue - prev.revenue) / prev.revenue, 1) AS revenue_yoy_pct,
    ROUND(100.0 * (cur.orders - prev.orders) / prev.orders, 1)    AS orders_yoy_pct,
    ROUND(100.0 * cur.profit / cur.revenue, 1)   AS margin_pct,
    ROUND(100.0 * prev.profit / prev.revenue, 1) AS margin_pct_prev_year
FROM monthly cur
JOIN monthly prev
  ON prev.order_month = (cur.order_month - INTERVAL '1 year')::date
ORDER BY cur.order_month;

-- ------------------------------------------------------------
-- B) Same-period comparison: Jan-Aug 2018 vs Jan-Aug 2017
--    (customers are counted distinct over the whole period,
--     so they cannot be summed from monthly numbers)
-- ------------------------------------------------------------
WITH period AS (
    SELECT
        EXTRACT(YEAR FROM order_month)::int  AS yr,
        SUM(revenue)                         AS revenue,
        SUM(freight)                         AS freight,
        SUM(est_profit)                      AS profit,
        COUNT(DISTINCT order_id)             AS orders,
        COUNT(DISTINCT customer_unique_id)   AS customers
    FROM v_order_items_enriched
    WHERE EXTRACT(MONTH FROM order_month) BETWEEN 1 AND 8
    GROUP BY 1
),
kpi AS (
    SELECT yr, revenue, profit, orders, customers,
           ROUND(100.0 * profit / revenue, 2)  AS margin_pct,
           ROUND(100.0 * freight / revenue, 2) AS freight_pct_of_rev,
           ROUND(revenue / orders, 2)          AS aov
    FROM period
)
SELECT
    yr,
    ROUND(revenue, 0) AS revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY yr)) / LAG(revenue) OVER (ORDER BY yr), 1) AS revenue_yoy_pct,
    ROUND(profit, 0)  AS profit,
    ROUND(100.0 * (profit - LAG(profit) OVER (ORDER BY yr)) / LAG(profit) OVER (ORDER BY yr), 1)    AS profit_yoy_pct,
    margin_pct,
    ROUND(margin_pct - LAG(margin_pct) OVER (ORDER BY yr), 2) AS margin_change_pp,
    freight_pct_of_rev,
    orders,
    ROUND(100.0 * (orders - LAG(orders) OVER (ORDER BY yr)) / LAG(orders) OVER (ORDER BY yr), 1)    AS orders_yoy_pct,
    aov,
    ROUND(100.0 * (aov - LAG(aov) OVER (ORDER BY yr)) / LAG(aov) OVER (ORDER BY yr), 1)             AS aov_yoy_pct,
    customers
FROM kpi
ORDER BY yr;
