## Процедуры

### Процедура 1: Добавление нового продукта в каталог

CREATE OR REPLACE PROCEDURE warehouse.add_product(
    p_name VARCHAR(100),
    p_category_id INT,
    p_unit_price INT,
    p_unit_of_measure VARCHAR(20),
    p_supplier_id INT
)
LANGUAGE plpgsql
AS 
\$$
BEGIN
    INSERT INTO warehouse.product_catalog (name, category_id, unit_price, unit_of_measure, supplier_id)
    VALUES (p_name, p_category_id, p_unit_price, p_unit_of_measure, p_supplier_id);
END;
\$$;
#### использование 
CALL warehouse.add_product(
    'Капуста белокочанная', 1, 3, 'г', 1
	);

![[Pasted image 20251125213946.png]]

### Процедура 2: Обновление количества товара на складе

CREATE OR REPLACE PROCEDURE warehouse.update_stock(
    p_product_id INT,
    p_warehouse_id INT,
    p_quantity INT
)
LANGUAGE plpgsql
AS \$$
BEGIN
    UPDATE warehouse.product_inventory 
    SET stock_quantity = p_quantity
    WHERE product_id = p_product_id AND warehouse_id = p_warehouse_id;
    
    IF NOT FOUND THEN
        INSERT INTO warehouse.product_inventory (product_id, warehouse_id, stock_quantity)
        VALUES (p_product_id, p_warehouse_id, p_quantity);
    END IF;
END;
\$$;

#### использование 

CALL warehouse.update_stock(
    5, 1, 15000    
);

![[Pasted image 20251125214526.png]]

### Процедура 3: Добавление нового заказчика

CREATE OR REPLACE PROCEDURE warehouse.add_customer(
    p_last_name VARCHAR(50),
    p_first_name VARCHAR(50),
    p_patronymic VARCHAR(50) DEFAULT NULL,
    p_email VARCHAR(100) DEFAULT NULL
)
AS \$$
BEGIN
    INSERT INTO warehouse.customer 
    (last_name, first_name, patronymic, email)
    VALUES (p_last_name, p_first_name, p_patronymic, p_email);
END;
\$$ LANGUAGE plpgsql;

#### использование

CALL warehouse.add_customer(
    'Сидоров',          
    'Дмитрий',            
    'Викторович',       
    'sidorov\@market.ru' 
);

![[Pasted image 20251125214832.png]]
####  Просмотр  всех процедур

SELECT proname as procedure_name
FROM pg_proc
WHERE pronamespace = 'warehouse'::regnamespace 
AND prokind = 'p';

![[Pasted image 20251125192910.png]]


## Функции

### Функция 1: Расчет общей стоимости заказа

CREATE OR REPLACE FUNCTION warehouse.get_order_total(p_order_id INT)
RETURNS INT
LANGUAGE plpgsql
AS \$$
BEGIN
    RETURN (
        SELECT SUM(oi.quantity * pc.unit_price)
        FROM warehouse.order_item oi
        JOIN warehouse.product_catalog pc ON oi.product_id = pc.id
        WHERE oi.order_id = p_order_id
    );
END;
\$$;

#### использование

SELECT warehouse.get_order_total(1);

![[Pasted image 20251125221009.png]]
![[Pasted image 20251125221034.png]]
![[Pasted image 20251125221320.png]]
### Функция 2: получение информации о заказчике

CREATE OR REPLACE FUNCTION warehouse.get_customer_info(p_customer_id INT)
RETURNS TEXT
LANGUAGE plpgsql
AS \$$
BEGIN
    RETURN (
        SELECT 'Клиент: ' || c.last_name || ' ' || c.first_name || ' ' || c.patronymic ||
               ', Email: ' || COALESCE(c.email, 'нет') || 
               ', Заказов: ' || COUNT(co.id)::TEXT
        FROM warehouse.customer c
        LEFT JOIN warehouse.customer_order co ON c.id = co.customer_id
        WHERE c.id = p_customer_id
        GROUP BY c.id, c.last_name, c.first_name, c.email
    );
END;
\$$;

#### использование

SELECT warehouse.get_customer_info(1);

![[Pasted image 20251125222124.png]]

### Функция 3: Проверка доступности товара

CREATE OR REPLACE FUNCTION warehouse.check_availability(p_product_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS \$$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM warehouse.product_inventory 
        WHERE product_id = p_product_id AND stock_quantity > 0
    );
END;
\$$;
#### использование

SELECT warehouse.check_availability(1);

![[Pasted image 20251125222543.png]]
## Функции с переменными

### Функция 1: подсчёт товаров на складе 

CREATE OR REPLACE FUNCTION warehouse.count_products_in_warehouse(p_warehouse_id INT)
RETURNS INT
LANGUAGE plpgsql
AS \$$
DECLARE
    product_count INT;
