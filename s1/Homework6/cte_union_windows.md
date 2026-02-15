# 1. CTE

## 1.1 Общее количество товаров по категориям
``` sql
WITH category_totals AS (
    SELECT 
        pc.category_id,
        SUM(pi.stock_quantity) AS total_quantity
    FROM warehouse.product_inventory pi
    JOIN warehouse.product_catalog pc ON pi.product_id = pc.id
    GROUP BY pc.category_id
)
SELECT * FROM category_totals;
```
![[image_2025-11-11_21-53-10.png]]
## 1.2 Средняя стоимость всех товаров по поставщикам
``` sql
WITH supplier_avg_price AS (
    SELECT 
        supplier_id,
        AVG(unit_price) AS avg_price
    FROM warehouse.product_catalog
    GROUP BY supplier_id
)
SELECT * FROM supplier_avg_price;
```
![[image_2025-11-11_21-53-39.png]]
## 1.3 Количество заказов по клиентам
``` sql
WITH customer_orders AS (
    SELECT 
        customer_id,
        COUNT(*) AS order_count
    FROM warehouse.customer_order
    GROUP BY customer_id
)
SELECT * FROM customer_orders;
```
![[image_2025-11-11_21-53-57.png]]
## 1.4 Сумма платежей по статусам
``` sql
WITH payment_totals AS (
    SELECT 
        status,
        SUM(amount) AS total_amount
    FROM warehouse.payment
    GROUP BY status
)
SELECT * FROM payment_totals;
```
![[image_2025-11-11_21-54-17.png]]
## 1.5 Количество сотрудников по складам
``` sql
WITH employee_count AS (
    SELECT 
        warehouse_id,
        COUNT(*) AS employee_count
    FROM warehouse.employee
    GROUP BY warehouse_id
)
SELECT * FROM employee_count;
```
![[image_2025-11-11_21-54-36.png]]
# 2. UNION

## 2.1 Имена сотрудников складов и их должности
``` sql
SELECT 
    'manager' AS role,
    last_name || ' ' || first_name AS full_name,
    'Управляющий' AS position
FROM warehouse.manager

UNION

SELECT 
    'employee' AS role,
    last_name || ' ' || first_name AS full_name,
    'Сотрудник склада' AS position
FROM warehouse.employee
ORDER BY role, full_name;
```
![[image_2025-11-11_21-54-56.png]]
## 2.2 Имена и контактные данные закачиков и поставщиков
``` sql
SELECT 
    'customer' AS type,
    last_name || ' ' || first_name AS full_name,
    email AS contact_info
FROM warehouse.customer
WHERE email IS NOT NULL

UNION

SELECT 
    'organization' AS type,
    organization_name AS full_name,
    phone AS contact_info
FROM warehouse.supplier
ORDER BY type, full_name;
```
![[image_2025-11-11_21-55-21.png]]
## 2.3 Товары дороже 80 рублей или с остатком меньше 20000
``` sql
SELECT 
    name AS product_name,
    unit_price / 100 AS price_rub,
    'Высокая цена' AS reason,
	0 AS warehouse
FROM warehouse.product_catalog
WHERE unit_price > 8000

UNION

SELECT 
    p.name AS product_name,
    p.unit_price / 100 AS price_rub,
    'Маленький остаток: ' || pi.stock_quantity AS reason,
	pi.warehouse_id as warehouse
FROM warehouse.product_catalog p
JOIN warehouse.product_inventory pi ON p.id = pi.product_id
WHERE pi.stock_quantity < 20000
ORDER BY price_rub DESC;
```
![[image_2025-11-11_21-56-21.png]]
# 3 INTERSECT

## 3.1 Выбрать товары стоимость которых меньше, чем средняя, среди тех, которые есть на каждом складе
``` sql
SELECT name AS product_name
FROM warehouse.product_catalog
WHERE unit_price < (SELECT AVG(unit_price) FROM warehouse.product_catalog)

INTERSECT

SELECT p.name AS product_name
FROM warehouse.product_catalog p
WHERE NOT EXISTS (
    SELECT w.id 
    FROM warehouse.warehouse w 
    WHERE NOT EXISTS (
        SELECT 1 
        FROM warehouse.product_inventory pi 
        WHERE pi.warehouse_id = w.id AND pi.product_id = p.id
    )
)
ORDER BY product_name;
```
![[image_2025-11-11_21-56-39.png]]
## 3.2 Вывести заказчиков, у которых есть email, если у них был сделан заказ
``` sql
SELECT id FROM warehouse.customer WHERE email IS NOT NULL
INTERSECT
SELECT customer_id FROM warehouse.customer_order;
```
![[image_2025-11-11_21-56-57.png]]
## 3.3 Сотрудники, которые обрабатывали заказы
``` sql
SELECT id FROM warehouse.employee
INTERSECT
SELECT employee_id FROM warehouse.customer_order;
```
![[image_2025-11-11_21-57-19.png]]
# 4 EXCEPT

