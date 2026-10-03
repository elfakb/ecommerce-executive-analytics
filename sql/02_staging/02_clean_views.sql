-- ============================================================
-- Analysis rules (defined ONCE, here):
--   * Window: 2017-01-01 to 2018-08-31
--   * Excluded statuses: canceled, unavailable
--   * Reviews: one per order (latest answer wins)
-- ============================================================

CREATE OR REPLACE VIEW v_valid_orders AS
SELECT o.*
FROM orders o
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= DATE '2017-01-01'
  AND o.order_purchase_timestamp <  DATE '2018-09-01';

CREATE OR REPLACE VIEW v_order_reviews_dedup AS
SELECT order_id, review_score
FROM (
    SELECT order_id, review_score,
           ROW_NUMBER() OVER (
               PARTITION BY order_id
               ORDER BY review_answer_timestamp DESC NULLS LAST, review_id
           ) AS rn
    FROM order_reviews
) r
WHERE rn = 1;

CREATE OR REPLACE VIEW v_order_items_enriched AS
WITH params AS (
    SELECT
        MAX(param_value) FILTER (WHERE param_name = 'default_cogs_rate')      AS default_cogs,
        MAX(param_value) FILTER (WHERE param_name = 'cogs_multiplier')        AS cogs_mult,
        MAX(param_value) FILTER (WHERE param_name = 'freight_absorbed_share') AS freight_share
    FROM cost_parameters
)
SELECT
    oi.order_id,
    oi.order_item_id,
    o.order_purchase_timestamp,
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
    c.customer_unique_id,
    c.customer_state,
    oi.seller_id,
    oi.product_id,
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category,
    oi.price         AS revenue,
    oi.freight_value AS freight,
    ROUND(oi.price * LEAST(1, COALESCE(a.cogs_rate, pr.default_cogs) * pr.cogs_mult), 2) AS est_cogs,
    ROUND(oi.price
          - oi.price * LEAST(1, COALESCE(a.cogs_rate, pr.default_cogs) * pr.cogs_mult)
          - oi.freight_value * pr.freight_share, 2) AS est_profit
FROM order_items oi
JOIN v_valid_orders o  ON o.order_id = oi.order_id
JOIN customers c       ON c.customer_id = o.customer_id
JOIN products p        ON p.product_id = oi.product_id
LEFT JOIN product_category_translation t ON t.product_category_name = p.product_category_name
LEFT JOIN category_cost_assumptions a    ON a.category_english = t.product_category_name_english
CROSS JOIN params pr;

CREATE OR REPLACE VIEW v_orders_summary AS
SELECT
    o.order_id,
    o.order_purchase_timestamp,
    DATE_TRUNC('month', o.order_purchase_timestamp)::date AS order_month,
    c.customer_unique_id,
    c.customer_state,
    o.order_status,
    SUM(i.revenue)    AS revenue,
    SUM(i.freight)    AS freight,
    SUM(i.est_profit) AS est_profit,
    COUNT(*)          AS items,
    (o.order_delivered_customer_date::date - o.order_purchase_timestamp::date)      AS delivery_days,
    (o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date) AS days_vs_estimate,
    r.review_score
FROM v_valid_orders o
JOIN customers c                  ON c.customer_id = o.customer_id
JOIN v_order_items_enriched i     ON i.order_id = o.order_id
LEFT JOIN v_order_reviews_dedup r ON r.order_id = o.order_id
GROUP BY o.order_id, o.order_purchase_timestamp, c.customer_unique_id, c.customer_state,
         o.order_status, o.order_delivered_customer_date, o.order_estimated_delivery_date,
         r.review_score;
