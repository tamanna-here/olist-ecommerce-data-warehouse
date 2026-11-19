-- ============================================================
-- OLIST E-COMMERCE DATA WAREHOUSE
-- File: 08_optimization.sql
-- Database: olist_ecommerce
--
-- Purpose:
-- Improve analytical query efficiency using a materialized
-- view and indexing, and inspect query execution plans.
--
-- SQL concepts:
-- Materialized Views, Indexing, REFRESH,
-- EXPLAIN ANALYZE and BUFFERS.
-- ============================================================


-- ============================================================
-- 1. CREATE MATERIALIZED VIEW
-- Purpose:
-- Store the monthly revenue analysis results so they can
-- be queried without recalculating the underlying view
-- every time.
-- ============================================================

CREATE MATERIALIZED VIEW analytics.mv_monthly_revenue AS

SELECT
    year,
    month,
    month_name,
    total_orders,
    product_revenue,
    freight_revenue,
    total_revenue

FROM analytics.vw_monthly_revenue;


-- ============================================================
-- 2. CREATE UNIQUE INDEX
-- Purpose:
-- Create an index on year and month to support efficient
-- lookups of monthly revenue records.
-- ============================================================

CREATE UNIQUE INDEX idx_mv_monthly_revenue_year_month

ON analytics.mv_monthly_revenue (year, month);


-- ============================================================
-- 3. REFRESH MATERIALIZED VIEW
-- Purpose:
-- Update the stored results using the latest data
-- available in the underlying tables and view.
-- ============================================================

REFRESH MATERIALIZED VIEW analytics.mv_monthly_revenue;


-- ============================================================
-- 4. VERIFY MATERIALIZED VIEW
-- Purpose:
-- Check that the materialized view contains the expected
-- monthly revenue records.
-- ============================================================

SELECT *
FROM analytics.mv_monthly_revenue
ORDER BY year, month;


-- ============================================================
-- 5. QUERY PERFORMANCE ANALYSIS
-- Purpose:
-- Inspect the execution plan, execution time and buffer
-- activity for a filtered monthly revenue query.
-- ============================================================

EXPLAIN (ANALYZE, BUFFERS)

SELECT *
FROM analytics.mv_monthly_revenue
WHERE year = 2018
ORDER BY month;


-- ============================================================
-- END OF OPTIMIZATION
-- ============================================================