## 4.1 Товары, которых нет на складах
``` sql
SELECT id, name FROM warehouse.product_catalog 

EXCEPT

SELECT product_id, pc.name FROM warehouse.product_inventory pi
JOIN warehouse.product_catalog pc ON pi.product_id = pc.id;
```
![[image_2025-11-11_21-57-47.png]]
## 4.2 Вывести название продукта, который никогда не заказывали
``` sql
SELECT name AS product_name
FROM warehouse.product_catalog

EXCEPT

SELECT DISTINCT p.name AS product_name
FROM warehouse.product_catalog p
JOIN warehouse.order_item oi ON p.id = oi.product_id
ORDER BY product_name;
```
![[image_2025-11-11_21-58-06.png]]
## 4.3 Вывести склад на котором нет мясных продуктов
``` sql
SELECT address AS warehouse_address
FROM warehouse.warehouse

EXCEPT

SELECT DISTINCT w.address AS warehouse_address
FROM warehouse.warehouse w
JOIN warehouse.product_inventory pi ON w.id = pi.warehouse_id
JOIN warehouse.product_catalog p ON pi.product_id = p.id
JOIN warehouse.product_category pc ON p.category_id = pc.id
WHERE pc.name = 'Мясные продукты'
ORDER BY warehouse_address;
```
![[image_2025-11-11_21-58-47.png]]
# 5 PARTITION BY

## 5.1 Количество товаров на складе с общей суммой по товару
``` sql
SELECT 
    product_id,
    warehouse_id,
    stock_quantity,
    SUM(stock_quantity) OVER (PARTITION BY product_id) AS total_by_product
FROM warehouse.product_inventory;
```
![[image_2025-11-11_22-01-22.png]]
## 5.2 Заказы с количеством заказов по клиенту
``` sql
SELECT 
    customer_id,
    id AS order_id,
    COUNT(*) OVER (PARTITION BY customer_id) AS orders_per_customer
FROM warehouse.customer_order;
```
![[image_2025-11-11_22-02-03.png]]
# 6 PARTITION BY + ORDER BY

## 6.1 Для каждого заказчика вывести по порядку его заказы с общей суммой всех заказов
``` sql
SELECT 
    co.customer_id,
    p.order_id,
    p.amount,
    SUM(p.amount) OVER (
        PARTITION BY co.customer_id 
        ORDER BY p.payment_date
    ) AS cumulative_amount
FROM warehouse.payment p
JOIN warehouse.customer_order co ON p.order_id = co.id;
```
![[image_2025-11-11_22-02-25.png]]
## 6.2 Анализ продаж по категориям за каждый месяц и по месяцам в общем 
``` sql
SELECT 
    pc.name AS category_name,
    EXTRACT(YEAR FROM p.payment_date) AS year,
    EXTRACT(MONTH FROM p.payment_date) AS month,
    SUM(oi.quantity) AS monthly_quantity,
    SUM(SUM(oi.quantity)) OVER (
        PARTITION BY pc.name 
        ORDER BY EXTRACT(YEAR FROM p.payment_date), EXTRACT(MONTH FROM p.payment_date)
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_quantity
FROM warehouse.order_item oi
JOIN warehouse.customer_order co ON oi.order_id = co.id
JOIN warehouse.payment p ON co.id = p.order_id
JOIN warehouse.product_catalog prod ON oi.product_id = prod.id
JOIN warehouse.product_category pc ON prod.category_id = pc.id
WHERE p.status = 2
GROUP BY pc.name, EXTRACT(YEAR FROM p.payment_date), EXTRACT(MONTH FROM p.payment_date)
ORDER BY pc.name, year, month;
```
![[image_2025-11-11_22-02-51.png]]
# 7 ROWS

## 7.1 Скользящее среднее платежей по 3 заказам
``` sql
SELECT 
    order_id,
    amount,
    AVG(amount) OVER (
        ORDER BY order_id 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS moving_avg
FROM warehouse.payment;
```
![[image_2025-11-11_22-03-06.png]]
## 7.2 Вывести всех работников склада по алфавиту и пронумеровать
``` sql
SELECT 
    last_name || ' ' || first_name AS employee_name,
    ROW_NUMBER() OVER (
        ORDER BY last_name, first_name
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS row_num
FROM warehouse.employee
ORDER BY last_name, first_name;
```
![[image_2025-11-11_22-03-22.png]]
# 8 RANGE

