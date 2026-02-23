-- Calculate monthly repeat purchase rate
WITH customer_orders AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT order_id) AS total_orders
    FROM orders
    GROUP BY customer_id
)
SELECT 
    ROUND(
        COUNT(*) FILTER (WHERE total_orders > 1) * 100.0
        / COUNT(*),
    2) AS repeat_purchase_rate_percent
FROM customer_orders;

-- Classify customers into value segments
WITH rfm AS (
    SELECT 
        o.customer_id,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(oi.quantity * oi.selling_price) AS monetary
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
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
FROM rfm;