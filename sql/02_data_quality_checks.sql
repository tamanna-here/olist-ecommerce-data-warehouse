-- ============================================================
-- OLIST E-COMMERCE DATA WAREHOUSE
-- File: 02_data_quality_checks.sql
-- Database: olist_ecommerce
-- Schema: staging
--
-- Purpose:
-- Validate source data before warehouse transformation.
-- Checks missing values, duplicates, invalid values,
-- and referential integrity across staging tables.
-- ============================================================


-- ============================================================
-- 1. SOURCE TABLE RECORD COUNTS
-- ============================================================

SELECT 'customers' AS table_name, COUNT(*) AS total_records
FROM staging.stg_customers

UNION ALL

SELECT 'geolocation', COUNT(*)
FROM staging.stg_geolocation

UNION ALL

SELECT 'order_items', COUNT(*)
FROM staging.stg_order_items

UNION ALL

SELECT 'order_payments', COUNT(*)
FROM staging.stg_order_payments

UNION ALL

SELECT 'order_reviews', COUNT(*)
FROM staging.stg_order_reviews

UNION ALL

SELECT 'orders', COUNT(*)
FROM staging.stg_orders

UNION ALL

SELECT 'products', COUNT(*)
FROM staging.stg_products

UNION ALL

SELECT 'sellers', COUNT(*)
FROM staging.stg_sellers

UNION ALL

SELECT 'category_translation', COUNT(*)
FROM staging.stg_category_translation;


-- ============================================================
-- 2. CUSTOMER DATA QUALITY CHECKS
-- ============================================================

-- Missing customer IDs
SELECT COUNT(*) AS missing_customer_ids
FROM staging.stg_customers
WHERE customer_id IS NULL
   OR TRIM(customer_id) = '';

-- Duplicate customer IDs
SELECT customer_id, COUNT(*) AS duplicate_count
FROM staging.stg_customers
GROUP BY customer_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 3. ORDER DATA QUALITY CHECKS
-- ============================================================

-- Missing order IDs
SELECT COUNT(*) AS missing_order_ids
FROM staging.stg_orders
WHERE order_id IS NULL
   OR TRIM(order_id) = '';

-- Duplicate order IDs
SELECT order_id, COUNT(*) AS duplicate_count
FROM staging.stg_orders
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Missing customer references in orders
SELECT COUNT(*) AS missing_customer_references
FROM staging.stg_orders
WHERE customer_id IS NULL
   OR TRIM(customer_id) = '';

-- Invalid order timestamps
SELECT
    COUNT(*) AS invalid_purchase_timestamps
FROM staging.stg_orders
WHERE order_purchase_timestamp IS NOT NULL
  AND TRIM(order_purchase_timestamp) <> ''
  AND NOT pg_input_is_valid(
      order_purchase_timestamp, 'timestamp'
  );

-- Delivered orders missing actual delivery timestamps
SELECT COUNT(*) AS delivered_orders_missing_delivery_date
FROM staging.stg_orders
WHERE order_status = 'delivered'
  AND (
      order_delivered_customer_date IS NULL
      OR TRIM(order_delivered_customer_date) = ''
  );


-- ============================================================
-- 4. PRODUCT DATA QUALITY CHECKS
-- ============================================================

-- Missing product IDs
SELECT COUNT(*) AS missing_product_ids
FROM staging.stg_products
WHERE product_id IS NULL
   OR TRIM(product_id) = '';

-- Duplicate product IDs
SELECT product_id, COUNT(*) AS duplicate_count
FROM staging.stg_products
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Missing product categories
SELECT COUNT(*) AS missing_product_categories
FROM staging.stg_products
WHERE product_category_name IS NULL
   OR TRIM(product_category_name) = '';

-- Missing or invalid product weights
SELECT COUNT(*) AS missing_or_invalid_weights
FROM staging.stg_products
WHERE product_weight_g IS NULL
   OR TRIM(product_weight_g) = ''
   OR NOT pg_input_is_valid(product_weight_g, 'numeric')
   OR CASE
        WHEN pg_input_is_valid(product_weight_g, 'numeric')
        THEN product_weight_g::numeric <= 0
        ELSE FALSE
      END;

-- Products with at least one missing dimension
SELECT COUNT(*) AS products_with_missing_dimensions
FROM staging.stg_products
WHERE product_length_cm IS NULL
   OR TRIM(product_length_cm) = ''
   OR product_height_cm IS NULL
   OR TRIM(product_height_cm) = ''
   OR product_width_cm IS NULL
   OR TRIM(product_width_cm) = '';


-- ============================================================
-- 5. SELLER DATA QUALITY CHECKS
-- ============================================================

-- Missing seller IDs
SELECT COUNT(*) AS missing_seller_ids
FROM staging.stg_sellers
WHERE seller_id IS NULL
   OR TRIM(seller_id) = '';

-- Duplicate seller IDs
SELECT seller_id, COUNT(*) AS duplicate_count
FROM staging.stg_sellers
GROUP BY seller_id
HAVING COUNT(*) > 1;


