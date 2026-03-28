import psycopg2
import pandas as pd
import matplotlib.pyplot as plt
import os

os.makedirs("outputs", exist_ok=True)

# Connect to database
conn = psycopg2.connect(
    dbname="business_analytics_engine",
    user="postgres",
    password="vaishvee",
    host="localhost",
    port="5432"
)

# ── Chart 1: Monthly Revenue Trend ────────────────────────────────────────────
monthly_revenue = pd.read_sql("""
    SELECT 
        DATE_TRUNC('month', o.order_date) AS month,
        ROUND(SUM(oi.quantity * oi.selling_price), 2) AS monthly_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY DATE_TRUNC('month', o.order_date)
    ORDER BY month
""", conn)

fig, ax = plt.subplots(figsize=(12, 5))
ax.plot(monthly_revenue["month"], monthly_revenue["monthly_revenue"],
        marker="o", color="steelblue", linewidth=2, markersize=4)
ax.set_title("Monthly Revenue Trend", fontsize=14, fontweight="bold")
ax.set_xlabel("Month")
ax.set_ylabel("Revenue")
ax.grid(True, alpha=0.3)
plt.xticks(rotation=45)
plt.tight_layout()
plt.savefig("outputs/monthly_revenue_trend.png", dpi=150)
plt.close()
print("Saved: monthly_revenue_trend.png")

# ── Chart 2: Revenue by Category ──────────────────────────────────────────────
category_revenue = pd.read_sql("""
    SELECT 
        p.category,
        ROUND(SUM(oi.quantity * oi.selling_price), 2) AS category_revenue,
        ROUND(SUM(oi.quantity * (oi.selling_price - p.cost)), 2) AS category_profit
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY p.category
    ORDER BY category_revenue DESC
""", conn)

fig, ax = plt.subplots(figsize=(8, 5))
x = range(len(category_revenue))
width = 0.35
bars1 = ax.bar([i - width/2 for i in x], category_revenue["category_revenue"],
               width, label="Revenue", color="steelblue", edgecolor="white")
bars2 = ax.bar([i + width/2 for i in x], category_revenue["category_profit"],
               width, label="Profit", color="darkorange", edgecolor="white")

ax.set_title("Revenue and Profit by Category", fontsize=13, fontweight="bold")
ax.set_xticks(list(x))
ax.set_xticklabels(category_revenue["category"])
ax.set_ylabel("Amount")
ax.legend()
ax.grid(axis="y", alpha=0.3)
plt.tight_layout()
plt.savefig("outputs/revenue_by_category.png", dpi=150)
plt.close()
print("Saved: revenue_by_category.png")

# ── Chart 3: Customer Segmentation ────────────────────────────────────────────
segments = pd.read_sql("""
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
        CASE 
            WHEN frequency >= 5 AND monetary >= 5000 THEN 'High Value'
            WHEN frequency >= 3 THEN 'Mid Value'
            ELSE 'Low Value'
        END AS customer_segment,
        COUNT(*) AS customer_count
    FROM rfm
    GROUP BY customer_segment
    ORDER BY customer_count DESC
""", conn)

colors = ["steelblue", "darkorange", "green"]
fig, ax = plt.subplots(figsize=(7, 7))
ax.pie(segments["customer_count"], labels=segments["customer_segment"],
       autopct="%1.1f%%", colors=colors, startangle=140,
       wedgeprops={"edgecolor": "white"})
ax.set_title("Customer Segmentation Distribution", fontsize=13, fontweight="bold")
plt.tight_layout()
plt.savefig("outputs/customer_segmentation.png", dpi=150)
plt.close()
print("Saved: customer_segmentation.png")

# ── Chart 4: Profit Margin by Category ────────────────────────────────────────
margins = pd.read_sql("""
    SELECT 
        p.category,
        ROUND(
            SUM(oi.quantity * (oi.selling_price - p.cost)) * 100.0
            / SUM(oi.quantity * oi.selling_price),
        2) AS profit_margin_percent
    FROM order_items oi
    JOIN products p ON oi.product_id = p.product_id
    JOIN orders o ON oi.order_id = o.order_id
    WHERE o.status = 'completed'
    GROUP BY p.category
    ORDER BY profit_margin_percent DESC
""", conn)

fig, ax = plt.subplots(figsize=(8, 5))
bars = ax.bar(margins["category"], margins["profit_margin_percent"],
              color="steelblue", edgecolor="white")

for bar, val in zip(bars, margins["profit_margin_percent"]):
    ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.2,
            f"{val}%", ha="center", va="bottom", fontsize=10)

ax.set_title("Profit Margin by Category", fontsize=13, fontweight="bold")
ax.set_ylabel("Profit Margin (%)")
ax.set_ylim(0, margins["profit_margin_percent"].max() * 1.15)
ax.grid(axis="y", alpha=0.3)
plt.tight_layout()
plt.savefig("outputs/profit_margin_by_category.png", dpi=150)
plt.close()
print("Saved: profit_margin_by_category.png")

# ── Chart 5: Payment Method Distribution ──────────────────────────────────────
payments = pd.read_sql("""
    SELECT 
        payment_method,
        COUNT(*) AS total_transactions
    FROM payments
    WHERE payment_status = 'success'
    GROUP BY payment_method
    ORDER BY total_transactions DESC
""", conn)

fig, ax = plt.subplots(figsize=(7, 7))
ax.pie(payments["total_transactions"], labels=payments["payment_method"],
       autopct="%1.1f%%", startangle=140,
       colors=["steelblue", "darkorange", "green", "crimson"],
       wedgeprops={"edgecolor": "white"})
ax.set_title("Payment Method Distribution", fontsize=13, fontweight="bold")
plt.tight_layout()
plt.savefig("outputs/payment_method_distribution.png", dpi=150)
plt.close()
print("Saved: payment_method_distribution.png")

conn.close()
print("\nAll charts saved to /outputs folder.")