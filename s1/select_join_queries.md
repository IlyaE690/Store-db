--SELECT
SELECT * FROM warehouse.customer;
SELECT * FROM warehouse.product_catalog;

--select нескольких столбцов
SELECT last_name, first_name, email FROM warehouse.customer;
SELECT name, unit_price, unit_of_measure FROM warehouse.product_catalog;

--select c присвоением новых имен столбцам
SELECT last_name AS фамилия, first_name AS имя FROM warehouse.customer;
SELECT name AS название, unit_price AS цена FROM warehouse.product_catalog;

-- select с созданием вычисляемого столбца
SELECT name, unit_price, unit_price * 1.2 AS price_with_tax 
FROM warehouse.product_catalog;

SELECT last_name, first_name, EXTRACT(YEAR FROM AGE(birth_date)) AS age 
FROM warehouse.employee;

--select с логической функцией
SELECT last_name, first_name, birth_date,
       CASE 
           WHEN birth_date < '1990-01-01' THEN 'Взрослый'
           ELSE 'Молодой'
       END AS возрастная_группа
FROM warehouse.employee;

SELECT name, unit_price,
       CASE 
           WHEN unit_price > 1000 THEN 'Дорогой'
           WHEN unit_price BETWEEN 500 AND 1000 THEN 'Средний'
           ELSE 'Бюджетный'
       END AS price_category
FROM warehouse.product_catalog;

--select c условием
SELECT * FROM warehouse.product_catalog WHERE unit_price > 500;
SELECT last_name, first_name FROM warehouse.customer WHERE email IS NOT NULL;

--select c OR, AND, BETWEEN, IN
SELECT * FROM warehouse.product_catalog 
WHERE unit_price BETWEEN 100 AND 1000 
   OR category_id IN (1, 2, 3);

SELECT last_name, first_name, birth_date 
FROM warehouse.employee 
WHERE gender = 'M' AND EXTRACT(YEAR FROM birth_date) BETWEEN 1980 AND 1990;

--select с order by
SELECT name, unit_price FROM warehouse.product_catalog 
ORDER BY unit_price DESC;

SELECT last_name, first_name, birth_date FROM warehouse.employee 
ORDER BY last_name, first_name;

--select с like
SELECT last_name, first_name FROM warehouse.customer 
WHERE last_name LIKE 'Ив%';

SELECT name FROM warehouse.product_catalog 
WHERE name LIKE '%стол%' OR name LIKE '%шкаф%';

--select уникальныз элементов
SELECT DISTINCT district FROM warehouse.warehouse;
SELECT DISTINCT category_id FROM warehouse.product_catalog;

--select с ограничением на возвращаемые строчки
SELECT * FROM warehouse.product_catalog LIMIT 10;

SELECT last_name, first_name FROM warehouse.customer 
ORDER BY id DESC LIMIT 5;

--select c inner join 
SELECT pcatalog.name, pcatalog.unit_price, pcategory.name as category
FROM warehouse.product_catalog pcatalog
INNER JOIN warehouse.product_category pcategory ON pcatalog.category_id = pcategory.id;

SELECT co.id, c.last_name, c.first_name
FROM warehouse.customer_order co
INNER JOIN warehouse.customer c ON co.customer_id = c.id;

--select c left, right join
SELECT w.address, m.last_name as manager
FROM warehouse.warehouse w
LEFT JOIN warehouse.manager m ON w.manager_id = m.id;

SELECT c.last_name, c.first_name, co.id as order_id
FROM warehouse.customer c
LEFT JOIN warehouse.customer_order co ON c.id = co.customer_id;

SELECT m.last_name, w.address
FROM warehouse.warehouse w
RIGHT JOIN warehouse.manager m ON w.manager_id = m.id;

SELECT ps.status, p.amount
FROM warehouse.payment p
RIGHT JOIN warehouse.payment_status ps ON p.status = ps.id;

--select c cross join
SELECT pc.name as category, s.organization_name as supplier
FROM warehouse.product_category pc
CROSS JOIN warehouse.supplier s;

SELECT w.adress, pc.name
FROM warehouse.warehouse w
CROSS JOIN warehouse.product_category pc;

--select c inner join из нескольких таблиц
SELECT co.id as order_id, c.last_name, pc.name as product, oi.quantity
FROM warehouse.customer_order co
INNER JOIN warehouse.customer c ON co.customer_id = c.id
INNER JOIN warehouse.order_item oi ON co.id = oi.order_id
INNER JOIN warehouse.product_catalog pc ON oi.product_id = pc.id;

SELECT pc.name as product, w.address, pi.stock_quantity
FROM warehouse.product_inventory pi
INNER JOIN warehouse.product_catalog pc ON pi.product_id = pc.id
INNER JOIN warehouse.warehouse w ON pi.warehouse_id = w.id;

SELECT DISTINCT w.address, pcategory.name
FROM warehouse.warehouse w 
LEFT JOIN warehouse.product_inventory pi ON w.id = pi.warehouse_id
INNER JOIN warehouse.product_catalog pcatalog ON pi.product_id = pcatalog.id
INNER JOIN warehouse.product_category pcategory ON pcatalog.category_id = pcategory.id