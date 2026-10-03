-- 1. Sipariş durumu dağılımı (hangi statüleri gelirden çıkaracağız?)
SELECT order_status, COUNT(*) AS orders,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
FROM orders GROUP BY order_status ORDER BY orders DESC;

-- 2. Aylık sipariş sayısı (analiz penceresini doğrular)
SELECT DATE_TRUNC('month', order_purchase_timestamp)::date AS month,
       COUNT(*) AS orders
FROM orders GROUP BY 1 ORDER BY 1;

-- 3. Kategorisi eksik ürünler
SELECT COUNT(*) AS products_without_category
FROM products WHERE product_category_name IS NULL;

-- 4. Çeviri tablosunda karşılığı olmayan kategoriler
SELECT DISTINCT p.product_category_name
FROM products p
LEFT JOIN product_category_translation t USING (product_category_name)
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name_english IS NULL;

-- 5. Teslim tarihi olmayan "delivered" siparişler
SELECT COUNT(*) AS delivered_without_date
FROM orders
WHERE order_status = 'delivered' AND order_delivered_customer_date IS NULL;

-- 6. Birden fazla yorumu olan siparişler (review join'inde satır çoğalması riski)
SELECT COUNT(*) AS orders_with_multiple_reviews
FROM (SELECT order_id FROM order_reviews GROUP BY order_id HAVING COUNT(*) > 1) x;