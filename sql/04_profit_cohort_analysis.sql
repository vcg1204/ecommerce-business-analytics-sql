-- Estimate profit assuming 30% cost of goods
SELECT 
    ROUND(
        SUM(oi.quantity * oi.selling_price) * 0.7,
    2) AS estimated_profit
FROM order_items oi;

-- Analyze customer acquisition by month
SELECT 
    DATE_TRUNC('month', MIN(order_date)) AS acquisition_month,
    COUNT(DISTINCT customer_id) AS new_customers
FROM orders
GROUP BY customer_id
ORDER BY acquisition_month;