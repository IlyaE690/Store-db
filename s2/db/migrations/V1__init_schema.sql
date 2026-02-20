CREATE SCHEMA IF NOT EXISTS warehouse;

CREATE TABLE IF NOT EXISTS warehouse.customer (
    id SERIAL PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50),
    email VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS warehouse.customer_archive (
    id INTEGER,
    last_name VARCHAR(50),
    first_name VARCHAR(50),
    patronymic VARCHAR(50),
    email VARCHAR(100),
    archive_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS warehouse.employee (
    id SERIAL PRIMARY KEY,
    warehouse_id INTEGER NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50),
    gender CHAR(1) CHECK (gender IN ('M', 'F')),
    birth_date DATE
);

CREATE TABLE IF NOT EXISTS warehouse.manager (
    id SERIAL PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50),
    gender CHAR(1) CHECK (gender IN ('M', 'F')),
    birth_date DATE
);

CREATE TABLE IF NOT EXISTS warehouse.manager_change_log (
    manager_id INTEGER PRIMARY KEY,
    old_last_name VARCHAR(50),
    old_first_name VARCHAR(50),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS warehouse.supplier (
    id SERIAL PRIMARY KEY,
    organization_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS warehouse.warehouse (
    id SERIAL PRIMARY KEY,
    address VARCHAR(200) NOT NULL,
    manager_id INTEGER REFERENCES warehouse.manager(id)
);

CREATE TABLE IF NOT EXISTS warehouse.product_category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS warehouse.product_catalog (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category_id INTEGER REFERENCES warehouse.product_category(id),
    unit_price INTEGER NOT NULL,
    unit_of_measure VARCHAR(20),
    supplier_id INTEGER REFERENCES warehouse.supplier(id),
    last_price_change TIMESTAMP
);

CREATE TABLE IF NOT EXISTS warehouse.product_inventory (
    product_id INTEGER REFERENCES warehouse.product_catalog(id),
    warehouse_id INTEGER REFERENCES warehouse.warehouse(id),
    stock_quantity INTEGER DEFAULT 0,
    PRIMARY KEY (product_id, warehouse_id)
);

CREATE TABLE IF NOT EXISTS warehouse.customer_order (
    id SERIAL PRIMARY KEY,
    customer_id INTEGER REFERENCES warehouse.customer(id),
    employee_id INTEGER REFERENCES warehouse.employee(id)
);

CREATE TABLE IF NOT EXISTS warehouse.order_item (
    order_id INTEGER REFERENCES warehouse.customer_order(id),
    product_id INTEGER REFERENCES warehouse.product_catalog(id),
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE IF NOT EXISTS warehouse.order_log (
    log_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    employee_id INTEGER NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    log_message TEXT
);

CREATE TABLE IF NOT EXISTS warehouse.payment_status (
    id SERIAL PRIMARY KEY,
    status VARCHAR(20) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS warehouse.payment (
    order_id INTEGER PRIMARY KEY REFERENCES warehouse.customer_order(id),
    amount INTEGER NOT NULL,
    status INTEGER REFERENCES warehouse.payment_status(id),
    payment_date DATE
);

CREATE TABLE IF NOT EXISTS warehouse.log (
    id SERIAL PRIMARY KEY,
    table_name TEXT,
    operation_type TEXT,
    delete_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);