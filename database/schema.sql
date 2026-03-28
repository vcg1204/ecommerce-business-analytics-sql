-- Database: ecommerce_business_analytics

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    city VARCHAR(50),
    signup_date DATE
);

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price NUMERIC(10,2),
    cost NUMERIC(10,2)
);

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES customers(customer_id),
    order_date TIMESTAMP,
    status VARCHAR(20) CHECK (status IN ('completed', 'cancelled'))
);

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    product_id INT REFERENCES products(product_id),
    quantity INT CHECK (quantity > 0),
    selling_price NUMERIC(10,2)
);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INT REFERENCES orders(order_id),
    payment_method VARCHAR(30),
    payment_status VARCHAR(20) CHECK (payment_status IN ('success', 'failed')),
    amount NUMERIC(10,2)
);

CREATE TABLE returns (
    return_id SERIAL PRIMARY KEY,
    order_item_id INT REFERENCES order_items(order_item_id),
    return_date DATE,
    refund_amount NUMERIC(10,2)
);