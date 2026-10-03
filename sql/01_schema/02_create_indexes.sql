CREATE INDEX IF NOT EXISTS idx_orders_customer   ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_purchase   ON orders(order_purchase_timestamp);
CREATE INDEX IF NOT EXISTS idx_orders_status     ON orders(order_status);
CREATE INDEX IF NOT EXISTS idx_items_product     ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_items_seller      ON order_items(seller_id);
CREATE INDEX IF NOT EXISTS idx_reviews_order     ON order_reviews(order_id);
CREATE INDEX IF NOT EXISTS idx_customers_unique  ON customers(customer_unique_id);
CREATE INDEX IF NOT EXISTS idx_customers_state   ON customers(customer_state);
