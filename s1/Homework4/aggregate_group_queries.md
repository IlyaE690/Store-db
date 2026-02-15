1. Запросы с COUNT


1.1. Количество заказов по каждому клиенту
SELECT 
    c.last_name || ' ' || c.first_name AS customer_name,
    COUNT(co.id) AS order_count
FROM warehouse.customer c
LEFT JOIN warehouse.customer_order co ON c.id = co.customer_id
GROUP BY c.id, customer_name
ORDER BY order_count DESC;

![Logo](image_2025-10-28_21-47-45.png "Company Logo")

1.2 Количество различных товаров на каждом складе
SELECT 
    w.address AS warehouse_address,
    COUNT(pi.product_id) AS product_count
FROM warehouse.warehouse w
INNER JOIN warehouse.product_inventory pi ON w.id = pi.warehouse_id
GROUP BY w.id
ORDER BY product_count DESC;

![Logo](image_2025-10-28_21-57-20.png "Company Logo")

2. Запросы с SUM

2.1.  Общая стоимость покупок по каждому клиенту

SELECT 
    c.last_name || ' ' || c.first_name AS customer_name,
    SUM(p.amount) AS total_spent
FROM warehouse.customer c
INNER JOIN warehouse.customer_order co ON c.id = co.customer_id
INNER JOIN warehouse.payment p ON co.id = p.order_id
WHERE p.status = 2 -- Оплачено
GROUP BY c.id
ORDER BY total_spent DESC;

![Logo](image_2025-10-28_22-17-40.png "Company Logo")

2.2 Общее количество каждого товара на всех складах

SELECT pc.name AS product_name, SUM(pi.stock_quantity) AS total_amount
FROM warehouse.product_catalog pc INNER JOIN warehouse.product_inventory pi
ON pc.id = pi.product_id 
GROUP BY pc.name
ORDER BY total_amount

![Logo](image_2025-10-28_22-44-10.png "Company Logo")

3. Запросы с AVG

3.1. Средняя стоимость заказа

SELECT 
    ROUND(AVG(p.amount) / 100, 2) AS avg_order_amount_rub
FROM warehouse.payment p
WHERE p.status = 2; -- Оплачено

![Logo](image_2025-10-28_22-55-06.png "Company Logo")

3.2. Средняя цена товара по категориям

SELECT 
    pc.name AS category_name,
    ROUND(AVG(p.unit_price) / 100, 2) AS avg_price_rub
FROM warehouse.product_catalog p
INNER JOIN warehouse.product_category pc ON p.category_id = pc.id
GROUP BY pc.id
ORDER BY avg_price_rub DESC;

![Logo](image_2025-10-28_22-58-48.png "Company Logo")

4. Запросы с MIN 

4.1 Самая маленькая цена в каждой категории

SELECT 
    pc.name AS category_name,
    MIN(p.unit_price) / 100 AS min_price_rub
FROM warehouse.product_catalog p
JOIN warehouse.product_category pc ON p.category_id = pc.id
GROUP BY pc.id
ORDER BY min_price_rub;

![Logo](image_2025-10-28_23-12-32.png "Company Logo")

4.2 Самая ранняя дата платежа  

SELECT MIN(payment_date) AS earliest_payment FROM warehouse.payment;

![Logo](image_2025-10-28_23-12-52.png "Company Logo")

5. Запросы с MAX

5.1 Самая большая цена в каждой категории

SELECT 
    pc.name AS category_name,
    MAX(p.unit_price) / 100 AS max_price_rub
FROM warehouse.product_catalog p
JOIN warehouse.product_category pc ON p.category_id = pc.id
GROUP BY pc.id
ORDER BY pc.name, max_price_rub DESC;

![Logo](image_2025-10-28_23-19-48.png "Company Logo")

5.2. Наибольшее количество товара на складе

SELECT MAX(stock_quantity) AS max_stock FROM warehouse.product_inventory;

![Logo](image_2025-10-28_23-22-26.png "Company Logo")

6. Запросы с STRING_AGG

6.1 Список всех клиентов через запятую

SELECT 
    STRING_AGG(last_name || ' ' || first_name, ', ') AS all_customers
FROM warehouse.customer;

![Logo](image_2025-10-28_23-23-14.png "Company Logo")

6.2 Список товаров в каждом заказе

SELECT 
    co.id AS order_id,
    STRING_AGG(p.name || ' (' || oi.quantity || ' ' || p.unit_of_measure || ')', '; ') AS products_list
FROM warehouse.customer_order co
JOIN warehouse.order_item oi ON co.id = oi.order_id
JOIN warehouse.product_catalog p ON oi.product_id = p.id
GROUP BY co.id
ORDER BY co.id;

![Logo](image_2025-10-28_23-37-00.png "Company Logo")

7. Запросы с GROUP BY  


7.1 Количество заказов, обработанных каждым сотрудником

SELECT 
    e.last_name || ' ' || e.first_name AS employee_name,
    COUNT(co.id) AS processed_orders
FROM warehouse.employee e
INNER JOIN warehouse.customer_order co ON e.id = co.employee_id
GROUP BY e.id, employee_name
ORDER BY processed_orders DESC;

![Logo](image_2025-10-28_23-37-57.png "Company Logo")

7.2 Общая сумма платежей по статусам

SELECT s.status, SUM(amount) AS total_amount 
FROM warehouse.payment p INNER JOIN warehouse.payment_status s
ON p.status = s.id
GROUP BY s.status;

