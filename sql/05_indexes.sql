-- ============================================================
-- OLIST E-COMMERCE DATA WAREHOUSE
-- File: 05_indexes.sql
-- Database: olist_ecommerce
--
-- Purpose:
-- Create indexes on frequently queried columns
-- to support joins and data retrieval.
-- ============================================================


-- ============================================================
-- 1. STAGING TABLE INDEXES
-- ============================================================

-- Index on order ID
CREATE INDEX IF NOT EXISTS idx_stg_orders_order_id
ON staging.stg_orders(order_id);

-- Index on product ID
CREATE INDEX IF NOT EXISTS idx_stg_products_product_id
ON staging.stg_products(product_id);

-- Index on seller ID
CREATE INDEX IF NOT EXISTS idx_stg_sellers_seller_id
ON staging.stg_sellers(seller_id);


-- ============================================================
-- 2. WAREHOUSE TABLE INDEXES
-- ============================================================

-- Fact orders: customer lookup
CREATE INDEX IF NOT EXISTS idx_fact_orders_customer_key
ON warehouse.fact_orders(customer_key);

-- Fact orders: purchase date lookup
CREATE INDEX IF NOT EXISTS idx_fact_orders_purchase_date_key
ON warehouse.fact_orders(purchase_date_key);

-- Fact order items: product lookup
CREATE INDEX IF NOT EXISTS idx_fact_order_items_product_key
ON warehouse.fact_order_items(product_key);

-- Fact order items: seller lookup
CREATE INDEX IF NOT EXISTS idx_fact_order_items_seller_key
ON warehouse.fact_order_items(seller_key);

-- Fact order items: order lookup
CREATE INDEX IF NOT EXISTS idx_fact_order_items_order_id
ON warehouse.fact_order_items(order_id);

-- Fact payments: order lookup
CREATE INDEX IF NOT EXISTS idx_fact_payments_order_id
ON warehouse.fact_payments(order_id);

-- Fact reviews: order lookup
CREATE INDEX IF NOT EXISTS idx_fact_reviews_order_id
ON warehouse.fact_reviews(order_id);


-- ============================================================
-- 3. INDEX VALIDATION
-- ============================================================

SELECT
    schemaname,
    tablename,
    indexname
FROM pg_indexes
WHERE schemaname IN ('staging', 'warehouse')
ORDER BY schemaname, tablename, indexname;


-- ============================================================
-- END OF INDEXES
-- ============================================================
