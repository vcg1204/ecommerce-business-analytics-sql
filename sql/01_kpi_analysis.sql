-- Calculate total revenue before refunds
SELECT 
    SUM(quantity * selling_price) AS gross_revenue
FROM order_items;

-- Calculate total refunded amount
SELECT 
    SUM(refund_amount) AS total_refunds
FROM returns;

-- Calculate net revenue after deducting refunds
SELECT 
    SUM(oi.quantity * oi.selling_price) 
    - COALESCE(SUM(r.refund_amount), 0) AS net_revenue
FROM order_items oi
LEFT JOIN returns r
    ON oi.order_item_id = r.order_item_id;

-- Calculate average revenue generated per order
SELECT 
    ROUND(
        SUM(oi.quantity * oi.selling_price) 
        / COUNT(DISTINCT o.order_id),
    2) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id;

-- Calculate revenue contribution by each product category
SELECT 
    p.category,
    ROUND(SUM(oi.quantity * oi.selling_price), 2) AS category_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY category_revenue DESC;