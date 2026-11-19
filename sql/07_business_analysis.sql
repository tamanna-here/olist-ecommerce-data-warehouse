-- ============================================================
-- OLIST E-COMMERCE DATA WAREHOUSE
-- File: 07_business_analysis.sql
-- Database: olist_ecommerce
--
-- Purpose:
-- Perform business analysis using SQL to identify
-- revenue trends, customer behaviour, product performance,
-- payment preferences, reviews and delivery performance.
--
-- SQL techniques:
-- CTEs, JOINs, GROUP BY, aggregate functions,
-- window functions, RANK(), LAG() and FILTER.
-- ============================================================


-- ============================================================
-- 1. MONTHLY REVENUE ANALYSIS
-- Business Question:
-- How does revenue change across different months?
-- ============================================================

SELECT
    year,
    month,
    month_name,
    total_orders,
    product_revenue,
    freight_revenue,
    total_revenue
FROM analytics.vw_monthly_revenue
ORDER BY year, month;


-- ============================================================
-- 2. PRODUCT CATEGORY REVENUE CONTRIBUTION
-- Business Question:
-- Which product categories contribute the most revenue?
-- ============================================================

WITH category_revenue AS (

    SELECT
        COALESCE(
            dp.product_category_name_english,
            'Unknown'
        ) AS category_name,

        SUM(oi.price) AS product_revenue

    FROM warehouse.fact_order_items oi

    JOIN warehouse.fact_orders fo
        ON oi.order_id = fo.order_id

    JOIN warehouse.dim_products dp
        ON oi.product_key = dp.product_key

    WHERE fo.order_status = 'delivered'

    GROUP BY
        COALESCE(
            dp.product_category_name_english,
            'Unknown'
        )
)

SELECT
    category_name,
    ROUND(product_revenue, 2) AS product_revenue,

    ROUND(
        100.0 * product_revenue /
        SUM(product_revenue) OVER (),
        2
    ) AS revenue_contribution_percentage

FROM category_revenue

ORDER BY product_revenue DESC
LIMIT 10;


-- ============================================================
-- 3. MONTH-OVER-MONTH REVENUE GROWTH
-- Business Question:
-- How much does monthly revenue increase or decrease?
-- ============================================================

WITH monthly_comparison AS (

    SELECT
        year,
        month,
        month_name,
        total_revenue,

        LAG(total_revenue) OVER (
            ORDER BY year, month
        ) AS previous_month_revenue

    FROM analytics.vw_monthly_revenue
)

SELECT
    year,
    month,
    month_name,
    ROUND(total_revenue, 2) AS current_month_revenue,

    ROUND(previous_month_revenue, 2)
        AS previous_month_revenue,

    ROUND(
        (
            (total_revenue - previous_month_revenue)
            / NULLIF(previous_month_revenue, 0)
        ) * 100,
        2
    ) AS revenue_growth_percentage

FROM monthly_comparison

ORDER BY year, month;


-- ============================================================
-- 4. TOP 10 PRODUCTS BY REVENUE
-- Business Question:
-- Which products generate the highest revenue?
-- ============================================================

WITH product_performance AS (

    SELECT
        dp.product_id,

        COALESCE(
            dp.product_category_name_english,
            'Unknown'
        ) AS category_name,

        COUNT(*) AS units_sold,

        SUM(oi.price) AS total_product_revenue

    FROM warehouse.fact_order_items oi

    JOIN warehouse.fact_orders fo
        ON oi.order_id = fo.order_id

    JOIN warehouse.dim_products dp
        ON oi.product_key = dp.product_key

    WHERE fo.order_status = 'delivered'

    GROUP BY
        dp.product_id,
        dp.product_category_name_english
),

ranked_products AS (

    SELECT
        product_id,
        category_name,
        units_sold,
        total_product_revenue,

        RANK() OVER (
            ORDER BY total_product_revenue DESC
        ) AS revenue_rank

    FROM product_performance
)

SELECT
    revenue_rank,
    product_id,
    category_name,
    units_sold,
    ROUND(total_product_revenue, 2) AS total_product_revenue

FROM ranked_products

WHERE revenue_rank <= 10

ORDER BY revenue_rank;


-- ============================================================
-- 5. CUSTOMER RETENTION ANALYSIS
-- Business Question:
-- What proportion of customers are repeat customers?
-- ============================================================

SELECT
    customer_type,
    COUNT(*) AS total_customers,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS customer_percentage

FROM analytics.vw_customer_value

GROUP BY customer_type

ORDER BY total_customers DESC;


-- ============================================================
-- 6. PAYMENT METHOD ANALYSIS
-- Business Question:
-- Which payment methods are most commonly used?
-- ============================================================

SELECT
    payment_type,

    COUNT(*) AS total_payment_transactions,

    COUNT(DISTINCT order_id) AS total_orders,

    ROUND(SUM(payment_value), 2) AS total_payment_value,

    ROUND(
        100.0 * SUM(payment_value) /
        NULLIF(SUM(SUM(payment_value)) OVER (), 0),
        2
    ) AS payment_value_percentage

FROM warehouse.fact_payments

GROUP BY payment_type

ORDER BY total_payment_value DESC;


-- ============================================================
-- 7. CUSTOMER REVIEW ANALYSIS
-- Business Question:
-- How satisfied are customers with their purchases?
-- ============================================================

-- Review score distribution

SELECT
    review_score,

    COUNT(*) AS total_reviews,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS review_percentage

FROM warehouse.fact_reviews

GROUP BY review_score

ORDER BY review_score DESC;


-- Overall review summary

SELECT
    ROUND(AVG(review_score), 2) AS average_review_score,

    COUNT(*) AS total_reviews,

    COUNT(*) FILTER (
        WHERE review_score >= 4
    ) AS positive_reviews,

    COUNT(*) FILTER (
        WHERE review_score <= 2
    ) AS negative_reviews

FROM warehouse.fact_reviews;


-- ============================================================
-- 8. DELIVERY PERFORMANCE ANALYSIS
-- Business Question:
-- How efficiently are orders being delivered?
-- ============================================================

SELECT
    delivered_orders,
    avg_carrier_to_customer_days,
    late_deliveries,
    late_delivery_percentage

FROM analytics.vw_delivery_performance;


-- ============================================================
-- END OF BUSINESS ANALYSIS
-- ============================================================
