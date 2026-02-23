-- Calculate revenue per customer
SELECT 
    o.customer_id,
    ROUND(SUM(oi.quantity * oi.selling_price), 2) AS customer_revenue
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.customer_id
ORDER BY customer_revenue DESC;

-- Rank customers based on total revenue generated
SELECT 
    o.customer_id,
    ROUND(SUM(oi.quantity * oi.selling_price), 2) AS customer_revenue,
    RANK() OVER (
        ORDER BY SUM(oi.quantity * oi.selling_price) DESC
    ) AS revenue_rank
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY o.customer_id;

-- Calculate percentage contribution of each customer to total revenue
SELECT 
    customer_id,
    customer_revenue,
    ROUND(
        customer_revenue * 100.0 
        / SUM(customer_revenue) OVER (),
    2) AS revenue_percent
FROM (
    SELECT 
        o.customer_id,
        SUM(oi.quantity * oi.selling_price) AS customer_revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY o.customer_id
) sub
ORDER BY customer_revenue DESC;

-- Calculate revenue concentration from top 10% customers
WITH customer_revenue AS (
    SELECT 
        o.customer_id,
        SUM(oi.quantity * oi.selling_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
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