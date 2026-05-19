INSERT INTO olap.dim_date (date_id, full_date, year, quarter, month, month_name,
                           day, day_of_week, day_name, week, is_weekend)
SELECT
    (EXTRACT(YEAR FROM d) * 10000 + EXTRACT(MONTH FROM d) * 100 + EXTRACT(DAY FROM d))::INTEGER,
    d::DATE,
    EXTRACT(YEAR FROM d)::INTEGER,
    EXTRACT(QUARTER FROM d)::INTEGER,
    EXTRACT(MONTH FROM d)::INTEGER,
    CASE EXTRACT(MONTH FROM d)
        WHEN 1 THEN 'Январь' WHEN 2 THEN 'Февраль' WHEN 3 THEN 'Март'
        WHEN 4 THEN 'Апрель' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июнь'
        WHEN 7 THEN 'Июль' WHEN 8 THEN 'Август' WHEN 9 THEN 'Сентябрь'
        WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь' ELSE 'Декабрь'
        END,
    EXTRACT(DAY FROM d)::INTEGER,
    EXTRACT(DOW FROM d)::INTEGER,
    CASE EXTRACT(DOW FROM d)
        WHEN 1 THEN 'Понедельник' WHEN 2 THEN 'Вторник' WHEN 3 THEN 'Среда'
        WHEN 4 THEN 'Четверг' WHEN 5 THEN 'Пятница' WHEN 6 THEN 'Суббота'
        ELSE 'Воскресенье'
        END,
    EXTRACT(WEEK FROM d)::INTEGER,
    EXTRACT(DOW FROM d) IN (0, 6)
FROM generate_series('2023-01-01'::DATE, '2026-12-31'::DATE, '1 day'::INTERVAL) d
    ON CONFLICT (date_id) DO NOTHING;