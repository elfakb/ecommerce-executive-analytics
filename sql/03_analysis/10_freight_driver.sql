SELECT CASE WHEN EXTRACT(YEAR FROM order_month)=2018 THEN '2018' ELSE '2017' END AS yr,
       ROUND(AVG(revenue), 2)                  AS avg_item_price,
       ROUND(AVG(freight), 2)                  AS avg_freight_per_item,
       ROUND(100.0*SUM(freight)/SUM(revenue),2) AS freight_pct,
       ROUND(AVG(freight/NULLIF(revenue,0)) * 100, 2) AS avg_item_freight_ratio
FROM v_order_items_enriched
WHERE EXTRACT(MONTH FROM order_month) BETWEEN 1 AND 8
GROUP BY 1 ORDER BY 1;