BEGIN
    SELECT COUNT(\*) INTO product_count
    FROM warehouse.product_inventory
    WHERE warehouse_id = p_warehouse_id;
    
    RETURN product_count;
END;
\$$;

#### использование

SELECT warehouse.count_products_in_warehouse(1);

![[Pasted image 20251125222913.png]]


### Функция 2:  получение цены товара

CREATE OR REPLACE FUNCTION warehouse.get_product_price(p_product_id INT)
RETURNS INT
LANGUAGE plpgsql
AS \$$
DECLARE
    product_price INT;
    product_name VARCHAR(100);
BEGIN
    SELECT unit_price, name INTO product_price, product_name
    FROM warehouse.product_catalog
    WHERE id = p_product_id;
    
    RETURN product_price;
END;
\$$;
#### использование

SELECT warehouse.get_product_price(1);

![[Pasted image 20251125223352.png]]

### Функция 3:  проверка клиента

CREATE OR REPLACE FUNCTION warehouse.check_customer_exists(p_customer_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS \$$
DECLARE
    customer_exists BOOLEAN;
    customer_last_name VARCHAR(50);
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM warehouse.customer WHERE id = p_customer_id
    ) INTO customer_exists;
    
    SELECT last_name INTO customer_last_name
    FROM warehouse.customer
    WHERE id = p_customer_id;
    
    RETURN customer_exists;
END;
\$$;

#### использование

SELECT warehouse.check_customer_exists(1);

![[Pasted image 20251125223850.png]]

### Запрос для просмотра всех функций

SELECT proname as function_name
FROM pg_proc
WHERE pronamespace = 'warehouse'::regnamespace 
AND prokind = 'f';

![[Pasted image 20251125223948.png]]

## DO
### 1 увеличение цены на 10%

DO \$$
BEGIN
    UPDATE warehouse.product_catalog 
    SET unit_price = unit_price + CEIL(unit_price * 0.1) 
    WHERE category_id = (SELECT id FROM warehouse.product_category WHERE name = 'Овощи');
    
END \$$;

![[Pasted image 20251125225233.png]]
![[Pasted image 20251125225253.png]]

### 2 Нахождение товаров с малым остатком

DO \$$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM warehouse.product_inventory 
        WHERE stock_quantity < 1000
    ) THEN
        RAISE NOTICE 'ВНИМАНИЕ: Есть товары с остатком менее 1000 единиц';
        RAISE NOTICE 'Товары с низким остатком: %', (
            SELECT STRING_AGG(pc.name, ', ')
            FROM warehouse.product_inventory pi
            JOIN warehouse.product_catalog pc ON pi.product_id = pc.id
            WHERE pi.stock_quantity < 1000
        );
    ELSE
        RAISE NOTICE 'Все товары в достаточном количестве';
    END IF;
END \$$;

![[Pasted image 20251125225536.png]]
### 3

DO \$$
BEGIN
    INSERT INTO warehouse.product_inventory (product_id, warehouse_id, stock_quantity)
    SELECT id, 1, 100 
    FROM warehouse.product_catalog 
    WHERE category_id = (SELECT id FROM warehouse.product_category WHERE name = 'Фрукты')
    ON CONFLICT (product_id, warehouse_id) DO UPDATE 
    SET stock_quantity = EXCLUDED.stock_quantity;
    
    RAISE NOTICE 'Добавлено 100 единиц всех фруктов на склад 1';
END \$$;

![[Pasted image 20251125225753.png]]


### IF 
#### проверка можно ли создать заказ

CREATE OR REPLACE FUNCTION warehouse.validate_order(p_customer_id INT, p_product_id INT)
RETURNS TEXT
LANGUAGE plpgsql
AS \$$
DECLARE
    customer_exists BOOLEAN;
    product_exists BOOLEAN;
BEGIN
	SELECT EXISTS(SELECT 1 FROM warehouse.customer WHERE id = p_customer_id) 
    INTO customer_exists;
    SELECT EXISTS(SELECT 1 FROM warehouse.product_catalog WHERE id = p_product_id) 
    INTO product_exists;
    
    IF NOT customer_exists THEN
        RETURN 'Ошибка: Клиент не найден';
    END IF;
    
    IF NOT product_exists THEN
        RETURN 'Ошибка: Товар не найден';
    END IF;
END;
\$$;

#### использование

SELECT warehouse.validate_order(1, 1);

![[Pasted image 20251126000543.png]]


### CASE  

#### оценка покупателя по количеству заказов

CREATE OR REPLACE FUNCTION warehouse.rate_customer(p_customer_id INT)
RETURNS TEXT
LANGUAGE plpgsql
AS \$$
DECLARE
    order_count INT;
    customer_rating TEXT;
