-- A) Category profitability with revenue/profit shares and profit rank
WITH cat AS (
    SELECT category,
           SUM(revenue)             AS revenue,
           SUM(freight)             AS freight,
           SUM(est_profit)          AS profit,
           COUNT(DISTINCT order_id) AS orders
    FROM v_order_items_enriched
    GROUP BY category
)
SELECT
    category,
    ROUND(revenue, 0)                          AS revenue,
    ROUND(profit, 0)                           AS profit,
    ROUND(100.0 * profit / revenue, 1)         AS margin_pct,
    ROUND(100.0 * freight / revenue, 1)        AS freight_pct_of_rev,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 1) AS revenue_share_pct,
    ROUND(100.0 * profit  / SUM(profit)  OVER (), 1) AS profit_share_pct,
    RANK() OVER (ORDER BY profit DESC)         AS profit_rank
FROM cat
ORDER BY profit DESC;

-- B) Items where freight eats the whole margin (negative estimated profit)
SELECT
    COUNT(*)                                                  AS items,
    COUNT(*) FILTER (WHERE est_profit < 0)                    AS loss_items,
    ROUND(100.0 * COUNT(*) FILTER (WHERE est_profit < 0) / COUNT(*), 1) AS loss_items_pct,
    ROUND(SUM(est_profit) FILTER (WHERE est_profit < 0), 0)   AS total_loss
FROM v_order_items_enriched;
