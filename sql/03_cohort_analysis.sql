-- ============================================================
-- COHORT ANALYSIS
-- Tracks retention of customers acquired in the same month
-- over subsequent months
-- ============================================================

-- Step 1: Find each customer's first order month (acquisition cohort)
WITH customer_cohort AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', MIN(order_date)) AS cohort_month
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
),

-- Step 2: Find all months each customer made a purchase
customer_activity AS (
    SELECT 
        o.customer_id,
        DATE_TRUNC('month', o.order_date) AS activity_month
    FROM orders o
    WHERE o.status = 'completed'
    GROUP BY o.customer_id, DATE_TRUNC('month', o.order_date)
),

-- Step 3: Calculate how many months after acquisition each purchase happened
cohort_data AS (
    SELECT 
        c.cohort_month,
        a.activity_month,
        EXTRACT(YEAR FROM AGE(a.activity_month, c.cohort_month)) * 12 +
        EXTRACT(MONTH FROM AGE(a.activity_month, c.cohort_month)) AS months_since_acquisition,
        COUNT(DISTINCT a.customer_id) AS active_customers
    FROM customer_cohort c
    JOIN customer_activity a ON c.customer_id = a.customer_id
    GROUP BY c.cohort_month, a.activity_month
),

-- Step 4: Get cohort sizes (total customers acquired per month)
cohort_sizes AS (
    SELECT 
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM customer_cohort
    GROUP BY cohort_month
)

-- Step 5: Calculate retention rate per cohort per month
SELECT 
    cd.cohort_month,
    cs.cohort_size,
    cd.months_since_acquisition,
    cd.active_customers,
    ROUND(
        cd.active_customers * 100.0 / cs.cohort_size,
    2) AS retention_rate_percent
FROM cohort_data cd
JOIN cohort_sizes cs ON cd.cohort_month = cs.cohort_month
WHERE cd.months_since_acquisition <= 12
ORDER BY cd.cohort_month, cd.months_since_acquisition;