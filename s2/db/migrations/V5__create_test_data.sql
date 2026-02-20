WITH 
first_names AS (
    SELECT unnest(ARRAY[
        'Александр', 'Дмитрий', 'Максим', 'Сергей', 'Андрей', 'Алексей', 'Иван', 'Евгений',
        'Михаил', 'Артем', 'Владимир', 'Роман', 'Николай', 'Денис', 'Павел', 'Кирилл'
    ]) as name
),
last_names AS (
    SELECT unnest(ARRAY[
        'Иванов', 'Петров', 'Сидоров', 'Смирнов', 'Кузнецов', 'Попов', 'Васильев',
        'Михайлов', 'Федоров', 'Морозов', 'Волков', 'Алексеев', 'Лебедев', 'Семенов',
        'Егоров', 'Павлов', 'Козлов', 'Степанов', 'Николаев', 'Орлов'
    ]) as name
),
patronymics AS (
    SELECT unnest(ARRAY[
        'Александрович', 'Дмитриевич', 'Максимович', 'Сергеевич', 'Андреевич',
        'Алексеевич', 'Иванович', 'Евгеньевич', 'Михайлович', 'Артемович',
        'Владимирович', 'Романович', 'Николаевич', 'Денисович', 'Павлович'
    ]) as name
)
INSERT INTO customer (
    id,
    last_name, 
    first_name, 
    patronymic, 
    email, 
    loyalty_level, 
    preferences, 
    device_fingerprint
)
SELECT
    gs,
    -- низкая кардинальность
    (SELECT name FROM last_names ORDER BY random() LIMIT 1),
    
    
    (SELECT name FROM first_names ORDER BY random() LIMIT 1),
    
    -- 20% NULL
    CASE WHEN random() < 0.2 THEN NULL
         ELSE (SELECT name FROM patronymics ORDER BY random() LIMIT 1)
    END,
    
    -- высокая кардинальность, но с паттерном
    lower(
        (SELECT name FROM first_names ORDER BY random() LIMIT 1) || '.' ||
        (SELECT name FROM last_names ORDER BY random() LIMIT 1) || 
        CASE (random()*3)::int
            WHEN 0 THEN '@gmail.com'
            WHEN 1 THEN '@yandex.ru'
            WHEN 2 THEN '@mail.ru'
            ELSE '@bk.ru'
        END
    ),
    
    -- низкая кардинальность
    CASE 
        WHEN random() < 0.4 THEN 'Bronze'     -- 40%
        WHEN random() < 0.7 THEN 'Silver'     -- 30%
        WHEN random() < 0.9 THEN 'Gold'       -- 20%
        ELSE 'Platinum'                        -- 10%
    END,
    
    -- JSON с предпочтениями 
    jsonb_build_object(
        'notifications', CASE WHEN random() < 0.7 THEN 'email' ELSE 'sms' END,
        'language', CASE 
            WHEN random() < 0.8 THEN 'ru'
            WHEN random() < 0.95 THEN 'en'
            ELSE 'kk'
        END,
        'theme', CASE 
            WHEN random() < 0.6 THEN 'light'
            WHEN random() < 0.9 THEN 'dark'
            ELSE 'system'
        END,
        'newsletter', random() < 0.3,
        'favorite_categories', (
            SELECT array_agg(cat) FROM (
                SELECT unnest(ARRAY['electronics', 'clothing', 'books', 'home', 'sports'])
                WHERE random() < 0.3
            ) t(cat)
        )
    ),
    
    -- Device fingerprint: высокая кардинальность 
    CASE WHEN random() < 0.15 THEN NULL
         ELSE 'fp_' || encode(sha256((gs || random()::text)::bytea), 'hex')
    END
    
FROM generate_series(1, 260000) gs;









