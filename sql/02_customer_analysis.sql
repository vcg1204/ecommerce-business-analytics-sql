-- ============================================================
-- CUSTOMER ANALYSIS
-- Revenue per customer, ranking, concentration, segmentation
-- ============================================================

-- Revenue per Customer
SELECT 
    o.customer_id,
    ROUND(SUM(oi.quantity * oi.selling_price), 2) AS customer_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'completed'
GROUP BY o.customer_id
ORDER BY customer_revenue DESC;

-- Customer Revenue Ranking
SELECT 
    o.customer_id,
    ROUND(SUM(oi.quantity * oi.selling_price), 2) AS customer_revenue,
    RANK() OVER (
        ORDER BY SUM(oi.quantity * oi.selling_price) DESC
    ) AS revenue_rank
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'completed'
GROUP BY o.customer_id;

-- Percentage Contribution of Each Customer to Total Revenue
SELECT 
    customer_id,
    ROUND(customer_revenue, 2) AS customer_revenue,
    ROUND(
        customer_revenue * 100.0 / SUM(customer_revenue) OVER (),
    2) AS revenue_percent
FROM (
    SELECT 
        o.customer_id,
        SUM(oi.quantity * oi.selling_price) AS customer_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY o.customer_id
) sub
ORDER BY customer_revenue DESC;

-- Top 10% Customer Revenue Concentration
WITH customer_revenue AS (
    SELECT 
        o.customer_id,
        SUM(oi.quantity * oi.selling_price) AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY o.customer_id
),
ranked_customers AS (
    SELECT *,
        NTILE(10) OVER (ORDER BY revenue DESC) AS decile
    FROM customer_revenue
)
SELECT 
    ROUND(
        SUM(revenue) FILTER (WHERE decile = 1) * 100.0
        / SUM(revenue),
    2) AS top_10_percent_revenue_share
FROM ranked_customers;

-- Repeat Purchase Rate
WITH customer_orders AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
)
SELECT 
    ROUND(
        COUNT(*) FILTER (WHERE total_orders > 1) * 100.0
        / COUNT(*),
    2) AS repeat_purchase_rate_percent
FROM customer_orders;

-- Customer Value Segmentation (RFM-based)
WITH rfm AS (
    SELECT 
        o.customer_id,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(oi.quantity * oi.selling_price), 2) AS monetary
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY o.customer_id
)
SELECT 
    customer_id,
    frequency,
    monetary,
    CASE 
        WHEN frequency >= 5 AND monetary >= 5000 THEN 'High Value'
        WHEN frequency >= 3 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS customer_segment
FROM rfm
ORDER BY monetary DESC;