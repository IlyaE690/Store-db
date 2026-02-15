### **Базовые операции с транзакциями**
#### **с использованием COMMIT
BEGIN;
-- добавление новой записи в таблицу 
INSERT INTO warehouse.product_catalog (name, category_id, unit_price, unit_of_measure, supplier_id)
VALUES ('Экспресс-кофе', 6, 1300, 'шт.', 6);

-- обновление связанной информации в другой таблице
INSERT INTO warehouse.product_inventory (product_id, warehouse_id, stock_quantity)
VALUES (currval('warehouse.product_catalog_id_seq'), 1, 100);

COMMIT;
![[1-1.png]]
![[1-2.png]]


BEGIN;
-- добавление новой записи в таблицу 
INSERT INTO warehouse.manager (last_name, first_name, patronymic, gender, birth_date)
VALUES ('Леонтьев', 'Вячеслав', 'Дмитриевич', 'M', '1963-10-10');

-- обновление связанной информации в другой таблице
INSERT INTO warehouse.warehouse (address, manager_id)
VALUES ('г. Новосибирск, ул. Бориса Богаткова, д. 266/1', currval('warehouse.manager_id_seq'));

COMMIT;
![[2-1.png]]
![[2-2.png]]

#### **с использованием ROLLBACK
BEGIN;
-- добавление новой записи в таблицу 
INSERT INTO warehouse.product_catalog (name, category_id, unit_price, unit_of_measure, supplier_id)
VALUES ('Экспресс-коф', 6, 1300, 'шт.', 6);

-- обновление связанной информации в другой таблице
INSERT INTO warehouse.product_inventory (product_id, warehouse_id, stock_quantity)
VALUES (currval('warehouse.product_catalog_id_seq'), 1, 100);
-- откат изменений
ROLLBACK;

![[1-1.png]]![[1-2.png]]
--**Мы произвели ROLLBACK, поэтому внесённые изменения не сохранились


BEGIN;
-- добавление новой записи в таблицу 
INSERT INTO warehouse.manager (last_name, first_name, patronymic, gender, birth_date)
VALUES ('Л','Вячеслав', 'Дмитриевич', 'M', '1563-10-10');

-- обновление связанной информации в другой таблице
INSERT INTO warehouse.warehouse (address, manager_id)
VALUES ('Новосибирск, ул. Бориса Богаткова, д. 266/1', currval('warehouse.manager_id_seq'));

ROLLBACK;
![[2-1.png]]
![[2-2.png]]
--**Мы произвели ROLLBACK, поэтому внесённые изменения не сохранились

#### -- Транзакция с ошибкой
BEGIN;

INSERT INTO warehouse.product_catalog (name, category_id, unit_price, unit_of_measure, supplier_id)
VALUES ('Черный чай', 2, 350, 'шт.', 2);

INSERT INTO warehouse.product_inventory (product_id, warehouse_id, stock_quantity)
VALUES (currval('warehouse.product_catalog_id_seq'), 1, 75);
	
-- ошибка
SELECT 1 / 0;

COMMIT;
![[5-1.png]]
![[1-1.png]]
![[1-2.png]]

**Мы проводили всё в одной транзакции, но из-за получения ошибки, изменения внесённые в этой транзакции не были сохранены

-- 6 запрос
BEGIN;
-- добавление новой записи, которая противоречит check на столбце gender
INSERT INTO warehouse.manager (last_name, first_name, patronymic, gender, birth_date)
VALUES ('Леонть', 'Вячеслав', 'Дмитриевич', 'R', '1950-10-10');

-- обновление связанной информации в другой таблице
INSERT INTO warehouse.warehouse (address, manager_id)
VALUES (' Новосибирск, ул. Бориса Богаткова, д. 266/1', currval('warehouse.manager_id_seq'));

COMMIT;
![[2-1.png]]
![[2-2.png]]
![[6-1.png]]
## **Уровни изоляции**
#### **READ UNCOMMITTED / READ COMMITTED:**
-- 7 запрос
BEGIN;
UPDATE warehouse.product_catalog SET unit_price = 999 WHERE id = 1;

-- попытка прочитать незакоммиченные данные
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM warehouse.product_catalog WHERE id = 1;
COMMIT;
-- отмена изменений первой транзакции
ROLLBACK;
![[7-1.png]]
**postgreSQL запрещает читать незакомиченные данные

-- 8 запрос
BEGIN;
UPDATE warehouse.customer SET email = 'test@gmail.com' WHERE id = 1;

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM warehouse.customer WHERE id = 1;
COMMIT;

-- отмена изменений первой транзакции
ROLLBACK;
![[8-1.png]]
**на данном уровне нельзя читать незакомиченные данные

#### **READ COMMITTED:**
## неповторяющееся чтение
--9 запрос

BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM warehouse.product_inventory WHERE product_id = 1 AND warehouse_id = 1;

BEGIN;
UPDATE warehouse.product_inventory SET stock_quantity = stock_quantity + 100
WHERE product_id = 1 AND warehouse_id = 1;
COMMIT;

SELECT * FROM warehouse.product_inventory WHERE product_id = 1 AND warehouse_id = 1;

COMMIT;
![[9-1.png]]
![[9-2.png]]

-- 10 запрос 
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- Чтение цены продукта в Т1
SELECT 'Цена до изменения:' as info, name, unit_price 
FROM warehouse.product_catalog 
WHERE id = 1;

-- вызов Т2
BEGIN;
UPDATE warehouse.product_catalog 
SET unit_price = unit_price + 100 
WHERE id = 1;
COMMIT;