WITH 
categories AS (
    SELECT unnest(ARRAY[
        'Электроника', 'Одежда', 'Книги', 'Дом', 'Спорт', 'Красота', 'Авто',
        'Детям', 'Зоотовары', 'Продукты', 'Мебель', 'Инструменты', 'Канцелярия'
    ]) as name
),
units AS (
    SELECT unnest(ARRAY['шт', 'кг', 'л', 'м', 'уп', 'пара', 'компл']) as unit
),
suppliers AS (
    SELECT unnest(ARRAY[
        'ООО Поставщик', 'АО Торговый дом', 'ИП Петров', 'ТД Альянс',
        'Глобал Импорт', 'Локал Маркет', 'Дистрибьютор Плюс'
    ]) as name
)
INSERT INTO product_catalog (
    id,
    name, 
    category_id, 
    unit_price, 
    unit_of_measure, 
    supplier_id, 
    last_price_change, 
    attributes, 
    tags, 
    price_history, 
    full_text_search
)
SELECT
    gs,
    CASE (random()*10)::int
        WHEN 0 THEN 'Смартфон '
        WHEN 1 THEN 'Ноутбук '
        WHEN 2 THEN 'Футболка '
        WHEN 3 THEN 'Джинсы '
        WHEN 4 THEN 'Книга '
        WHEN 5 THEN 'Наушники '
        WHEN 6 THEN 'Кружка '
        WHEN 7 THEN 'Мяч '
        WHEN 8 THEN 'Часы '
        ELSE 'Товар '
    END || gs || ' ' || 
    CASE (random()*5)::int
        WHEN 0 THEN 'Pro'
        WHEN 1 THEN 'Lite'
        WHEN 2 THEN 'Max'
        WHEN 3 THEN 'Mini'
        ELSE ''
    END,
    
    -- category_id: сильно неравномерное zipf
    CASE 
        WHEN random() < 0.4 THEN 1      
        WHEN random() < 0.6 THEN 2      
        WHEN random() < 0.7 THEN 3      
        WHEN random() < 0.8 THEN 4      
        ELSE (random()*8)::int + 5     
    END,
    
    (CASE 
        WHEN random() < 0.4 THEN 100 + (random()*900)::int           
        WHEN random() < 0.7 THEN 1000 + (random()*4000)::int         
        WHEN random() < 0.9 THEN 5000 + (random()*20000)::int        
        ELSE 25000 + (random()*75000)::int                           
    END)::integer,
    
    -- единица измерения
    (SELECT unit FROM units ORDER BY random() LIMIT 1),
    
    -- supplier_id: неравномерное
    CASE 
        WHEN random() < 0.35 THEN 1
        WHEN random() < 0.55 THEN 2
        WHEN random() < 0.7 THEN 3
        WHEN random() < 0.8 THEN 4
        ELSE (random()*3)::int + 4
    END,
    
    -- дата изменения: 30% NULL
    CASE WHEN random() < 0.3 THEN NULL
         ELSE current_timestamp - (random()*365)::int * interval '1 day'
    END,
    
    -- атрибуты: комбинация огр. знач.
    jsonb_build_object(
        'brand', CASE (random()*8)::int
            WHEN 0 THEN 'Samsung'
            WHEN 1 THEN 'Apple'
            WHEN 2 THEN 'Xiaomi'
            WHEN 3 THEN 'Sony'
            WHEN 4 THEN 'LG'
            WHEN 5 THEN 'Adidas'
            WHEN 6 THEN 'Nike'
            WHEN 7 THEN 'Puma'
            ELSE 'NoName'
        END,
        'color', CASE (random()*6)::int
            WHEN 0 THEN 'черный'
            WHEN 1 THEN 'белый'
            WHEN 2 THEN 'красный'
            WHEN 3 THEN 'синий'
            WHEN 4 THEN 'зеленый'
            WHEN 5 THEN 'желтый'
            ELSE 'серый'
        END,
        'weight_kg', CASE WHEN random() < 0.5 THEN (random()*10)::numeric(5,2) ELSE NULL END,
        'in_stock', random() < 0.7,
        'rating', (random()*5)::numeric(3,1)
    ),
    
    -- теги: комбинации тегов
    ARRAY(
        SELECT tag FROM (
            SELECT unnest(ARRAY['новинка', 'хит', 'акция', 'премиум', 'распродажа']) as tag
            WHERE random() < 0.2
        ) t
    ),
    
    -- история цен
    daterange(
    current_date - (random()*180)::int,     
    current_date - (random()*10)::int + 10,     
    '[]'
    ),
    
    -- полнотекстовый поиск
    to_tsvector('russian', 
        COALESCE((SELECT name FROM categories ORDER BY random() LIMIT 1), '') || ' ' ||
        'товар описание ' || gs
    )
    
FROM generate_series(1, 260000) gs;