![Logo](image_2025-10-28_23-38-11.png "Company Logo")

8.Запросы с HAVING


8.1  Категории с средней ценой товара выше 80 рублей


SELECT 
    pc.name AS category_name,
    ROUND(AVG(p.unit_price) / 100, 2) AS avg_price_rub
FROM warehouse.product_catalog p
INNER JOIN warehouse.product_category pc ON p.category_id = pc.id
GROUP BY pc.id, pc.name
HAVING AVG(p.unit_price) > 8000
ORDER BY avg_price_rub DESC;

![Logo](image_2025-10-28_23-38-22.png "Company Logo")

8.2 Клиенты с более чем 1 заказом

SELECT 
    c.last_name || ' ' || c.first_name AS customer_name,
    COUNT(co.id) AS order_count
FROM warehouse.customer c
INNER JOIN warehouse.customer_order co ON c.id = co.customer_id
GROUP BY c.id, customer_name
HAVING COUNT(co.id) > 1
ORDER BY order_count DESC;

![Logo](image_2025-10-28_23-45-16.png "Company Logo")

9. Запросы с GROUPING SETS


9.1 Анализ продаж по категориям и поставщикам

SELECT 
    pc.name AS category_name,
    s.organization_name AS supplier_name,
    COUNT(oi.product_id) AS items_sold,
    SUM(oi.quantity) AS total_quantity
FROM warehouse.order_item oi
INNER JOIN warehouse.product_catalog p ON oi.product_id = p.id
INNER JOIN warehouse.product_category pc ON p.category_id = pc.id
INNER JOIN warehouse.supplier s ON p.supplier_id = s.id
GROUP BY GROUPING SETS (
    (pc.name),
    (s.organization_name),
    (pc.name, s.organization_name),
    ()
)

![Logo](image_2025-10-28_23-45-53.png "Company Logo")

9.2 Анализ запасов по складам и категориям

SELECT 
    w.address AS warehouse_address,
    pc.name AS category_name,
    SUM(pi.stock_quantity) AS total_stock
FROM warehouse.product_inventory pi
INNER JOIN warehouse.warehouse w ON pi.warehouse_id = w.id
INNER JOIN warehouse.product_catalog p ON pi.product_id = p.id
INNER JOIN warehouse.product_category pc ON p.category_id = pc.id
GROUP BY GROUPING SETS (
    (w.address),
    (pc.name),
    (w.address, pc.name)
)

![Logo](image_2025-10-28_23-48-35.png "Company Logo")

10. Запросы с ROLLUP


10.1 Иерархический отчет по складам и категориям

SELECT 
    w.address AS warehouse_address,
    pc.name AS category_name,
    SUM(pi.stock_quantity) AS total_stock,
    SUM(pi.stock_quantity * p.unit_price) / 100 AS total_value_rub
FROM warehouse.product_inventory pi
INNER JOIN warehouse.warehouse w ON pi.warehouse_id = w.id
INNER JOIN warehouse.product_catalog p ON pi.product_id = p.id
INNER JOIN warehouse.product_category pc ON p.category_id = pc.id
GROUP BY ROLLUP (w.address, pc.name);

![Logo](image_2025-10-28_23-51-57.png "Company Logo")

10.2 

SELECT 
    EXTRACT(YEAR FROM py.payment_date) AS payment_year,
    c.last_name || ' ' || c.first_name AS customer_name,
    COUNT(co.id) AS order_count,
    SUM(py.amount) / 100 AS total_amount_rub
FROM warehouse.customer_order co
INNER JOIN warehouse.customer c ON co.customer_id = c.id
INNER JOIN warehouse.payment py ON co.id = py.order_id
WHERE py.status = 2
GROUP BY ROLLUP (EXTRACT(YEAR FROM py.payment_date), c.last_name || ' ' || c.first_name)
ORDER BY payment_year, customer_name;

![Logo](image_2025-10-28_23-57-42.png "Company Logo")

11. Запросы с CUBE


11.1 Все возможные комбинации группировки по категориям и поставщикам

SELECT 
    pc.name,
    s.organization_name,
    COUNT(*) AS products_count,
    ROUND(AVG(unit_price), 2) AS avg_price
FROM warehouse.product_catalog p 
INNER JOIN  warehouse.product_category pc ON p.category_id = pc.id
INNER JOIN warehouse.supplier s ON p.supplier_id = s.id
GROUP BY CUBE (pc.name, s.organization_name);

![Logo](image_2025-10-29_00-09-38.png "Company Logo")

11.2 Многомерный анализ заказов по клиентам, сотрудникам и складам

SELECT 
    c.last_name || ' ' || c.first_name AS customer_name,
    e.last_name || ' ' || e.first_name AS employee_name,
    w.address AS warehouse_address,
    COUNT(co.id) AS order_count,
    SUM(py.amount) / 100 AS total_amount_rub
FROM warehouse.customer_order co
JOIN warehouse.customer c ON co.customer_id = c.id
JOIN warehouse.employee e ON co.employee_id = e.id
JOIN warehouse.warehouse w ON e.warehouse_id = w.id
JOIN warehouse.payment py ON co.id = py.order_id
WHERE py.status = 2
GROUP BY CUBE (c.last_name || ' ' || c.first_name, e.last_name || ' ' || e.first_name, w.address)

![Logo](image_2025-10-29_00-12-12.png "Company Logo")