-- ============================================================
-- PRODUCT ANALYSIS
-- Top products, category performance, profit margins
-- ============================================================

-- Top 10 Products by Revenue
SELECT 
    p.product_name,
    p.category,
    ROUND(SUM(oi.quantity * oi.selling_price), 2) AS product_revenue,
    SUM(oi.quantity) AS total_units_sold
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY p.product_name, p.category
ORDER BY product_revenue DESC
LIMIT 10;

-- Profit Margin by Category using actual cost column
SELECT 
    p.category,
    ROUND(SUM(oi.quantity * oi.selling_price), 2) AS total_revenue,
    ROUND(SUM(oi.quantity * p.cost), 2) AS total_cost,
    ROUND(SUM(oi.quantity * (oi.selling_price - p.cost)), 2) AS total_profit,
    ROUND(
        SUM(oi.quantity * (oi.selling_price - p.cost)) * 100.0
        / SUM(oi.quantity * oi.selling_price),
    2) AS profit_margin_percent
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status = 'completed'
GROUP BY p.category
ORDER BY profit_margin_percent DESC;

-- Most Returned Products
SELECT 
    p.product_name,
    p.category,
    COUNT(r.return_id) AS total_returns,
    ROUND(SUM(r.refund_amount), 2) AS total_refunded
FROM returns r
JOIN order_items oi ON r.order_item_id = oi.order_item_id
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name, p.category
ORDER BY total_returns DESC
LIMIT 10;

-- Payment Method Distribution
SELECT 
    payment_method,
    COUNT(*) AS total_transactions,
    ROUND(SUM(amount), 2) AS total_amount,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
    2) AS transaction_share_percent
FROM payments
WHERE payment_status = 'success'
GROUP BY payment_method
ORDER BY total_transactions DESC;

-- Failed Payment Rate by Method
SELECT 
    payment_method,
    COUNT(*) AS total_attempts,
    COUNT(*) FILTER (WHERE payment_status = 'failed') AS failed_payments,
    ROUND(
        COUNT(*) FILTER (WHERE payment_status = 'failed') * 100.0
        / COUNT(*),
    2) AS failure_rate_percent
FROM payments
GROUP BY payment_method
ORDER BY failure_rate_percent DESC;