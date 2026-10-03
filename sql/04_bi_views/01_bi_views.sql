-- Tableau reads these views as CSV. Item-level and order-level facts let
-- Tableau compute KPIs itself (COUNTD of customers cannot be pre-summed).

CREATE OR REPLACE VIEW bi_items AS
SELECT order_id, order_item_id, order_purchase_timestamp::date AS order_date, order_month,
       EXTRACT(YEAR FROM order_month)::int AS order_year,
       customer_unique_id, customer_state,
       CASE
           WHEN customer_state IN ('SP','RJ','MG','ES')                          THEN 'Southeast'
           WHEN customer_state IN ('PR','SC','RS')                               THEN 'South'
           WHEN customer_state IN ('BA','SE','AL','PE','PB','RN','CE','PI','MA') THEN 'Northeast'
           WHEN customer_state IN ('DF','GO','MT','MS')                          THEN 'Central-West'
           ELSE 'North'
       END AS region,
       product_id, category, revenue, freight, est_cogs, est_profit
FROM v_order_items_enriched;

CREATE OR REPLACE VIEW bi_orders AS
SELECT order_id, order_purchase_timestamp::date AS order_date, order_month,
       customer_unique_id, customer_state, revenue, freight, est_profit, items,
       delivery_days, days_vs_estimate,
       (days_vs_estimate > 0) AS is_late,
       review_score
FROM v_orders_summary;

CREATE OR REPLACE VIEW bi_customer_segments AS
WITH customer AS (
    SELECT customer_unique_id,
           DATE '2018-09-01' - MAX(order_purchase_timestamp)::date AS recency_days,
           COUNT(*) AS frequency, SUM(revenue) AS monetary
    FROM v_orders_summary GROUP BY customer_unique_id
),
scored AS (
    SELECT *, NTILE(5) OVER (ORDER BY recency_days DESC) AS r_score,
              NTILE(5) OVER (ORDER BY monetary)          AS m_score
    FROM customer
)
SELECT customer_unique_id, recency_days, frequency, monetary, r_score, m_score,
       CASE
           WHEN frequency >= 2 AND r_score >= 4 THEN '1. Champions (repeat, recent)'
           WHEN frequency >= 2                  THEN '2. Loyal (repeat)'
           WHEN r_score >= 4                    THEN '3. New (one-time, recent)'
           WHEN m_score >= 4                    THEN '4. High-value one-time (win-back)'
           ELSE                                      '5. Dormant one-time'
       END AS segment
FROM scored;

CREATE OR REPLACE VIEW bi_margin_bridge AS
SELECT dim, member, rev0, rev1, s0, s1, m0, m1, mix_effect, rate_effect
FROM v_margin_bridge;
