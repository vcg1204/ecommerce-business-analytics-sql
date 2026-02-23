from faker import Faker
import psycopg2
import random

fake = Faker()

conn = psycopg2.connect(
    dbname="business_analytics_engine",
    user="postgres",
    password="vaishvee",
    host="localhost",
    port="5432"
)

cur = conn.cursor()

# --------- Generate Customers ---------

for _ in range(10000):
    cur.execute(
        """
        INSERT INTO customers (first_name, last_name, email, city, signup_date)
        VALUES (%s, %s, %s, %s, %s)
        """,
        (
            fake.first_name(),
            fake.last_name(),
            fake.unique.email(),
            fake.city(),
            fake.date_between(start_date='-2y', end_date='today')
        )
    )

print("Customers inserted")

# --------- Generate Products ---------

categories = ["Electronics", "Clothing", "Home", "Beauty", "Sports"]

for _ in range(200):
    cost = round(random.uniform(100, 2000), 2)
    price = round(cost * random.uniform(1.1, 1.6), 2)

    cur.execute(
        """
        INSERT INTO products (product_name, category, price, cost)
        VALUES (%s, %s, %s, %s)
        """,
        (
            fake.word().capitalize(),
            random.choice(categories),
            price,
            cost
        )
    )

print("Products inserted")

# --------- Generate Orders ---------

order_ids = []

for _ in range(50000):
    customer_id = random.randint(1, 10000)

    cur.execute(
        """
        INSERT INTO orders (customer_id, order_date, status)
        VALUES (%s, %s, %s)
        RETURNING order_id
        """,
        (
            customer_id,
            fake.date_time_between(start_date='-2y', end_date='now'),
            random.choice(["completed", "cancelled"])
        )
    )

    order_id = cur.fetchone()[0]
    order_ids.append(order_id)

print("Orders inserted")

# --------- Generate Order Items ---------

for order_id in order_ids:
    for _ in range(random.randint(1, 4)):
        product_id = random.randint(1, 200)
        quantity = random.randint(1, 3)

        # Get product price
        cur.execute(
            "SELECT price FROM products WHERE product_id = %s",
            (product_id,)
        )
        price = cur.fetchone()[0]

        cur.execute(
            """
            INSERT INTO order_items (order_id, product_id, quantity, selling_price)
            VALUES (%s, %s, %s, %s)
            """,
            (order_id, product_id, quantity, price)
        )

print("Order items inserted")

# --------- Generate Payments ---------

for order_id in order_ids:
    cur.execute(
        """
        SELECT SUM(quantity * selling_price)
        FROM order_items
        WHERE order_id = %s
        """,
        (order_id,)
    )

    amount = cur.fetchone()[0]

    cur.execute(
        """
        INSERT INTO payments (order_id, payment_method, payment_status, amount)
        VALUES (%s, %s, %s, %s)
        """,
        (
            order_id,
            random.choice(["UPI", "Card", "NetBanking", "COD"]),
            random.choice(["success", "failed"]),
            amount
        )
    )

print("Payments inserted")

# --------- Generate Returns ---------

cur.execute("SELECT order_item_id FROM order_items")
all_items = cur.fetchall()

for item in all_items:
    if random.random() < 0.1:
        cur.execute(
            """
            INSERT INTO returns (order_item_id, return_date, refund_amount)
            SELECT order_item_id, CURRENT_DATE, quantity * selling_price
            FROM order_items
            WHERE order_item_id = %s
            """,
            (item[0],)
        )

print("Returns inserted")


conn.commit()
cur.close()
conn.close()

print("Full dataset generation complete")
