DO $$ 
BEGIN
    -- 1. Добавление DDL структуры: новый тип данных для интерполяции
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'Интерполяция' AND typtype = 'c') THEN
        EXECUTE 'CREATE TYPE public."Интерполяция" AS (
            x0 numeric(6,2),
            y0 numeric(6,2),
            x1 numeric(6,2),
            y1 numeric(6,2)
        )';
        EXECUTE 'ALTER TYPE public."Интерполяция" OWNER TO postgres;';
    END IF;

    -- 2. Добавление функции (DDL) для определения параметров интерполяции по температуре
    EXECUTE 'CREATE OR REPLACE FUNCTION public."Шаг_Интерполяции"("Температура" numeric)
    RETURNS public."Интерполяция"
    LANGUAGE plpgsql
    COST 100
    VOLATILE PARALLEL UNSAFE
    AS $body$
    DECLARE
        var_result public."Интерполяция";
        var_value numeric := "Температура";
    BEGIN 
        SELECT
            -- x0: если замер отрицательный (вернулся NULL) - берем саму температуру замера
            COALESCE((SELECT MAX(t."Температура") FROM "Виртуальные поправки" t WHERE t."Температура" <= var_value), var_value),
            -- y0: если замер отрицательный - берем поправку от 0 градусов (0.5)
            COALESCE((SELECT t."Поправка"         FROM "Виртуальные поправки" t WHERE t."Температура" <= var_value ORDER BY t."Температура" DESC LIMIT 1), 0.5),
     
            -- x1: если замер > 40 (вернулся NULL) - берем саму температуру замера
            COALESCE((SELECT MIN(t."Температура") FROM "Виртуальные поправки" t WHERE t."Температура" >= var_value), var_value),
            -- y1: если замер > 40 - берем поправку от максимальных 40 градусов (4.5)
            COALESCE((SELECT t."Поправка"         FROM "Виртуальные поправки" t WHERE t."Температура" >= var_value ORDER BY t."Температура" ASC LIMIT 1), 4.5)
        INTO var_result.x0, var_result.y0, var_result.x1, var_result.y1;
     
        RETURN var_result;
    END;
    $body$;';
    
    EXECUTE 'ALTER FUNCTION public."Шаг_Интерполяции"(numeric) OWNER TO postgres;';

    -- 3. Добавление функции (DDL) для расчета интерполяции
    EXECUTE 'CREATE OR REPLACE FUNCTION public."Расчет_Интерполяции"(x numeric, "Параметры" public."Интерполяция")
    RETURNS numeric
    LANGUAGE plpgsql
    AS $body$
    BEGIN
        -- Защита от деления на ноль: если x0 равно x1 (крайние точки таблицы или точное попадание в узел)
        IF "Параметры".x1 = "Параметры".x0 THEN
            RETURN "Параметры".y0;
        END IF;

        -- Классическая формула линейной интерполяции для поиска значения (y)
        RETURN "Параметры".y0 + (x - "Параметры".x0) * ("Параметры".y1 - "Параметры".y0) / ("Параметры".x1 - "Параметры".x0);
    END;
    $body$;';

    EXECUTE 'ALTER FUNCTION public."Расчет_Интерполяции"(numeric, public."Интерполяция") OWNER TO postgres;';

END $$;
