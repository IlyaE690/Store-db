
# Триггеры
## 1. ТРИГГЕРЫ С NEW
### 1.1 Автоматическое обновление общей стоимости заказа при добавлении позиции

CREATE OR REPLACE FUNCTION warehouse.update_order_total_on_insert()
RETURNS TRIGGER AS \$$
BEGIN
    UPDATE warehouse.payment
    SET amount = COALESCE(amount, 0) + 
        (SELECT unit_price FROM warehouse.product_catalog WHERE id = NEW.product_id) * NEW.quantity
    WHERE order_id = NEW.order_id;
    RETURN NEW;
END;
\$$ LANGUAGE plpgsql;

CREATE TRIGGER update_order_total_insert_trigger
AFTER INSERT ON warehouse.order_item
FOR EACH ROW
EXECUTE FUNCTION warehouse.update_order_total_on_insert();

#### использование
INSERT INTO warehouse.order_item(order_id, product_id, quantity)
VALUES (4, 1, 1000);
Цена до вставки новых данных 
![[Pasted image 20251202222435.png]]
Цена после вставки новых данных 
![[Pasted image 20251202222539.png]]


### 1.2 Проверка достаточности товара перед добавлением товара в заказ
CREATE OR REPLACE FUNCTION warehouse.check_stock_before_order()
RETURNS TRIGGER AS \$$
DECLARE
    available_stock INT;
BEGIN
    SELECT stock_quantity INTO available_stock
    FROM warehouse.product_inventory 
    WHERE product_id = NEW.product_id;
    
    IF available_stock < NEW.quantity THEN
        RAISE EXCEPTION 'Недостаточно товара на складе. Доступно: %, запрошено: %', 
            available_stock, NEW.quantity;
    END IF;
    RETURN NEW;
END;
\$$ LANGUAGE plpgsql;

CREATE TRIGGER check_stock_trigger
BEFORE INSERT ON warehouse.order_item
FOR EACH ROW
EXECUTE FUNCTION warehouse.check_stock_before_order();
#### использование

на первом складе всего 50_000 единиц продукта 2
![[Pasted image 20251202223440.png]]

INSERT INTO warehouse.order_item(order_id, product_id, quantity)
VALUES (1, 2, 100000); 

![[Pasted image 20251202223354.png]]


## 2. ТРИГГЕРЫ С OLD

### 2.1 Архивация удаленных клиентов

#### добавим таблицу для нового функционала

