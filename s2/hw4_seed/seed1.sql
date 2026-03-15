WITH
    categories AS (
        SELECT ARRAY[
                   'Электроника', 'Одежда', 'Книги', 'Дом', 'Спорт', 'Красота', 'Авто',
               'Детям', 'Зоотовары', 'Продукты', 'Мебель', 'Инструменты', 'Канцелярия'
    ] as name
    ),
    units AS (
SELECT ARRAY['шт', 'кг', 'л', 'м', 'уп', 'пара', 'компл'] as unit
    ),
    suppliers AS (
SELECT ARRAY[
    'ООО Поставщик', 'АО Торговый дом', 'ИП Петров', 'ТД Альянс',
    'Глобал Импорт', 'Локал Маркет', 'Дистрибьютор Плюс'
    ] as name
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
    CASE (random()*9)::int
        WHEN 0 THEN 'Смартфон'
        WHEN 1 THEN 'Ноутбук'
        WHEN 2 THEN 'Футболка'
        WHEN 3 THEN 'Джинсы'
        WHEN 4 THEN 'Книга'
        WHEN 5 THEN 'Наушники'
        WHEN 6 THEN 'Кружка'
        WHEN 7 THEN 'Мяч'
        ELSE 'Часы'
END || ' ' ||
    CASE (random()*5)::int
        WHEN 0 THEN 'Pro'
        WHEN 1 THEN 'Lite'
        WHEN 2 THEN 'Max'
        WHEN 3 THEN 'Mini'
        ELSE ''
END,

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

    (SELECT unit FROM units)[ceil(random() * 7)::int],

    CASE
        WHEN random() < 0.35 THEN 1
        WHEN random() < 0.55 THEN 2
        WHEN random() < 0.7 THEN 3
        WHEN random() < 0.8 THEN 4
        ELSE (random()*3)::int + 4
END,

    CASE WHEN random() < 0.3 THEN NULL
         ELSE current_timestamp - (random()*365)::int * interval '1 day'
END,

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

    ARRAY[
        (ARRAY['новинка', 'премиум', 'хит', 'распродажа', 'акция'])[floor(random()*5)+1],
        (ARRAY['новинка', 'премиум', 'хит', 'распродажа', 'акция'])[floor(random()*5)+1],
        (ARRAY['новинка', 'преимум', 'хит', 'распродажа', 'акция'])[floor(random()*5)+1]
        ],

    daterange(
                    current_date - (random()*180)::int,
                    current_date - (random()*10)::int + 10,
                    '[]'
    ),

    to_tsvector('russian',
                COALESCE((SELECT name FROM categories)[ceil(random() * 13)::int], '') || ' ' ||
                'товар описание ' || gs
    )

FROM generate_series(1, 260000) gs
on conflict do nothing;

