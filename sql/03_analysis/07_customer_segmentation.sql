-- RFM segmentation. Reference date = day after the analysis window ends.
WITH customer AS (
    SELECT
        customer_unique_id,
        DATE '2018-09-01' - MAX(order_purchase_timestamp)::date AS recency_days,
        COUNT(*)                                                 AS frequency,
        SUM(revenue)                                             AS monetary
    FROM v_orders_summary
    GROUP BY customer_unique_id
),
scored AS (
    SELECT *,
           NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,  -- 5 = most recent
           NTILE(5) OVER (ORDER BY monetary)          AS m_score   -- 5 = highest spend
    FROM customer
),
segmented AS (
    SELECT *,
        CASE
            WHEN frequency >= 2 AND r_score >= 4 THEN '1. Champions (repeat, recent)'
            WHEN frequency >= 2                  THEN '2. Loyal (repeat)'
            WHEN r_score >= 4                    THEN '3. New (one-time, recent)'
            WHEN m_score >= 4                    THEN '4. High-value one-time (win-back)'
            ELSE                                      '5. Dormant one-time'
        END AS segment
    FROM scored
)
SELECT
    segment,
    COUNT(*)                                           AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_customers,
    ROUND(SUM(monetary), 0)                            AS revenue,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_revenue,
    ROUND(AVG(monetary), 2)                            AS avg_spend,
    ROUND(AVG(recency_days), 0)                        AS avg_recency_days
FROM segmented
GROUP BY segment
ORDER BY segment;

-- Repeat purchase rate
SELECT
    COUNT(*)                                            AS customers,
    COUNT(*) FILTER (WHERE frequency >= 2)              AS repeat_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE frequency >= 2) / COUNT(*), 2) AS repeat_rate_pct
FROM (SELECT customer_unique_id, COUNT(*) AS frequency
      FROM v_orders_summary GROUP BY 1) t;