INSERT INTO customer_order (
    id,
    customer_id, 
    employee_id, 
    delivery_time_range, 
    order_metadata, 
    delivery_coordinates
)
SELECT
    gs,
    -- сustomer_id: 70% заказов от 30% покупателей
    CASE 
        WHEN random() < 0.7 THEN (random()*75000)::int + 1
        ELSE (random()*175000)::int + 75001
    END,
    
    -- employee_id: 
    (random()*29)::int + 1,
    
    -- диапазон доставки
    tstzrange(
        current_timestamp + (random()*7)::int * interval '1 day',
        current_timestamp + (random()*7 + 8)::int * interval '1 day',
        '[)'
    ),
    
    -- метаданные заказа
    jsonb_build_object(
        'source', CASE (random()*3)::int
            WHEN 0 THEN 'web' WHEN 1 THEN 'mobile' WHEN 2 THEN 'api' ELSE 'store'
        END,
        'payment', CASE (random()*3)::int
            WHEN 0 THEN 'card' WHEN 1 THEN 'cash' WHEN 2 THEN 'online' ELSE 'credit'
        END,
        'delivery_type', CASE (random()*2)::int
            WHEN 0 THEN 'courier' WHEN 1 THEN 'pickup' ELSE 'post'
        END,
        'total_items', (random()*15)::int + 1,
        'discount', CASE WHEN random() < 0.2 THEN (random()*30)::int ELSE 0 END
    ),
    
    CASE (random()*4)::int
        WHEN 0 THEN point(55.75 + (random()-0.5)*0.2, 37.62 + (random()-0.5)*0.2)     -- Москва
        WHEN 1 THEN point(59.93 + (random()-0.5)*0.2, 30.36 + (random()-0.5)*0.2)     -- СПб
        WHEN 2 THEN point(54.98 + (random()-0.5)*0.3, 82.89 + (random()-0.5)*0.3)    -- Новосибирск
        WHEN 3 THEN point(55.16 + (random()-0.5)*0.3, 61.40 + (random()-0.5)*0.3)    -- Челябинск
        ELSE point(43.11 + (random()-0.5)*0.5, 131.88 + (random()-0.5)*0.5)          -- Владивосток
    END
    
FROM generate_series(1, 260000) gs;







INSERT INTO order_item (
    order_id, 
    product_id, 
    quantity, 
    special_requests, 
    item_options, 
    return_window
)
SELECT
    -- оrder_id: с перекосом
    CASE 
        WHEN random() < 0.7 THEN (random()*175000)::int + 1
        ELSE (random()*75000)::int + 175001
    END,
    
    -- product_id: Zipf-распределение
    CASE 
        WHEN random() < 0.3 THEN (random()*100)::int + 1          -- топ-100 товаров
        WHEN random() < 0.5 THEN (random()*1000)::int + 101       -- следующие 1000
        WHEN random() < 0.7 THEN (random()*5000)::int + 1101      -- следующие 5000
        ELSE (random()*243800)::int + 6101                        -- все остальные
    END,
    
    -- количество: в основном 1-2 шт
    (CASE 
        WHEN random() < 0.6 THEN 1
        WHEN random() < 0.85 THEN 2
        WHEN random() < 0.95 THEN (random()*3)::int + 3
        ELSE (random()*8)::int + 6
    END)::integer,
    
    -- особые пожелания
    CASE WHEN random() < 0.2 THEN 
        CASE (random()*4)::int
            WHEN 0 THEN 'Подарочная упаковка'
            WHEN 1 THEN 'Без контакта'
            WHEN 2 THEN 'Позвонить за час'
            WHEN 3 THEN 'Оставить у двери'
            ELSE 'Проверить качество'
        END
    ELSE NULL END,
    
    -- опции товара
    jsonb_build_object(
        'gift_wrap', random() < 0.15,
        'warranty', random() < 0.25,
        'engraving', CASE WHEN random() < 0.02 THEN 'С праздником!' ELSE NULL END
    ),
    
    -- окно возврата
    CASE WHEN random() < 0.3 THEN
        daterange(
            current_date,
            current_date + (random()*30)::int,
            '[]'
        )
    ELSE NULL END
    
FROM generate_series(1, 250000) gs
ON CONFLICT (order_id, product_id) DO NOTHING;