-- ============================================================
-- 6. ORDER ITEM DATA QUALITY CHECKS
-- ============================================================

-- Missing order, product and seller IDs
SELECT
    COUNT(*) FILTER (
        WHERE order_id IS NULL OR TRIM(order_id) = ''
    ) AS missing_order_ids,

    COUNT(*) FILTER (
        WHERE product_id IS NULL OR TRIM(product_id) = ''
    ) AS missing_product_ids,

    COUNT(*) FILTER (
        WHERE seller_id IS NULL OR TRIM(seller_id) = ''
    ) AS missing_seller_ids
FROM staging.stg_order_items;

-- Invalid or negative item prices
SELECT COUNT(*) AS invalid_or_negative_prices
FROM staging.stg_order_items
WHERE price IS NULL
   OR TRIM(price) = ''
   OR NOT pg_input_is_valid(price, 'numeric')
   OR CASE
        WHEN pg_input_is_valid(price, 'numeric')
        THEN price::numeric < 0
        ELSE FALSE
      END;

-- Invalid or negative freight values
SELECT COUNT(*) AS invalid_or_negative_freight
FROM staging.stg_order_items
WHERE freight_value IS NULL
   OR TRIM(freight_value) = ''
   OR NOT pg_input_is_valid(freight_value, 'numeric')
   OR CASE
        WHEN pg_input_is_valid(freight_value, 'numeric')
        THEN freight_value::numeric < 0
        ELSE FALSE
      END;


-- ============================================================
-- 7. PAYMENT DATA QUALITY CHECKS
-- ============================================================

-- Missing payment order IDs
SELECT COUNT(*) AS missing_payment_order_ids
FROM staging.stg_order_payments
WHERE order_id IS NULL
   OR TRIM(order_id) = '';

-- Invalid or negative payment values
SELECT COUNT(*) AS invalid_payment_values
FROM staging.stg_order_payments
WHERE payment_value IS NULL
   OR TRIM(payment_value) = ''
   OR NOT pg_input_is_valid(payment_value, 'numeric')
   OR CASE
        WHEN pg_input_is_valid(payment_value, 'numeric')
        THEN payment_value::numeric < 0
        ELSE FALSE
      END;

-- Negative payment installments
SELECT COUNT(*) AS negative_installments
FROM staging.stg_order_payments
WHERE payment_installments IS NOT NULL
  AND TRIM(payment_installments) <> ''
  AND pg_input_is_valid(payment_installments, 'integer')
  AND payment_installments::integer < 0;


-- ============================================================
-- 8. REVIEW DATA QUALITY CHECKS
-- ============================================================

-- Missing review IDs
SELECT COUNT(*) AS missing_review_ids
FROM staging.stg_order_reviews
WHERE review_id IS NULL
   OR TRIM(review_id) = '';

-- Missing review order IDs
SELECT COUNT(*) AS missing_review_order_ids
FROM staging.stg_order_reviews
WHERE order_id IS NULL
   OR TRIM(order_id) = '';

-- Invalid review scores
SELECT COUNT(*) AS invalid_review_scores
FROM staging.stg_order_reviews
WHERE review_score IS NULL
   OR TRIM(review_score) = ''
   OR NOT pg_input_is_valid(review_score, 'integer')
   OR CASE
        WHEN pg_input_is_valid(review_score, 'integer')
        THEN review_score::integer NOT BETWEEN 1 AND 5
        ELSE FALSE
      END;


-- ============================================================
-- 9. CATEGORY TRANSLATION DATA QUALITY CHECKS
-- ============================================================

-- Missing category names
SELECT COUNT(*) AS missing_category_names
FROM staging.stg_category_translation
WHERE product_category_name IS NULL
   OR TRIM(product_category_name) = '';

-- Duplicate category names
SELECT
    product_category_name,
    COUNT(*) AS duplicate_count
FROM staging.stg_category_translation
GROUP BY product_category_name
HAVING COUNT(*) > 1;


-- ============================================================
-- 10. REFERENTIAL INTEGRITY CHECKS
-- ============================================================

-- Orders without matching customers
SELECT COUNT(*) AS unmatched_customer_ids
FROM staging.stg_orders o
LEFT JOIN staging.stg_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Order items without matching orders
SELECT COUNT(*) AS unmatched_order_ids
FROM staging.stg_order_items oi
LEFT JOIN staging.stg_orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Order items without matching products
SELECT COUNT(*) AS unmatched_product_ids
FROM staging.stg_order_items oi
LEFT JOIN staging.stg_products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Order items without matching sellers
SELECT COUNT(*) AS unmatched_seller_ids
FROM staging.stg_order_items oi
LEFT JOIN staging.stg_sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- Payments without matching orders
SELECT COUNT(*) AS unmatched_payment_orders
FROM staging.stg_order_payments p
LEFT JOIN staging.stg_orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Reviews without matching orders
SELECT COUNT(*) AS unmatched_review_orders
FROM staging.stg_order_reviews r
LEFT JOIN staging.stg_orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- ============================================================
-- END OF DATA QUALITY CHECKS
-- ============================================================



