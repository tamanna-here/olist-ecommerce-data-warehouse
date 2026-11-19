-- ============================================================
-- OLIST E-COMMERCE DATA WAREHOUSE
-- File: 03_dimension_tables.sql
-- Database: olist_ecommerce
-- Schema: warehouse
--
-- Purpose:
-- Create and populate dimension tables using staging data.
--
-- Dimensions:
-- 1. dim_customers
-- 2. dim_products
-- 3. dim_sellers
-- 4. dim_date
-- ============================================================


-- ============================================================
-- 1. CUSTOMER DIMENSION
-- ============================================================

CREATE TABLE IF NOT EXISTS warehouse.dim_customers (
    customer_key SERIAL PRIMARY KEY,
    customer_id TEXT UNIQUE NOT NULL,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);

-- Populate customer dimension

INSERT INTO warehouse.dim_customers (
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
)
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM staging.stg_customers
ON CONFLICT (customer_id) DO NOTHING;


-- ============================================================
-- 2. PRODUCT DIMENSION
-- ============================================================

CREATE TABLE IF NOT EXISTS warehouse.dim_products (
    product_key SERIAL PRIMARY KEY,
    product_id TEXT UNIQUE NOT NULL,
    product_category_name TEXT,
    product_category_name_english TEXT,
    product_weight_g NUMERIC,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC
);

-- Populate product dimension
-- Translate Portuguese category names into English.
-- Invalid or missing numeric attributes are stored as NULL.

INSERT INTO warehouse.dim_products (
    product_id,
    product_category_name,
    product_category_name_english,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
)
SELECT
    p.product_id,
    p.product_category_name,
    ct.product_category_name_english,

    CASE
        WHEN pg_input_is_valid(
            NULLIF(TRIM(p.product_weight_g), ''), 'numeric'
        )
        THEN NULLIF(TRIM(p.product_weight_g), '')::numeric
    END,

    CASE
        WHEN pg_input_is_valid(
            NULLIF(TRIM(p.product_length_cm), ''), 'numeric'
        )
        THEN NULLIF(TRIM(p.product_length_cm), '')::numeric
    END,

    CASE
        WHEN pg_input_is_valid(
            NULLIF(TRIM(p.product_height_cm), ''), 'numeric'
        )
        THEN NULLIF(TRIM(p.product_height_cm), '')::numeric
    END,

    CASE
        WHEN pg_input_is_valid(
            NULLIF(TRIM(p.product_width_cm), ''), 'numeric'
        )
        THEN NULLIF(TRIM(p.product_width_cm), '')::numeric
    END

FROM staging.stg_products p
LEFT JOIN staging.stg_category_translation ct
    ON p.product_category_name = ct.product_category_name
ON CONFLICT (product_id) DO NOTHING;


-- ============================================================
-- 3. SELLER DIMENSION
-- ============================================================

CREATE TABLE IF NOT EXISTS warehouse.dim_sellers (
    seller_key SERIAL PRIMARY KEY,
    seller_id TEXT UNIQUE NOT NULL,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);

-- Populate seller dimension

INSERT INTO warehouse.dim_sellers (
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
)
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM staging.stg_sellers
ON CONFLICT (seller_id) DO NOTHING;


-- ============================================================
-- 4. DATE DIMENSION
-- ============================================================

CREATE TABLE IF NOT EXISTS warehouse.dim_date (
    date_key INTEGER PRIMARY KEY,
    full_date DATE UNIQUE NOT NULL,
    year INTEGER,
    quarter INTEGER,
    month INTEGER,
    month_name TEXT,
    day INTEGER,
    day_of_week TEXT,
    week_number INTEGER
);

-- Generate a continuous date range based on order
-- purchase dates in the staging orders table.

INSERT INTO warehouse.dim_date (
    date_key,
    full_date,
    year,
    quarter,
    month,
    month_name,
    day,
    day_of_week,
    week_number
)
SELECT
    TO_CHAR(d.date_value, 'YYYYMMDD')::INTEGER,
    d.date_value,
    EXTRACT(YEAR FROM d.date_value)::INTEGER,
    EXTRACT(QUARTER FROM d.date_value)::INTEGER,
    EXTRACT(MONTH FROM d.date_value)::INTEGER,
    TO_CHAR(d.date_value, 'FMMonth'),
    EXTRACT(DAY FROM d.date_value)::INTEGER,
    TO_CHAR(d.date_value, 'FMDay'),
    EXTRACT(WEEK FROM d.date_value)::INTEGER

FROM GENERATE_SERIES(
    (
        SELECT MIN(order_purchase_timestamp::timestamp)::date
        FROM staging.stg_orders
        WHERE order_purchase_timestamp IS NOT NULL
          AND TRIM(order_purchase_timestamp) <> ''
    ),
    (
        SELECT MAX(order_purchase_timestamp::timestamp)::date
        FROM staging.stg_orders
        WHERE order_purchase_timestamp IS NOT NULL
          AND TRIM(order_purchase_timestamp) <> ''
    ),
    INTERVAL '1 day'
) AS d(date_value)

ON CONFLICT (date_key) DO NOTHING;


-- ============================================================
-- 5. DIMENSION TABLE ROW COUNT VALIDATION
-- ============================================================

SELECT 'dim_customers' AS dimension_name,
       COUNT(*) AS total_records
FROM warehouse.dim_customers

UNION ALL

SELECT 'dim_products', COUNT(*)
FROM warehouse.dim_products

UNION ALL

SELECT 'dim_sellers', COUNT(*)
FROM warehouse.dim_sellers

UNION ALL

SELECT 'dim_date', COUNT(*)
FROM warehouse.dim_date;


-- ============================================================
-- END OF DIMENSION TABLES
-- ============================================================
