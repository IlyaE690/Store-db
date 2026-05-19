
CREATE SCHEMA IF NOT EXISTS olap;

CREATE TABLE IF NOT EXISTS olap.dim_date (
                                             date_id INTEGER PRIMARY KEY,
                                             full_date DATE NOT NULL,
                                             year INTEGER NOT NULL,
                                             quarter INTEGER NOT NULL,
                                             month INTEGER NOT NULL,
                                             month_name VARCHAR(20) NOT NULL,
    day INTEGER NOT NULL,
    day_of_week INTEGER NOT NULL,
    day_name VARCHAR(20) NOT NULL,
    week INTEGER NOT NULL,
    is_weekend BOOLEAN NOT NULL,
    season VARCHAR(10)
    );

CREATE TABLE IF NOT EXISTS olap.dim_customer (
                                                 customer_sk SERIAL PRIMARY KEY,
                                                 customer_id INTEGER NOT NULL UNIQUE,
                                                 last_name VARCHAR(50),
    first_name VARCHAR(50),
    full_name VARCHAR(150),
    email VARCHAR(100),
    loyalty_level VARCHAR(20),
    total_orders INTEGER DEFAULT 0,
    total_spent BIGINT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

CREATE TABLE IF NOT EXISTS olap.dim_category (
                                                 category_id INTEGER PRIMARY KEY,
                                                 category_name VARCHAR(100) NOT NULL
    );

CREATE TABLE IF NOT EXISTS olap.dim_product (
                                                product_id INTEGER PRIMARY KEY,
                                                product_name VARCHAR(200) NOT NULL,
    category_id INTEGER REFERENCES olap.dim_category(category_id),
    category_name VARCHAR(100),
    supplier_name VARCHAR(100),
    brand VARCHAR(50),
    unit_price INTEGER,
    unit_of_measure VARCHAR(20)
    );

CREATE TABLE IF NOT EXISTS olap.fact_sales (
                                               sale_id BIGSERIAL PRIMARY KEY,
                                               order_id INTEGER NOT NULL,
                                               date_id INTEGER REFERENCES olap.dim_date(date_id),
    customer_sk INTEGER REFERENCES olap.dim_customer(customer_sk),
    product_id INTEGER REFERENCES olap.dim_product(product_id),
    category_id INTEGER,
    quantity INTEGER NOT NULL,
    unit_price INTEGER NOT NULL,
    total_amount INTEGER NOT NULL,
    discount_amount INTEGER DEFAULT 0,
    net_amount INTEGER NOT NULL,
    source_channel VARCHAR(20),
    etl_loaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

CREATE INDEX idx_fact_date ON olap.fact_sales(date_id);
CREATE INDEX idx_fact_customer ON olap.fact_sales(customer_sk);
CREATE INDEX idx_fact_product ON olap.fact_sales(product_id);