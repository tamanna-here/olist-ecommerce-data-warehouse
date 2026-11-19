-- ============================================================
-- OLIST E-COMMERCE DATA WAREHOUSE
-- File: 04_fact_tables.sql
-- Database: olist_ecommerce
--
-- Purpose:
-- Create and populate fact tables using staging data
-- and the previously created dimension tables.
--
-- Fact tables:
-- 1. fact_orders
-- 2. fact_order_items
-- 3. fact_payments
-- 4. fact_reviews
-- ============================================================


-- ============================================================
-- 1. ORDERS FACT TABLE
-- ============================================================

CREATE TABLE warehouse.fact_orders (
    order_key SERIAL PRIMARY KEY,
    order_id TEXT UNIQUE NOT NULL,
    customer_key INTEGER NOT NULL
        REFERENCES warehouse.dim_customers(customer_key),
    purchase_date_key INTEGER
        REFERENCES warehouse.dim_date(date_key),
    approved_at TIMESTAMP,
    delivered_carrier_at TIMESTAMP,
    delivered_customer_at TIMESTAMP,
    estimated_delivery_at TIMESTAMP,
    order_status TEXT
);

-- Populate orders fact table

INSERT INTO warehouse.fact_orders (
    order_id,
    customer_key,
    purchase_date_key,
    approved_at,
    delivered_carrier_at,
    delivered_customer_at,
    estimated_delivery_at,
    order_status
)
SELECT
    o.order_id,
    c.customer_key,
    d.date_key,

    NULLIF(TRIM(o.order_approved_at), '')::timestamp,
    NULLIF(TRIM(o.order_delivered_carrier_date), '')::timestamp,
    NULLIF(TRIM(o.order_delivered_customer_date), '')::timestamp,
    NULLIF(TRIM(o.order_estimated_delivery_date), '')::timestamp,

    o.order_status

FROM staging.stg_orders o

JOIN warehouse.dim_customers c
    ON o.customer_id = c.customer_id

LEFT JOIN warehouse.dim_date d
    ON NULLIF(TRIM(o.order_purchase_timestamp), '')::timestamp::date
       = d.full_date;


-- ============================================================
-- 2. ORDER ITEMS FACT TABLE
-- ============================================================

CREATE TABLE warehouse.fact_order_items (
    order_item_key SERIAL PRIMARY KEY,
    order_id TEXT NOT NULL
        REFERENCES warehouse.fact_orders(order_id),
    product_key INTEGER NOT NULL
        REFERENCES warehouse.dim_products(product_key),
    seller_key INTEGER NOT NULL
        REFERENCES warehouse.dim_sellers(seller_key),
    shipping_limit_date TIMESTAMP,
    price NUMERIC,
    freight_value NUMERIC
);

-- Populate order items fact table

INSERT INTO warehouse.fact_order_items (
    order_id,
    product_key,
    seller_key,
    shipping_limit_date,
    price,
    freight_value
)
SELECT
    oi.order_id,
    p.product_key,
    s.seller_key,

    NULLIF(TRIM(oi.shipping_limit_date), '')::timestamp,
    NULLIF(TRIM(oi.price), '')::numeric,
    NULLIF(TRIM(oi.freight_value), '')::numeric

FROM staging.stg_order_items oi

JOIN warehouse.dim_products p
    ON oi.product_id = p.product_id

JOIN warehouse.dim_sellers s
    ON oi.seller_id = s.seller_id

JOIN warehouse.fact_orders fo
    ON oi.order_id = fo.order_id;


-- ============================================================
-- 3. PAYMENTS FACT TABLE
-- ============================================================

CREATE TABLE warehouse.fact_payments (
    payment_key SERIAL PRIMARY KEY,
    order_id TEXT NOT NULL
        REFERENCES warehouse.fact_orders(order_id),
    payment_sequential INTEGER,
    payment_type TEXT,
    payment_installments INTEGER,
    payment_value NUMERIC
);

-- Populate payments fact table

INSERT INTO warehouse.fact_payments (
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
)
SELECT
    p.order_id,
    NULLIF(TRIM(p.payment_sequential), '')::integer,
    p.payment_type,
    NULLIF(TRIM(p.payment_installments), '')::integer,
    NULLIF(TRIM(p.payment_value), '')::numeric

FROM staging.stg_order_payments p

JOIN warehouse.fact_orders fo
    ON p.order_id = fo.order_id;


-- ============================================================
-- 4. REVIEWS FACT TABLE
-- ============================================================

CREATE TABLE warehouse.fact_reviews (
    review_key SERIAL PRIMARY KEY,
    review_id TEXT NOT NULL,
    order_id TEXT NOT NULL
        REFERENCES warehouse.fact_orders(order_id),
    review_score INTEGER,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    review_comment_title TEXT,
    review_comment_message TEXT
);

-- Populate reviews fact table

INSERT INTO warehouse.fact_reviews (
    review_id,
    order_id,
    review_score,
    review_creation_date,
    review_answer_timestamp,
    review_comment_title,
    review_comment_message
)
SELECT
    review_id,
    order_id,
    NULLIF(TRIM(review_score), '')::integer,
    NULLIF(TRIM(review_creation_date), '')::timestamp,
    NULLIF(TRIM(review_answer_timestamp), '')::timestamp,
    review_comment_title,
    review_comment_message

FROM staging.stg_order_reviews r

JOIN warehouse.fact_orders fo
    ON r.order_id = fo.order_id;


-- ============================================================
-- 5. FACT TABLE ROW COUNT VALIDATION
-- ============================================================

SELECT 'fact_orders' AS table_name,
       COUNT(*) AS total_records
FROM warehouse.fact_orders

UNION ALL

SELECT 'fact_order_items', COUNT(*)
FROM warehouse.fact_order_items

UNION ALL

SELECT 'fact_payments', COUNT(*)
FROM warehouse.fact_payments

UNION ALL

SELECT 'fact_reviews', COUNT(*)
FROM warehouse.fact_reviews;


-- ============================================================
-- END OF FACT TABLES
-- ============================================================
