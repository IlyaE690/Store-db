-- подзапрос в SELECT

-- 1.1) Информация о товаре с количеством заказов

SELECT 
    name AS product_name,
    unit_price / 100 AS price_rub,
    (SELECT COUNT(*) 
     FROM warehouse.order_item oi 
     WHERE oi.product_id = pc.id) AS order_count
FROM warehouse.product_catalog pc;

![Logo](1.png "Company Logo")


-- 1.2) Клиенты с общей суммой их заказов

SELECT 
    last_name || ' ' || first_name AS customer_name,
    (SELECT SUM(amount) / 100 
     FROM warehouse.payment p 
     JOIN warehouse.customer_order co ON p.order_id = co.id 
     WHERE co.customer_id = c.id AND p.status = 2) AS total_spent_rub
FROM warehouse.customer c;

![Logo](2.png "Company Logo")

-- 1.3) Получить название товара, его цену и цену с наценкой в 15%

SELECT name, unit_price, unit_price * 1.15 AS increased_price
FROM warehouse.product_catalog;

![Logo](3.png "Company Logo")

-- подзапрос в FROM

-- 2.1) Топ-5 самых популярных товаров

SELECT 
    product_name,
    total_ordered
FROM (
    SELECT 
        p.name AS product_name,
        SUM(oi.quantity) AS total_ordered
    FROM warehouse.order_item oi
    JOIN warehouse.product_catalog p ON oi.product_id = p.id
    GROUP BY p.id, p.name
) AS popular_products
ORDER BY total_ordered DESC
LIMIT 5;

![Logo](4.png "Company Logo")

-- 2.2) Клиенты с количеством заказов больше 1

SELECT 
    customer_name,
    order_count
FROM (
    SELECT 
        c.last_name || ' ' || c.first_name AS customer_name,
        COUNT(co.id) AS order_count
    FROM warehouse.customer c
    LEFT JOIN warehouse.customer_order co ON c.id = co.customer_id
    GROUP BY c.id, c.last_name, c.first_name
) AS customer_orders
WHERE order_count > 1;

![Logo](5.png "Company Logo")

-- 2.3) Средняя цена по категориям с фильтрацией

SELECT 
    category_name,
    avg_price_rub
FROM (
    SELECT 
        pc.name AS category_name,
        ROUND(AVG(p.unit_price) / 100, 2) AS avg_price_rub
    FROM warehouse.product_catalog p
    JOIN warehouse.product_category pc ON p.category_id = pc.id
    GROUP BY pc.id, pc.name
) AS category_prices
WHERE avg_price_rub > 50;

![Logo](6.png "Company Logo")

-- WHERE

-- 3.1)  Товары, которые есть на складе №1

SELECT 
    name AS product_name
FROM warehouse.product_catalog
WHERE id IN (
    SELECT product_id 
    FROM warehouse.product_inventory 
    WHERE warehouse_id = 1 AND stock_quantity > 0
);

![Logo](7.png "Company Logo")

-- 3.2) Клиенты, которые делали заказы в этом месяце

SELECT 
    last_name || ' ' || first_name AS customer_name
FROM warehouse.customer
WHERE id IN (
    SELECT DISTINCT customer_id
    FROM warehouse.customer_order co
    JOIN warehouse.payment p ON co.id = p.order_id
    WHERE EXTRACT(MONTH FROM p.payment_date) = EXTRACT(MONTH FROM CURRENT_DATE)
);

![Logo](8.png "Company Logo")

-- 3.3) Сотрудники, которые обрабатывали заказы

SELECT 
    last_name || ' ' || first_name AS employee_name
FROM warehouse.employee
WHERE id IN (
    SELECT DISTINCT employee_id 
    FROM warehouse.customer_order 
    WHERE employee_id IS NOT NULL
);

![Logo](9.png "Company Logo")

-- HAVING

-- 4.1) Категории, где средняя цена товаров выше средней цены всех товаров

SELECT 
    pc.name AS category_name,
    ROUND(AVG(p.unit_price) / 100, 2) AS avg_price_rub
FROM warehouse.product_catalog p
JOIN warehouse.product_category pc ON p.category_id = pc.id
GROUP BY pc.id, pc.name
HAVING AVG(p.unit_price) > (
    SELECT AVG(unit_price) 
    FROM warehouse.product_catalog
);

![Logo](10.png "Company Logo")

-- 4.2) Клиенты, у которых общая сумма заказов больше средней суммы заказов всех клиентов

SELECT 
    c.last_name || ' ' || c.first_name AS customer_name,
    SUM(p.amount) / 100 AS total_spent_rub
FROM warehouse.customer c
JOIN warehouse.customer_order co ON c.id = co.customer_id
JOIN warehouse.payment p ON co.id = p.order_id
WHERE p.status = 2
GROUP BY c.id, customer_name
HAVING SUM(p.amount) > (
    SELECT AVG(amount) 
    FROM warehouse.payment
    where status = 2
);

![Logo](11.png "Company Logo")

-- 4.3) Склады, где количество разных товаров больше чем на складе с минимальным ассортиментом

SELECT 
    w.address AS warehouse_address,
    COUNT(pi.product_id) AS product_count
FROM warehouse.warehouse w
JOIN warehouse.product_inventory pi ON w.id = pi.warehouse_id
GROUP BY w.id, w.address
HAVING COUNT(pi.product_id) > (
    SELECT MIN(product_count)
    FROM (
        SELECT COUNT(product_id) as product_count
        FROM warehouse.product_inventory
        GROUP BY warehouse_id
    ) AS warehouse_counts
);

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