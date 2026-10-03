-- A) Delivery time band vs review score (delivered orders only)
SELECT
    CASE
        WHEN delivery_days <= 7  THEN '1) 0-7 days'
        WHEN delivery_days <= 14 THEN '2) 8-14 days'
        WHEN delivery_days <= 21 THEN '3) 15-21 days'
        WHEN delivery_days <= 30 THEN '4) 22-30 days'
        ELSE                          '5) 30+ days'
    END AS delivery_band,
    COUNT(*)                                                        AS orders,
    ROUND(AVG(review_score), 2)                                     AS avg_review,
    ROUND(100.0 * COUNT(*) FILTER (WHERE review_score <= 2) / COUNT(*), 1) AS pct_bad_reviews
FROM v_orders_summary
WHERE order_status = 'delivered' AND delivery_days IS NOT NULL AND review_score IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- B) Late vs on-time delivery
SELECT
    CASE WHEN days_vs_estimate > 0 THEN 'Late' ELSE 'On time / early' END AS delivery_status,
    COUNT(*)                                    AS orders,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_orders,
    ROUND(AVG(review_score), 2)                 AS avg_review,
    ROUND(AVG(delivery_days), 1)                AS avg_delivery_days
FROM v_orders_summary
WHERE order_status = 'delivered' AND days_vs_estimate IS NOT NULL AND review_score IS NOT NULL
GROUP BY 1
ORDER BY 1 DESC;

-- C) Monthly trend: late delivery rate and average review
SELECT
    order_month,
    ROUND(100.0 * COUNT(*) FILTER (WHERE days_vs_estimate > 0) / COUNT(*), 1) AS late_pct,
    ROUND(AVG(delivery_days), 1)  AS avg_delivery_days,
    ROUND(AVG(review_score), 2)   AS avg_review
FROM v_orders_summary
WHERE order_status = 'delivered' AND days_vs_estimate IS NOT NULL
GROUP BY order_month
ORDER BY order_month;
