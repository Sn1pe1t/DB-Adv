-- 1. Подготовка временной таблицы для красивого вывода результатов на экран
CREATE TEMP TABLE IF NOT EXISTS my_db_temperature_validation (
    id serial,
    pack_name text,
    measured_t0 numeric,
    node_x0 numeric,
    node_y0 numeric,
    node_x1 numeric,
    node_y1 numeric,
    calculated_delta_tv numeric,
    check_status text
);
TRUNCATE TABLE my_db_temperature_validation;

-- 2. Основной блок DO $$ для расчета по температурам из твоей БД
DO $$
DECLARE
    db_row record;
    detected_nodes public."Интерполяция";
    result_y numeric;
BEGIN
    -- Выбираем названия пачек и значения температур из твоих таблиц
    FOR db_row IN 
        SELECT 
            p."Название" AS name, 
            param."Значение" AS t0
        FROM "Пачки" p
        JOIN "Параметры" param ON param."Код пачки" = p."Код"
        WHERE param."Код типа параметра" = 2 -- Код 2 соответствует "Температуре"
        ORDER BY p."Код"
    LOOP
        -- Шаг 1: Получаем структуру узлов для текущей температуры из БД
        detected_nodes := public."Шаг_Интерполяции"(db_row.t0);
        
        -- Шаг 2: Рассчитываем итоговую виртуальную поправку
        result_y := public."Расчет_Интерполяции"(db_row.t0, detected_nodes);

        -- Шаг 3: Фиксируем расчеты во временной таблице
        INSERT INTO my_db_temperature_validation (
            pack_name, 
            measured_t0, 
            node_x0, 
            node_y0, 
            node_x1, 
            node_y1, 
            calculated_delta_tv, 
            check_status
        )
        VALUES (
            db_row.name, 
            db_row.t0, 
            detected_nodes.x0, 
            detected_nodes.y0, 
            detected_nodes.x1, 
            detected_nodes.y1, 
            result_y, 
            'Расчитано успешно'
        );
    END LOOP;
END $$;

-- 3. Вывод результатов работы блока DO на вкладку Data Output в pgAdmin
SELECT 
    pack_name AS "Название пачки",
    measured_t0 AS "Измеренная температура (t0)",
    node_x0 AS "x0",
    node_y0 AS "y0",
    node_x1 AS "x1",
    node_y1 AS "y1",
    calculated_delta_tv AS "Виртуальная поправка (ΔTv)",
    check_status AS "Статус проверки"
FROM my_db_temperature_validation
ORDER BY id;
