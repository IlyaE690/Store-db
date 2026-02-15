-- SELECT

-- 1.1) Получить полную информацию всех менеджеров
SELECT 
    last_name,
    first_name,
    patronymic,
    gender,
    birth_date
FROM warehouse.manager;

![Logo](1.png "Company Logo")


-- 1.2) Получить ФИО всех работников

SELECT 
    last_name,
    first_name,
    patronymic
FROM warehouse.employee;

![Logo](2.png "Company Logo")

-- 1.3) Получить название товара, его цену и цену с наценкой в 15%

SELECT name, unit_price, unit_price * 1.15 AS increased_price
FROM warehouse.product_catalog;

![Logo](3.png "Company Logo")

-- FROM

-- 2.1) Получить имена товаров и названия их категорий
SELECT pc.name AS product_name, pc2.name AS category_name
FROM warehouse.product_catalog pc
JOIN warehouse.product_category pc2 ON pc.category_id = pc2.id;

![Logo](4.png "Company Logo")

-- 2.2) Получить адреса складов и ФИО их менеджеров
SELECT w.address, m.last_name, m.first_name, m.patronymic
FROM warehouse.warehouse w
LEFT JOIN warehouse.manager m ON w.manager_id = m.id;

![Logo](5.png "Company Logo")

-- 2.3) Получить все заказы с email клиентов, которые их сделали
SELECT co.id AS order_id, c.email
FROM warehouse.customer_order co
INNER JOIN warehouse.customer c ON co.customer_id = c.id

![Logo](6.png "Company Logo")

-- WHERE

-- 3.1) Найти всех сотрудников мужского пола
SELECT *
FROM warehouse.employee
WHERE gender = 'M';

![Logo](7.png "Company Logo")

-- 3.2) Найти товары с ценой выше 100 р
SELECT *
FROM warehouse.product_catalog
WHERE unit_price > 10000;

![Logo](8.png "Company Logo")

-- 3.3) Найти платежи за 2024
SELECT *
FROM warehouse.payment
WHERE EXTRACT(YEAR FROM payment_date) = 2024;

![Logo](9.png "Company Logo")

-- HAVING

-- 4.1) Найти категории товаров, у которых средняя цена больше 1000
SELECT category_id, AVG(unit_price) AS avg_price
FROM warehouse.product_catalog
GROUP BY category_id
HAVING AVG(unit_price) > 10000;

![Logo](10.png "Company Logo")

-- 4.2) Найти склады, на которых хранится более 2 разных товаров
SELECT warehouse_id, COUNT(product_id) AS unique_products
FROM warehouse.product_inventory
GROUP BY warehouse_id
HAVING COUNT(product_id) > 2;

![Logo](11.png "Company Logo")

-- 4.3) Найти клиентов, сделавших хотя бы 2 заказа
SELECT customer_id, COUNT(id) AS order_count
FROM warehouse.customer_order
GROUP BY customer_id
HAVING COUNT(id) >= 2;

![Logo](12.png "Company Logo")

-- ALL

-- 5.1) Найти товары, которые дороже ВСЕХ товаров в категории 3
SELECT *
FROM warehouse.product_catalog
WHERE unit_price > ALL (
    SELECT unit_price
    FROM warehouse.product_catalog
    WHERE category_id = 3
);

![Logo](13.png "Company Logo")

-- 5.2) Найти сотрудников, которые старше ВСЕХ менеджеров женского пола
SELECT *
FROM warehouse.employee
WHERE birth_date < ALL (
    SELECT birth_date
    FROM warehouse.manager
    WHERE gender = 'F'
);

![Logo](14.png "Company Logo")

-- 5.3) Найти платежи, сумма которых больше ВСЕХ платежей со статусом (id=1)
SELECT *
FROM warehouse.payment
WHERE amount > ALL (
    SELECT amount
    FROM warehouse.payment
    WHERE status = 1
);

![Logo](15.png "Company Logo")

-- IN

-- 6.1) Найти менеджеров из списка наиболее распространенных фамилий
SELECT 
    m.last_name || ' ' || m.first_name AS manager_name
FROM warehouse.manager m
WHERE m.id IN (
    SELECT manager_id 
    FROM warehouse.warehouse 
    WHERE address LIKE '%Ленина%' OR address LIKE '%Мира%'
);

![Logo](16.png "Company Logo")

-- 6.2) Заказы, в которых есть товары от поставщика "ООО Мясной союз"
SELECT DISTINCT
    co.id AS order_id,
    c.last_name || ' ' || c.first_name AS customer_name
FROM warehouse.customer_order co
JOIN warehouse.customer c ON co.customer_id = c.id
JOIN warehouse.order_item oi ON co.id = oi.order_id
JOIN warehouse.product_catalog p ON oi.product_id = p.id
WHERE p.supplier_id IN (
    SELECT id FROM warehouse.supplier WHERE organization_name = 'ООО "Мясной союз"'
);

![Logo](17.png "Company Logo")

-- 6.3) Найти заказы, обработанные сотрудниками с определённых складов
SELECT *
FROM warehouse.customer_order
WHERE employee_id IN (
    SELECT id
    FROM warehouse.employee
    WHERE warehouse_id IN (1, 2)
);

![Logo](18.png "Company Logo")

