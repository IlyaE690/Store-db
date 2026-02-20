INSERT INTO product_category (id, name)
VALUES 
    (1, 'Электроника'),
    (2, 'Одежда'),
    (3, 'Книги'),
    (4, 'Дом'),
    (5, 'Спорт'),
    (6, 'Красота'),
    (7, 'Авто'),
    (8, 'Детям'),
    (9, 'Зоотовары'),
    (10, 'Продукты'),
    (11, 'Мебель'),
    (12, 'Инструменты'),
    (13, 'Канцелярия')
ON CONFLICT (id) DO NOTHING;

INSERT INTO supplier (id, organization_name, phone)
VALUES 
    (1, 'ООО Поставщик', NULL),
    (2, 'АО Торговый дом', NULL),
    (3, 'ИП Петров', NULL),
    (4, 'ТД Альянс', NULL),
    (5, 'Глобал Импорт', NULL),
    (6, 'Локал Маркет', NULL),
    (7, 'Дистрибьютор Плюс', NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO warehouse (id, address, manager_id)
VALUES 
    (1, 'г. Москва, ул. Ленина, 1', NULL),
    (2, 'г. Санкт-Петербург, пр. Невский, 50', NULL),
    (3, 'г. Краснодар, ул. Красная, 100', NULL),
    (4, 'г. Новосибирск, ул. Советская, 200', NULL),
    (5, 'г. Калининград, ул. Мира, 30', NULL)
ON CONFLICT (id) DO NOTHING;

INSERT INTO employee (
    id,
    warehouse_id,
    last_name,
    first_name,
    patronymic,
    gender,
    birth_date
)
SELECT
    gs,
    (random()*4 + 1)::int,                     
    (ARRAY['Иванов', 'Петров', 'Сидоров', 'Смирнов', 'Кузнецов', 'Попов', 'Васильев'])[(random()*6)::int + 1],
    (ARRAY['Александр', 'Дмитрий', 'Максим', 'Сергей', 'Андрей', 'Алексей', 'Иван'])[(random()*6)::int + 1],
    (ARRAY['Александрович', 'Дмитриевич', 'Максимович', 'Сергеевич', 'Андреевич', 'Алексеевич', 'Иванович'])[(random()*6)::int + 1],
    'M',
    current_date - ((random()*47 + 18) * 365)::int
FROM generate_series(1, 30) gs
ON CONFLICT (id) DO NOTHING;