BEGIN
    SELECT COUNT(\*) INTO order_count
    FROM warehouse.customer_order
    WHERE customer_id = p_customer_id;
    
    customer_rating := 
        CASE 
            WHEN order_count = 0 THEN 'Новый'
            WHEN order_count BETWEEN 1 AND 5 THEN 'Обычный'
            WHEN order_count BETWEEN 6 AND 15 THEN 'Постоянный'
            ELSE 'VIP'
        END;
    
    RETURN customer_rating;
END;
\$$;
#### использование

SELECT warehouse.rate_customer(1);

![[Pasted image 20251125231407.png]]


### WHILE
### 1

#### вычисление факториала 

CREATE OR REPLACE FUNCTION warehouse.calculate_factorial(n INTEGER)
RETURNS BIGINT 
LANGUAGE plpgsql
AS \$$
DECLARE
    result BIGINT := 1;
    counter INTEGER := 1;
BEGIN
    IF n < 0 THEN
        RETURN NULL;
    END IF;
    
    WHILE counter <= n LOOP
        result := result * counter;
        counter := counter + 1;
    END LOOP;
    
    RETURN result;
END;
\$$;

#### использование

SELECT warehouse.calculate_factorial(5);
![[Pasted image 20251125233114.png]]

### 2

#### Добавление тестовых заказов 

CREATE OR REPLACE PROCEDURE warehouse.create_test_orders(p_count INT)
LANGUAGE plpgsql
AS \$$
DECLARE
    i INT := 1;
    customer_id INT;
    employee_id INT;
BEGIN
    SELECT id INTO customer_id FROM warehouse.customer LIMIT 1;
    SELECT id INTO employee_id FROM warehouse.employee LIMIT 1;
    
    WHILE i <= p_count LOOP
        INSERT INTO warehouse.customer_order (customer_id, employee_id)
        VALUES (customer_id, employee_id);
        
        i := i + 1;
    END LOOP;
END;
\$$;

#### использование

![[Pasted image 20251126001508.png]]
CALL warehouse.create_test_orders(2);
![[Pasted image 20251126001531.png]]

### EXCEPTION

### 1

#### безопасное удаление покупателя 

CREATE OR REPLACE FUNCTION warehouse.delete_customer(p_customer_id INT)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS \$$
BEGIN
    DELETE FROM warehouse.customer WHERE id = p_customer_id;
    
    RETURN TRUE;
    
EXCEPTION
    WHEN others THEN
        RETURN FALSE;
END;
\$$;

#### использование

SELECT warehouse.delete_customer(26);

![[Pasted image 20251125234536.png]]

### 2

#### безопасное изменение цены

CREATE OR REPLACE PROCEDURE warehouse.change_price(p_product_id INT, p_new_price INT)
LANGUAGE plpgsql
AS \$$
BEGIN
    IF p_new_price <= 0 THEN
        RAISE EXCEPTION 'Цена должна быть больше 0';
    END IF;
    
    UPDATE warehouse.product_catalog 
    SET unit_price = p_new_price 
    WHERE id = p_product_id;
    
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'Не удалось обновить цену';
END;
\$$;
#### использование

call warehouse.change_price(1, 4);


![[Pasted image 20251125234811.png]]
![[Pasted image 20251125235001.png]]


### RAISE

### 1

CREATE OR REPLACE FUNCTION warehouse.check_warehouse(p_warehouse_id INT)
RETURNS TEXT
LANGUAGE plpgsql
AS \$$
DECLARE
    wh_count INT;
BEGIN
    SELECT COUNT(*) INTO wh_count
    FROM warehouse.warehouse
    WHERE id = p_warehouse_id;
    
    IF wh_count = 0 THEN
        RAISE EXCEPTION 'Склад не найден';
    END IF;
    
    RAISE NOTICE 'Склад ID % существует', p_warehouse_id;
    RETURN 'OK';
END;
\$$;

#### использование

SELECT warehouse.check_warehouse(5);
![[Pasted image 20251125235327.png]]

SELECT warehouse.check_warehouse(1);
![[Pasted image 20251125235411.png]]

### 2

CREATE OR REPLACE FUNCTION warehouse.validate_email(p_email VARCHAR(100))
RETURNS BOOLEAN
LANGUAGE plpgsql
AS \$$
BEGIN
    IF p_email IS NULL THEN
		RAISE EXCEPTION 'Некорректный email';
        
    END IF;
    
    IF p_email LIKE '%@%' THEN
        RETURN TRUE;
	ELSE 
	RETURN FALSE;
    END IF;
    
    RAISE NOTICE 'Email прошел проверку';
END;
\$$;
#### использование

SELECT warehouse.validate_email(NULL);
![[Pasted image 20251126000756.png]]
SELECT warehouse.validate_email('12412@gmail..com');
![[Pasted image 20251126000853.png]]
![[Pasted image 20251126000955.png]]