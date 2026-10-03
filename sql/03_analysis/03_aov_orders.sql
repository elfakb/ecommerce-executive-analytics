-- AOV decomposition: AOV = items per order x average item price
WITH monthly AS (
    SELECT
        order_month,
        COUNT(*)                         AS orders,
        SUM(items)                       AS items,
        SUM(revenue)                     AS revenue
    FROM v_orders_summary
    GROUP BY order_month
)
SELECT
    order_month,
    orders,
    ROUND(revenue / orders, 2)           AS aov,
    ROUND(items::numeric / orders, 3)    AS items_per_order,
    ROUND(revenue / items, 2)            AS avg_item_price,
    ROUND(100.0 * (revenue / orders - LAG(revenue / orders) OVER (ORDER BY order_month))
          / LAG(revenue / orders) OVER (ORDER BY order_month), 1) AS aov_mom_pct
FROM monthly
ORDER BY order_month;

-- Order size distribution (how concentrated are orders?)
SELECT
    CASE
        WHEN revenue < 50   THEN '1) < 50'
        WHEN revenue < 100  THEN '2) 50-99'
        WHEN revenue < 200  THEN '3) 100-199'
        WHEN revenue < 500  THEN '4) 200-499'
        ELSE                     '5) 500+'
    END AS order_value_band,
    COUNT(*)                                                  AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)        AS pct_of_orders,
    ROUND(100.0 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1) AS pct_of_revenue
FROM v_orders_summary
GROUP BY 1
ORDER BY 1;
