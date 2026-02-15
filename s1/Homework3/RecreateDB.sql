CREATE SCHEMA warehouse;

CREATE TABLE warehouse.product_category (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Таблица поставщиков
CREATE TABLE warehouse.supplier (
    id SERIAL PRIMARY KEY,
    organization_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20)
);

-- Таблица менеджеров
CREATE TABLE warehouse.manager (
    id SERIAL PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50),
    gender CHAR(1) CHECK (gender IN ('M', 'F')),
    birth_date DATE
);

-- Таблица статусов оплаты
CREATE TABLE warehouse.payment_status (
    id SERIAL PRIMARY KEY,
    status VARCHAR(20) UNIQUE NOT NULL
);

-- Таблица складов
CREATE TABLE warehouse.warehouse (
    id SERIAL PRIMARY KEY,
    address VARCHAR(200) NOT NULL,
    manager_id INT,
    FOREIGN KEY (manager_id) REFERENCES warehouse.manager(id)
);

-- Таблица клиентов
CREATE TABLE warehouse.customer (
    id SERIAL PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50),
    email VARCHAR(100)
);

-- Таблица сотрудников
CREATE TABLE warehouse.employee (
    id SERIAL PRIMARY KEY,
    warehouse_id INT NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    patronymic VARCHAR(50),
    gender CHAR(1) CHECK (gender IN ('M', 'F')),
    birth_date DATE,
    FOREIGN KEY (warehouse_id) REFERENCES warehouse.warehouse(id)
);

-- Таблица каталога продуктов
CREATE TABLE warehouse.product_catalog (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category_id INT, 
    unit_price INT NOT NULL, 
    unit_of_measure VARCHAR(20),
    supplier_id INT, 
    FOREIGN KEY (category_id) REFERENCES warehouse.product_category(id),
    FOREIGN KEY (supplier_id) REFERENCES warehouse.supplier(id)
);

-- Таблица инвентаря
CREATE TABLE warehouse.product_inventory (
    product_id INT,  
    warehouse_id INT, 
    stock_quantity INT DEFAULT 0,
    PRIMARY KEY (product_id, warehouse_id),
    FOREIGN KEY (product_id) REFERENCES warehouse.product_catalog(id),
    FOREIGN KEY (warehouse_id) REFERENCES warehouse.warehouse(id)
);

-- Таблица заказов клиентов
CREATE TABLE warehouse.customer_order (
    id SERIAL PRIMARY KEY,
    customer_id INT,
    employee_id INT, 
    FOREIGN KEY (customer_id) REFERENCES warehouse.customer(id),
    FOREIGN KEY (employee_id) REFERENCES warehouse.employee(id)
);


-- Таблица позиций заказа
CREATE TABLE warehouse.order_item (
    order_id INT,  
    product_id INT, 
    quantity INT NOT NULL CHECK (quantity > 0),
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (product_id) REFERENCES warehouse.product_catalog(id),
	FOREIGN KEY (order_id) REFERENCES warehouse.customer_order(id)
);




-- Таблица платежей
CREATE TABLE warehouse.payment (
    order_id INT PRIMARY KEY,  
    amount INT NOT NULL,  
    status INT,  
    payment_date DATE NOT NULL,
    FOREIGN KEY (order_id) REFERENCES warehouse.customer_order(id),
    FOREIGN KEY (status) REFERENCES warehouse.payment_status(id)
);