CREATE TABLE warehouse.customer_archive (
    id INT PRIMARY KEY,
    last_name VARCHAR(50),
    first_name VARCHAR(50),
    patronymic VARCHAR(50),
    email VARCHAR(100),
    archive_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION warehouse.archive_deleted_customer()
RETURNS TRIGGER AS \$$
BEGIN
    INSERT INTO warehouse.customer_archive (id, last_name, first_name, patronymic, email)
    VALUES (OLD.id, OLD.last_name, OLD.first_name, OLD.patronymic, OLD.email);
    RETURN OLD;
END;
\$$ LANGUAGE plpgsql;

CREATE TRIGGER archive_customer_trigger
BEFORE DELETE ON warehouse.customer
FOR EACH ROW
EXECUTE FUNCTION warehouse.archive_deleted_customer();

#### использование

delete from warehouse.customer where id = 27;

![[Pasted image 20251202224206.png]]![[Pasted image 20251202224216.png]]

SELECT * FROM warehouse.customer_archive
ORDER BY id ASC

![[Pasted image 20251202224253.png]]


### 2.2 Логирование изменений данных менеджера

#### добавим таблицу для нового функционала

CREATE TABLE warehouse.manager_change_log (
    manager_id INT PRIMARY KEY,
    old_last_name VARCHAR(50),
    new_last_name VARCHAR(50),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION warehouse.log_manager_changes()
RETURNS TRIGGER AS \$$
BEGIN
	INSERT INTO warehouse.manager_change_log (manager_id, old_last_name, old_first_name)
	VALUES (OLD.id, OLD.last_name, OLD.first_name);
    RETURN NEW;
END;
\$$ LANGUAGE plpgsql;

CREATE TRIGGER log_manager_changes_trigger
AFTER UPDATE ON warehouse.manager
FOR EACH ROW
EXECUTE FUNCTION warehouse.log_manager_changes();
#### использование

![[Pasted image 20251202225625.png]]
UPDATE warehouse.manager
SET last_name = 'Афанасьев' WHERE id = 4;
![[Pasted image 20251202225706.png]]
SELECT * FROM warehouse.manager_change_log;
![[Pasted image 20251202225823.png]]


## 3. ТРИГГЕРЫ BEFORE

### 3.1 Проверка возраста сотрудника перед добавлением

CREATE OR REPLACE FUNCTION warehouse.check_employee_age()
RETURNS TRIGGER AS \$$
BEGIN
    IF EXTRACT(YEAR FROM AGE(NEW.birth_date)) < 18 THEN
        RAISE EXCEPTION 'Сотрудник должен быть старше 18 лет';
    END IF;
    RETURN NEW;
END;
\$$ LANGUAGE plpgsql;

CREATE TRIGGER check_employee_age_trigger
BEFORE INSERT OR UPDATE ON warehouse.employee
FOR EACH ROW
EXECUTE FUNCTION warehouse.check_employee_age();

#### использование

INSERT INTO warehouse.employee(warehouse_id, last_name, first_name, patronymic, gender, birth_date)
VALUES (1, 'Сташков', 'Артём', 'Денисович', 'M', '2023-02-03');

![[Pasted image 20251202230454.png]]

### 3.2. Проверка цены товара перед добавлением

CREATE OR REPLACE FUNCTION warehouse.validate_product_price()
RETURNS TRIGGER AS \$$
BEGIN
    IF NEW.unit_price < 0 THEN
        RAISE EXCEPTION 'Цена товара не может быть отрицательной. Указано: %', NEW.unit_price;
    END IF;
    
    IF NEW.unit_price IS NULL THEN
        RAISE EXCEPTION 'Цена товара не может быть NULL';
    END IF;
    
    RETURN NEW;
END;
\$$ LANGUAGE plpgsql;


CREATE TRIGGER validate_product_price_trigger
BEFORE INSERT OR UPDATE ON warehouse.product_catalog
FOR EACH ROW
EXECUTE FUNCTION warehouse.validate_product_price();

#### использование

INSERT INTO warehouse.product_catalog (name, category_id, unit_price, unit_of_measure, supplier_id)
VALUES ('Тестовый товар', 1, -100, 'шт', 1);
![[Pasted image 20251202232340.png]]
INSERT INTO warehouse.product_catalog (name, category_id, unit_of_measure, supplier_id)
VALUES ('Тестовый товар', 1, 'шт', 1);
![[Pasted image 20251202232358.png]]

## ТРИГГЕРЫ AFTER

### 4.1 Обновление остатков после добавления в заказ

CREATE OR REPLACE FUNCTION warehouse.update_stock_after_sale()
RETURNS TRIGGER AS \$$
BEGIN
    UPDATE warehouse.product_inventory 
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE product_id = NEW.product_id;
    RETURN NEW;
END;
\$$ LANGUAGE plpgsql;

CREATE TRIGGER update_stock_after_sale_trigger
AFTER INSERT ON warehouse.order_item
FOR EACH ROW
EXECUTE FUNCTION warehouse.update_stock_after_sale();

#### использование

![[Pasted image 20251202234215.png]]
INSERT INTO warehouse.order_item(order_id, product_id, quantity) 
VALUES (2, 1, 1000);
![[Pasted image 20251202234247.png]]


### 4.2 Логирование добавления нового заказа

#### добавим таблицу для нового функционала
CREATE TABLE IF NOT EXISTS warehouse.order_log (
    log_id SERIAL PRIMARY KEY,
    order_id INT NOT NULL,
    customer_id INT NOT NULL,
    employee_id INT NOT NULL,
    created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    log_message TEXT
);

CREATE OR REPLACE FUNCTION warehouse.log_new_order()
RETURNS TRIGGER AS \$$
BEGIN
    DECLARE
        customer_name TEXT;
        employee_name TEXT;
    BEGIN

        SELECT CONCAT(last_name, ' ', first_name) INTO customer_name
        FROM warehouse.customer 
        WHERE id = NEW.customer_id;
        
        SELECT CONCAT(last_name, ' ', first_name) INTO employee_name
        FROM warehouse.employee 
        WHERE id = NEW.employee_id;
        
        INSERT INTO warehouse.order_log (order_id, customer_id, employee_id, log_message)
        VALUES (
            NEW.id,
            NEW.customer_id,
            NEW.employee_id,
            'Создан новый заказ №' || NEW.id || 
            ' от клиента: ' || customer_name || 
            ', оформлен сотрудником: ' || employee_name
        );
    END;
    
    RETURN NEW;
END;
\$$ LANGUAGE plpgsql;


CREATE TRIGGER log_new_order_trigger
AFTER INSERT ON warehouse.customer_order
FOR EACH ROW
EXECUTE FUNCTION warehouse.log_new_order();

#### использование
INSERT INTO warehouse.customer_order (customer_id, employee_id)
VALUES (1, 1);

SELECT * FROM warehouse.order_log;
![[Pasted image 20251202235747.png]]
## 5. ТРИГГЕРЫ Row Level

### 5.1 Контроль изменения статуса платежа

CREATE OR REPLACE FUNCTION warehouse.validate_payment_status_change()
RETURNS TRIGGER AS \$$
BEGIN
    IF OLD.status IS NOT NULL AND NEW.status != OLD.status THEN
        IF OLD.status = 2 AND NEW.status = 1 THEN
            RAISE EXCEPTION 'Нельзя изменить статус с "Оплачено" на "Ожидание"';
        END IF;
    END IF;
    RETURN NEW;
END;
\$$ LANGUAGE plpgsql;

CREATE TRIGGER validate_payment_status_trigger
BEFORE UPDATE ON warehouse.payment
FOR EACH ROW
EXECUTE FUNCTION warehouse.validate_payment_status_change();

#### использование


![[Pasted image 20251203000645.png]]
UPDATE warehouse.payment 
SET status = 1
WHERE order_id = 1;
![[Pasted image 20251203000504.png]]



### 5.2 добавление последней даты изменения цены
#### добавим в таблицу новый столбец для нового функционала

ALTER TABLE warehouse.product_catalog ADD COLUMN IF NOT EXISTS last_price_change TIMESTAMP;


CREATE OR REPLACE FUNCTION warehouse.update_price_modification_date()
RETURNS TRIGGER AS \$$
BEGIN
    IF NEW.unit_price != OLD.unit_price THEN
        NEW.last_price_change = CURRENT_TIMESTAMP;
    END IF;
    RETURN NEW;
END;
\$$ LANGUAGE plpgsql;


CREATE TRIGGER update_price_date_trigger
BEFORE UPDATE ON warehouse.product_catalog
FOR EACH ROW
EXECUTE FUNCTION warehouse.update_price_modification_date();
#### использование

UPDATE warehouse.product_catalog
SET unit_price = 5
WHERE id = 1;

![[Pasted image 20251203001348.png]]


## 6. ТРИГГЕРЫ Statement Level

### 6.1 Логирование  удалений
#### добавим таблицу для нового функционала

CREATE TABLE IF NOT EXISTS warehouse.log (
    id SERIAL PRIMARY KEY,
    table_name TEXT,
    operation_type TEXT,
    delete_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION warehouse.log_deletes()
RETURNS TRIGGER AS \$$
BEGIN
    INSERT INTO warehouse.log (table_name, operation_type)
    VALUES (TG_TABLE_NAME, TG_OP);
    RETURN NULL;
END;
\$$ LANGUAGE plpgsql;

CREATE TRIGGER log_batch_deletes_trigger
AFTER DELETE ON warehouse.order_item
FOR EACH STATEMENT
EXECUTE FUNCTION warehouse.log_deletes();

#### использование

![[Pasted image 20251203003429.png]]

DELETE FROM warehouse.order_item
WHERE order_id = 2 AND product_id = 2;

SELECT * FROM warehouse.batch_delete_log

![[Pasted image 20251203003701.png]]

### 6.2  Аудит массовых вставок


CREATE OR REPLACE FUNCTION warehouse.audit_batch_inserts()
RETURNS TRIGGER AS \$$
BEGIN
    RAISE NOTICE 'Выполнена массовая вставка в таблицу %', TG_TABLE_NAME;
    RETURN NULL;
END;
\$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_batch_inserts_trigger
AFTER INSERT ON warehouse.product_inventory
FOR EACH STATEMENT
EXECUTE FUNCTION warehouse.audit_batch_inserts();


#### использование

INSERT INTO warehouse.product_inventory(product_id, warehouse_id, stock_quantity)
VALUES (29, 1, 10000),
(29, 2, 10000),
(29, 3, 10000)

![[Pasted image 20251203010923.png]]


## ОТОБРАЖЕНИЕ СПИСКА ТРИГГЕРОВ

SELECT 
    trigger_schema as schema_name,
    trigger_name,
    event_object_table as table_name,
    event_manipulation as operation,
    action_timing as timing,
    action_statement as function
FROM information_schema.triggers
WHERE trigger_schema = 'warehouse'
ORDER BY table_name, trigger_name;

![[Pasted image 20251203012155.png]]


# КРОНЫ


### Ежемесячное удаление старых заказов
SELECT cron.schedule(
    'monthly-delete-old-orders',
    '0 0 1 \* *', -- каждый первый день месяца 
    \$\$
    
    DELETE FROM warehouse.customer_order 
    WHERE created_at < NOW() - INTERVAL '1 year';
    $$
);

### Крон для еженедельного отчета по остаткам
SELECT cron.schedule(
    'weekly-low-stock-report',
    '0 9 * * 1', -- каждый понедельник в 9
    \$$
    INSERT INTO warehouse.low_stock_alerts
    SELECT pi.product_id, pi.warehouse_id, pi.stock_quantity, pc.name
    FROM warehouse.product_inventory pi
    JOIN warehouse.product_catalog pc ON pi.product_id = pc.id
    WHERE pi.stock_quantity < 1000;
    \$$
);

### Крон для ежемесячной очистки логов
SELECT cron.schedule(
    'monthly-log-cleanup',
    '0 3 1 \* \*', -- первое число каждого месяца в 3:00
    \$$
    DELETE FROM warehouse.manager_change_log 
    WHERE change_date < NOW() - INTERVAL '6 months';
    \$$
);

### ЗАПРОС НА ПРОСМОТР ВЫПОЛНЕНИЯ КРОНОВ
SELECT 
    jobid,
    jobname,
    schedule,
    command,
    database,
    username,
    active
FROM cron.job;

### Просмотр логов выполнения cron
SELECT 
    jobid,
    runid,
    job_pid,
    database,
    username,
    command,
    status,
    return_message,
    start_time,
    end_time
FROM cron.job_run_details
ORDER BY start_time DESC
LIMIT 50;

### ЗАПРОС НА ПРОСМОТР КРОНОВ
SELECT 
    cron.jobid,
    cron.jobname,
    cron.schedule,
    cron.command,
    cron.nodename,
    cron.nodeport
FROM cron.job
WHERE active = true
ORDER BY jobname;
