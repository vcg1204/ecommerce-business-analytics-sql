-- ============================================================
-- REVENUE ANALYSIS
-- Gross revenue, net revenue, refund rate, AOV, category breakdown
-- ============================================================

-- Gross Revenue (before refunds)
SELECT 
    ROUND(SUM(oi.quantity * oi.selling_price), 2) AS gross_revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'completed';

-- Net Revenue (after refunds)
WITH refunds AS (
    SELECT COALESCE(SUM(refund_amount), 0) AS total_refunds
    FROM returns
)
SELECT 
    ROUND(SUM(oi.quantity * oi.selling_price), 2) AS gross_revenue,
    ROUND(SUM(oi.quantity * oi.selling_price) - (SELECT total_refunds FROM refunds), 2) AS net_revenue,
    ROUND((SELECT total_refunds FROM refunds), 2) AS total_refunds
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'completed';

-- Refund Rate
SELECT 
    ROUND(
        COUNT(DISTINCT r.return_id) * 100.0 / COUNT(DISTINCT oi.order_item_id),
    2) AS refund_rate_percent
FROM order_items oi
LEFT JOIN returns r ON oi.order_item_id = r.order_item_id;

-- Average Order Value (AOV)
SELECT 
    ROUND(
        SUM(oi.quantity * oi.selling_price) / COUNT(DISTINCT oi.order_id),
    2) AS average_order_value
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'completed';

-- Revenue by Category
SELECT 
    p.category,
    ROUND(SUM(oi.quantity * oi.selling_price), 2) AS category_revenue,
    ROUND(SUM(oi.quantity * (oi.selling_price - p.cost)), 2) AS category_profit
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY category_revenue DESC;

-- Monthly Revenue Trend
SELECT 
    DATE_TRUNC('month', o.order_date) AS month,
    ROUND(SUM(oi.quantity * oi.selling_price), 2) AS monthly_revenue,
    COUNT(DISTINCT o.order_id) AS total_orders
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status = 'completed'
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY month;