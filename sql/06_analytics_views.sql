-- ============================================================
-- OLIST E-COMMERCE DATA WAREHOUSE
-- File: 06_analytics_views.sql
-- Database: olist_ecommerce
-- Schema: analytics
--
-- Purpose:
-- Create analytical views for business reporting.
--
-- Views:
-- 1. vw_monthly_revenue
-- 2. vw_customer_value
-- 3. vw_seller_performance
-- 4. vw_delivery_performance
-- ============================================================


-- ============================================================
-- 1. MONTHLY REVENUE VIEW
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_monthly_revenue AS

SELECT
    d.year,
    d.month,
    d.month_name,
    COUNT(DISTINCT fo.order_id) AS total_orders,
    SUM(oi.price) AS product_revenue,
    SUM(oi.freight_value) AS freight_revenue,
    SUM(oi.price + oi.freight_value) AS total_revenue

FROM warehouse.fact_orders fo

JOIN warehouse.fact_order_items oi
    ON fo.order_id = oi.order_id

JOIN warehouse.dim_date d
    ON fo.purchase_date_key = d.date_key

WHERE fo.order_status = 'delivered'

GROUP BY
    d.year,
    d.month,
    d.month_name;


-- ============================================================
-- 2. CUSTOMER VALUE VIEW
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_customer_value AS

WITH order_values AS (

    SELECT
        dc.customer_unique_id,
        fo.order_id,
        d.full_date,
        SUM(oi.price + oi.freight_value) AS order_value

    FROM warehouse.fact_orders fo

    JOIN warehouse.dim_customers dc
        ON fo.customer_key = dc.customer_key

    JOIN warehouse.fact_order_items oi
        ON fo.order_id = oi.order_id

    JOIN warehouse.dim_date d
        ON fo.purchase_date_key = d.date_key

    WHERE fo.order_status = 'delivered'

    GROUP BY
        dc.customer_unique_id,
        fo.order_id,
        d.full_date
)

SELECT
    customer_unique_id,
    COUNT(*) AS total_orders,
    SUM(order_value) AS lifetime_value,
    AVG(order_value) AS average_order_value,
    MIN(full_date) AS first_purchase_date,
    MAX(full_date) AS last_purchase_date,

    CASE
        WHEN COUNT(*) > 1 THEN 'Repeat Customer'
        ELSE 'One-time Customer'
    END AS customer_type

FROM order_values

GROUP BY customer_unique_id;


-- ============================================================
-- 3. SELLER PERFORMANCE VIEW
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_seller_performance AS

SELECT
    ds.seller_id,
    ds.seller_city,
    ds.seller_state,
    COUNT(DISTINCT fo.order_id) AS total_orders,
    COUNT(*) AS items_sold,
    SUM(oi.price) AS product_revenue,
    SUM(oi.freight_value) AS freight_revenue

FROM warehouse.fact_order_items oi

JOIN warehouse.fact_orders fo
    ON oi.order_id = fo.order_id

JOIN warehouse.dim_sellers ds
    ON oi.seller_key = ds.seller_key

WHERE fo.order_status = 'delivered'

GROUP BY
    ds.seller_id,
    ds.seller_city,
    ds.seller_state;


-- ============================================================
-- 4. DELIVERY PERFORMANCE VIEW
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_delivery_performance AS

SELECT
    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    delivered_customer_at - delivered_carrier_at
                )
            ) / 86400
        ),
        2
    ) AS avg_carrier_to_customer_days,

    COUNT(*) FILTER (
        WHERE delivered_customer_at > estimated_delivery_at
    ) AS late_deliveries,

    ROUND(
        (
            100.0 *
            COUNT(*) FILTER (
                WHERE delivered_customer_at > estimated_delivery_at
            ) /
            NULLIF(COUNT(*), 0)
        ),
        2
    ) AS late_delivery_percentage

FROM warehouse.fact_orders

WHERE order_status = 'delivered'
  AND delivered_customer_at IS NOT NULL;


-- ============================================================
-- 5. VIEW VALIDATION
-- ============================================================

SELECT
    schemaname,
    viewname
FROM pg_views
WHERE schemaname = 'analytics'
ORDER BY viewname;


-- ============================================================
-- END OF ANALYTICS VIEWS
-- ============================================================
