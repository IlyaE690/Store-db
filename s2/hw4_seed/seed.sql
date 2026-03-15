WITH
    first_names AS (
        SELECT ARRAY[
                   'Александр', 'Дмитрий', 'Максим', 'Сергей', 'Андрей', 'Алексей', 'Иван', 'Евгений',
               'Михаил', 'Артем', 'Владимир', 'Роман', 'Николай', 'Денис', 'Павел', 'Кирилл'
    ] as name
    ),
    last_names AS (
SELECT ARRAY[
    'Иванов', 'Петров', 'Сидоров', 'Смирнов', 'Кузнецов', 'Попов', 'Васильев',
    'Михайлов', 'Федоров', 'Морозов', 'Волков', 'Алексеев', 'Лебедев', 'Семенов',
    'Егоров', 'Павлов', 'Козлов', 'Степанов', 'Николаев', 'Орлов'
    ] as name
    ),
    patronymics AS (
SELECT ARRAY[
    'Александрович', 'Дмитриевич', 'Максимович', 'Сергеевич', 'Андреевич',
    'Алексеевич', 'Иванович', 'Евгеньевич', 'Михайлович', 'Артемович',
    'Владимирович', 'Романович', 'Николаевич', 'Денисович', 'Павлович'
    ] as name
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
    (SELECT name FROM last_names)[ceil(random() * 20)::int],


    (SELECT name FROM first_names)[ceil(random() * 16)::int],

    CASE WHEN random() < 0.2 THEN NULL
         ELSE ((SELECT name FROM patronymics)[ceil(random() * 15)::int])
END,

    lower(
        ((SELECT name FROM first_names)[ceil(random() * 16)::int]) || '.' ||
        ((SELECT name FROM last_names)[ceil(random() * 20)::int]) ||
        CASE (random()*3)::int
            WHEN 0 THEN '@gmail.com'
            WHEN 1 THEN '@yandex.ru'
            WHEN 2 THEN '@mail.ru'
            ELSE '@bk.ru'
        END
    ),

    CASE
        WHEN random() < 0.4 THEN 'Bronze'     -- 40%
        WHEN random() < 0.7 THEN 'Silver'     -- 30%
        WHEN random() < 0.9 THEN 'Gold'       -- 20%
        ELSE 'Platinum'                        -- 10%
END,

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

    CASE WHEN random() < 0.15 THEN NULL
         ELSE 'fp_' || encode(sha256((gs || random()::text)::bytea), 'hex')
END

FROM generate_series(1, 260000) gs
on conflict do nothing;