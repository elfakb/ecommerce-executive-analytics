-- Monthly KPIs with MoM growth, 3-month moving average and cumulative revenue
WITH monthly AS (
    SELECT
        order_month,
        SUM(revenue)                      AS revenue,
        SUM(freight)                      AS freight,
        SUM(est_profit)                   AS profit,
        COUNT(DISTINCT order_id)          AS orders,
        COUNT(DISTINCT customer_unique_id) AS customers
    FROM v_order_items_enriched
    GROUP BY order_month
)
SELECT
    order_month,
    ROUND(revenue, 0)                                   AS revenue,
    ROUND(profit, 0)                                    AS profit,
    ROUND(100.0 * profit / revenue, 1)                  AS margin_pct,
    ROUND(100.0 * freight / revenue, 1)                 AS freight_pct_of_rev,
    orders,
    customers,
    ROUND(revenue / orders, 2)                          AS aov,
    ROUND(100.0 * (revenue - LAG(revenue) OVER w)
          / NULLIF(LAG(revenue) OVER w, 0), 1)          AS mom_growth_pct,
    ROUND(AVG(revenue) OVER (ORDER BY order_month
          ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0) AS revenue_3m_avg,
    ROUND(SUM(revenue) OVER (ORDER BY order_month), 0)  AS cumulative_revenue
FROM monthly
WINDOW w AS (ORDER BY order_month)
ORDER BY order_month;