## 8.1 Сумма платежей по датам с группировкой
``` sql
SELECT 
    payment_date,
    amount,
    SUM(amount) OVER (
        ORDER BY payment_date
        RANGE BETWEEN CURRENT ROW AND CURRENT ROW
    ) AS daily_total
FROM warehouse.payment;
```
![[image_2025-11-11_22-03-47.png]]
## 8.2 Общая сумма платежей до текущей даты
``` sql
SELECT 
    payment_date,
    amount,
    SUM(amount) OVER (
        ORDER BY payment_date
        RANGE UNBOUNDED PRECEDING
    ) AS running_total
FROM warehouse.payment;
```
![[image_2025-11-11_22-04-11.png]]
# 9 ROW_NUMBER

## 9.1 Нумерация товаров по категориям
``` sql
SELECT 
    name,
    category_id,
    unit_price,
    ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY unit_price) as row_num
FROM warehouse.product_catalog;
```
![[image_2025-11-11_22-04-40.png]]
# 10 RANK

## 10.1 Рейтинг товаров по цене
``` sql
SELECT 
    name,
    unit_price,
    RANK() OVER (ORDER BY unit_price DESC) as price_rank
FROM warehouse.product_catalog;
```
![[image_2025-11-11_22-05-02.png]]

# 11 DENSE_RANK

## 11.1 Плотный рейтинг сотрудников по количеству заказов
``` sql
SELECT 
    DENSE_RANK() OVER (ORDER BY COUNT(co.id) DESC) AS performance_rank,
    e.last_name || ' ' || e.first_name AS employee_name,
    COUNT(co.id) AS order_count,
    SUM(p.amount) / 100 AS total_revenue_rub
FROM warehouse.employee e
JOIN warehouse.customer_order co ON e.id = co.employee_id
JOIN warehouse.payment p ON co.id = p.order_id
GROUP BY e.id, employee_name
ORDER BY performance_rank;
```
![[image_2025-11-11_22-05-20.png]]
# 12 LAG

## 12.1 Сравнение с предыдущим заказом клиента
``` sql
WITH customer_orders AS (
    SELECT 
        c.last_name || ' ' || c.first_name AS customer_name,
        co.id AS order_id,
        p.amount / 100 AS order_amount_rub,
        p.payment_date,
        p.amount / 100 - LAG(p.amount / 100) OVER (
            PARTITION BY co.customer_id 
            ORDER BY p.payment_date
        ) AS amount_change
    FROM warehouse.customer_order co
    JOIN warehouse.customer c ON co.customer_id = c.id
    JOIN warehouse.payment p ON co.id = p.order_id
    WHERE p.status = 2
)
SELECT 
    customer_name,
    order_id,
    order_amount_rub,
    amount_change
FROM customer_orders
ORDER BY customer_name, payment_date;
```
![[image_2025-11-11_22-05-41.png]]
# 13 LEAD

## 13.1 Следующий заказ по дате
``` sql
WITH ordered_payments AS (
    SELECT 
        co.id AS order_id,
        c.last_name || ' ' || c.first_name AS customer_name,
        p.payment_date,
        p.amount / 100 AS order_amount_rub,
        LEAD(p.payment_date) OVER (
            PARTITION BY co.customer_id 
            ORDER BY p.payment_date
        ) AS next_order_date,
        LEAD(p.amount / 100) OVER (
            PARTITION BY co.customer_id 
            ORDER BY p.payment_date
        ) AS next_order_amount_rub
    FROM warehouse.customer_order co
    JOIN warehouse.customer c ON co.customer_id = c.id
    JOIN warehouse.payment p ON co.id = p.order_id
    WHERE p.status = 2
)
SELECT 
    order_id,
    customer_name,
    payment_date,
    order_amount_rub,
    next_order_date,
    next_order_amount_rub
FROM ordered_payments
ORDER BY customer_name, payment_date;
```
![[image_2025-11-11_22-06-01.png]]
# 14 FIRST_VALUE

## 14.1 Первый товар в категории
``` sql
SELECT 
    name,
    category_id,
    unit_price,
    FIRST_VALUE(name) OVER (PARTITION BY category_id ORDER BY unit_price) as cheapest_product
FROM warehouse.product_catalog;
```
![[image_2025-11-11_22-06-31.png]]
# 15 LAST_VALUE

## 15.1 Последний товар в категории
``` sql
SELECT 
    name,
    category_id,
    unit_price,
    LAST_VALUE(name) OVER (
        PARTITION BY category_id 
        ORDER BY unit_price
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) as most_expensive_product
FROM warehouse.product_catalog;
```
![[image_2025-11-11_22-06-55.png]]