-- ANY (SOME)

-- 7.1) Найти товары, которые дороже ХОТЯ БЫ ОДНОГО товара из категории 2
SELECT *
FROM warehouse.product_catalog
WHERE unit_price > ANY (
    SELECT unit_price
    FROM warehouse.product_catalog
    WHERE category_id = 2
);

![Logo](19.png "Company Logo")

-- 7.2) Найти сотрудников, которые моложе ХОТЯ БЫ ОДНОГО менеджера
SELECT *
FROM warehouse.employee
WHERE birth_date > ANY (
    SELECT birth_date
    FROM warehouse.manager
);

![Logo](20.png "Company Logo")

-- 7.3) Найти склады, на которых количество какого-либо товара больше 50000
SELECT *
FROM warehouse.warehouse
WHERE id = ANY (
    SELECT warehouse_id
    FROM warehouse.product_inventory
    WHERE stock_quantity > 50000
);

![Logo](21.png "Company Logo")

-- EXISTS

-- 8.1) Найти клиентов, которые делали хотя бы один заказ
SELECT *
FROM warehouse.customer c
WHERE EXISTS (
    SELECT 1
    FROM warehouse.customer_order co
    WHERE co.customer_id = c.id
);

![Logo](22.png "Company Logo")

-- 8.2) Найти категории, в которых есть хотя бы один товар
SELECT *
FROM warehouse.product_category pc
WHERE EXISTS (
    SELECT 1
    FROM warehouse.product_catalog pc2
    WHERE pc2.category_id = pc.id
);

![Logo](23.png "Company Logo")

-- 8.3) Поставщики, у которых есть товары на всех складах

SELECT 
    s.organization_name AS supplier_name
FROM warehouse.supplier s
WHERE NOT EXISTS (
    SELECT w.id
    FROM warehouse.warehouse w
    WHERE NOT EXISTS (
        SELECT 1
        FROM warehouse.product_catalog p
        INNER JOIN warehouse.product_inventory pi ON p.id = pi.product_id
        WHERE p.supplier_id = s.id
        AND pi.warehouse_id = w.id
    )
);

![Logo](24.png "Company Logo")


-- Сравнение по нескольким столбцам

-- 9.1) Найти сотрудников с такой же датой рождения и полом, как у менеджеров
SELECT e.*
FROM warehouse.employee e
WHERE (e.birth_date, e.gender) IN (
    SELECT m.birth_date, m.gender
    FROM warehouse.manager m
);

![Logo](25.png "Company Logo")

-- 9.2) Поиск сотрудников по полу и году рождения
SELECT last_name, first_name, gender, birth_date
FROM warehouse.employee
WHERE (gender, EXTRACT(YEAR FROM birth_date)) IN (
    ('M', 1995),
    ('F', 1997)
);

![Logo](26.png "Company Logo")

-- 9.3) Поиск клиентов по имени и email

SELECT last_name, first_name, email
FROM warehouse.customer
WHERE (last_name, email) IN (
    ('Петров', 'petrov@mail.ru'),
    ('Сидорова', 'sidorova@gmail.com')
);

![Logo](27.png "Company Logo")

-- Коррелированные подзапросы

-- 10.1) Для каждого товара вывести его название и среднюю цену по его категории
SELECT
    pc1.name,
    pc1.unit_price,
    (SELECT AVG(pc2.unit_price)
     FROM warehouse.product_catalog pc2
     WHERE pc2.category_id = pc1.category_id) AS avg_category_price
FROM warehouse.product_catalog pc1;

![Logo](28.png "Company Logo")

-- 10.2) Вывести список складов и количество различных товаров на каждом из них
SELECT
    w.id,
    w.address,
    (SELECT COUNT(*)
     FROM warehouse.product_inventory pi
     WHERE pi.warehouse_id = w.id) AS product_count
FROM warehouse.warehouse w;

![Logo](29.png "Company Logo")

-- 10.3) Найти клиентов, которые делали заказы больше одного раза
SELECT
    c.*,
    (SELECT COUNT(*)
     FROM warehouse.customer_order co
     WHERE co.customer_id = c.id) AS order_count
FROM warehouse.customer c
WHERE (SELECT COUNT(*)
       FROM warehouse.customer_order co2
       WHERE co2.customer_id = c.id) > 1;

![Logo](30.png "Company Logo")

-- 10.4) Для каждого заказа вывести его ID и общую стоимость всех товаров в нём
SELECT
    co.id AS order_id,
    (SELECT SUM(pc.unit_price * oi.quantity)
     FROM warehouse.order_item oi
     JOIN warehouse.product_catalog pc ON oi.product_id = pc.id
     WHERE oi.order_id = co.id) AS total_order_amount
FROM warehouse.customer_order co;

![Logo](31.png "Company Logo")

-- 10.5) Вывести товары, которые есть на всех складах (количество складов с товаром = общему количеству складов)
SELECT
    pc.name
FROM warehouse.product_catalog pc
WHERE (
    SELECT COUNT(DISTINCT pi.warehouse_id)
    FROM warehouse.product_inventory pi
    WHERE pi.product_id = pc.id
) = (SELECT COUNT(*) FROM warehouse.warehouse);

![Logo](32.png "Company Logo")