-- Чтение после изменений T2
SELECT 'Цена после изменения:' as info, name, unit_price 
FROM warehouse.product_catalog 
WHERE id = 1;

COMMIT;
![[10-1.png]]
![[10-2.png]]
**на уровне READ COMMITTED возможно неповторяющееся чтение**
#### **REPEATABLE READ**

--11 запрос
--вызов Т1
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT 'Количество до изменения:' as info, stock_quantity FROM warehouse.product_inventory
WHERE product_id = 1 AND warehouse_id = 1;

--вызов Т2
BEGIN;
UPDATE warehouse.product_inventory 
SET stock_quantity = stock_quantity + 30 
WHERE product_id = 1 AND warehouse_id = 1;
COMMIT;

-- Чтение после изменений T2
SELECT 'Количество после изменения:' as info, stock_quantity FROM warehouse.product_inventory WHERE product_id = 1 AND warehouse_id = 1;

COMMIT;

![[11-1.png]]
![[11-2.png]]
**на уровне REPEATABLE READ** невозможно неповторяющееся чтение

--12 запрос
--вызов Т1
-- REPEATABLE READ: Фантомное чтение через INSERT
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT 'Количество до изменения:' as info, COUNT(*) 
FROM warehouse.customer WHERE email LIKE '%@gmail.com';

--вызов Т2
BEGIN;
INSERT INTO warehouse.customer (last_name, first_name, patronymic, email) 
VALUES ('Иванов', 'Иван' 'Иванович', 'ivanov@gmail.com');
COMMIT;

--чтение после изменений Т2
SELECT 'Количество после изменения:' as info, COUNT(\*)
FROM warehouse.customer WHERE email LIKE '%@gmail.com';
COMMIT;
![[12-1.png]]
![[12-2.png]]
**Фантомное чтение невозможно на в postgreSQL**

#### **SERIALIZABLE:**

--13 запрос 
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- T1 читает и модифицирует данные
SELECT stock_quantity 
FROM warehouse.product_inventory 
WHERE product_id = 3 AND warehouse_id = 1;

UPDATE warehouse.product_inventory 
SET stock_quantity = stock_quantity - 500 
WHERE product_id = 3 AND warehouse_id = 1;


BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- T2 читает те же данные
SELECT 'результат первой транзакции' as info, stock_quantity
FROM warehouse.product_inventory 
WHERE product_id = 3 AND warehouse_id = 1;

UPDATE warehouse.product_inventory 
SET stock_quantity = stock_quantity - 300 
WHERE product_id = 3 AND warehouse_id = 1;

COMMIT;

COMMIT;
![[13-1.png]]
![[13-2.png]]
![[13-3.png]]

 **обе транзакции имеют доступ только к закомиченным данным или к измменённым самой транзакцией, однако при попытке изменить данные *"захваченные"* другой транзакцией выдаётся ошибка**
 
--14 запрос
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- T1 модифицирует данные
UPDATE warehouse.customer 
SET patronymic = 'Петрович'
WHERE id = 12;


BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;

--Т2 модифицирует те же данные
UPDATE warehouse.customer 
SET patronymic = 'Петрович'
WHERE id = 12;

COMMIT;

COMMIT;
![[14-1.png]]
![[14-2.png]]

**Также стоит отметить, что при вызове sql запроса по частям (сначала update а потом commit), выясняется, что транзакции блокируют ресурс, который они изменяют (его можно прочитать без учёта изменений, но нельзя поменять), из-за этого вторая транзакция встала в состояние блокировки до момента, когда завершится первая транзакция. После завершения первой транзакции получили ошибку

--15 запрос 
## SAVEPOINT

BEGIN;

INSERT INTO warehouse.customer (last_name, first_name, email)
VALUES ('Петров', 'Петр', 'petrov@mail.com');

SAVEPOINT sp1;

UPDATE warehouse.customer SET email = 'new_email@mail.com' WHERE id = 1;

SELECT * FROM warehouse.customer WHERE last_name = 'Петров'; -- есть
SELECT * FROM warehouse.customer WHERE id = 1; -- изменен

-- отменяем апдейт
ROLLBACK TO SAVEPOINT sp1;

SELECT * FROM warehouse.customer WHERE last_name = 'Петров'; -- есть
SELECT * FROM warehouse.customer WHERE id = 1; -- старый email

COMMIT;
![[15-1.png]]
![[15-2.png]]
![[15-3.png]]
![[15-4.png]]


--16 запрос
BEGIN;

INSERT INTO warehouse.customer (last_name, first_name, email)
VALUES ('Петров', 'Иван', 'petrov1@mail.com');
SELECT * FROM warehouse.customer where last_name = 'Петров';

SAVEPOINT sp1;
 
UPDATE warehouse.customer SET last_name = 'Иванов' WHERE id = 2;
SELECT * FROM warehouse.customer WHERE id = 2;

SAVEPOINT sp2;


DELETE FROM warehouse.customer WHERE id = 12;
--проверяем что удалили
SELECT * FROM warehouse.customer;
-- откат ко sp 2, отменили делет
ROLLBACK TO SAVEPOINT sp2;
SELECT * FROM warehouse.customer WHERE id = 12;
-- откат к sp 1, отменили делет и апдейт
ROLLBACK TO SAVEPOINT sp1;
SELECT * FROM warehouse.customer  WHERE id = 2;

COMMIT;

ROLLBACK;
![[16-1.png]]
![[16-2.png]]
![[16-3.png]]
![[16-4.png]]![[16-5.png]]

**SAVEPOIN позволяет вернуться к любому моменту выполнения запроса и восстановить данные 