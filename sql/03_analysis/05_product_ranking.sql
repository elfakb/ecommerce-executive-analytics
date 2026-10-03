-- A) Top 20 products overall + rank inside their category
WITH prod AS (
    SELECT product_id, category,
           SUM(revenue)    AS revenue,
           SUM(est_profit) AS profit,
           COUNT(*)        AS units
    FROM v_order_items_enriched
    GROUP BY product_id, category
),
ranked AS (
    SELECT *,
           RANK()       OVER (ORDER BY revenue DESC)                      AS overall_rank,
           DENSE_RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS category_rank
    FROM prod
)
SELECT overall_rank, category_rank, product_id, category,
       ROUND(revenue, 0) AS revenue, ROUND(profit, 0) AS profit, units
FROM ranked
WHERE overall_rank <= 20
ORDER BY overall_rank;

-- B) Top 3 products inside each of the 5 biggest categories
WITH prod AS (
    SELECT product_id, category, SUM(revenue) AS revenue
    FROM v_order_items_enriched
    GROUP BY product_id, category
),
top_cats AS (
    SELECT category FROM prod GROUP BY category ORDER BY SUM(revenue) DESC LIMIT 5
),
ranked AS (
    SELECT p.*, DENSE_RANK() OVER (PARTITION BY p.category ORDER BY p.revenue DESC) AS rnk
    FROM prod p JOIN top_cats USING (category)
)
SELECT category, rnk, product_id, ROUND(revenue, 0) AS revenue
FROM ranked WHERE rnk <= 3
ORDER BY category, rnk;

-- C) Pareto: how many products generate 80% of revenue?
WITH prod AS (
    SELECT product_id, SUM(revenue) AS revenue
    FROM v_order_items_enriched GROUP BY product_id
),
cum AS (
    SELECT product_id, revenue,
           (SUM(revenue) OVER (ORDER BY revenue DESC, product_id) - revenue)
               / SUM(revenue) OVER () AS cum_share_before,
           COUNT(*) OVER () AS n_products
    FROM prod
)
SELECT COUNT(*)                                   AS products_for_80pct_revenue,
       MAX(n_products)                            AS total_products,
       ROUND(100.0 * COUNT(*) / MAX(n_products), 1) AS pct_of_products
FROM cum
WHERE cum_share_before < 0.80;
