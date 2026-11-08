DO $$
BEGIN


    CREATE TABLE IF NOT EXISTS public.calc_correction_headers (
        id SERIAL PRIMARY KEY,
        header_name TEXT NOT NULL,
        header_values INTEGER[] NOT NULL
    );

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'calc_correction_types' 
          AND column_name = 'header_id'
    ) THEN
        ALTER TABLE public.calc_correction_types ADD COLUMN header_id INTEGER REFERENCES public.calc_correction_headers(id);
    END IF;


    INSERT INTO public.calc_correction_headers(id, header_name, header_values) VALUES
    (1, 'Температурные градации (Табл 2)', ARRAY[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 40, 50]),
    (2, 'Ветер ВР (Табл 3)', ARRAY[40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150]),
    (3, 'Ветер ДМК (Табл 3)', ARRAY[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
    ON CONFLICT (id) DO UPDATE SET header_values = EXCLUDED.header_values;

    INSERT INTO public.calc_correction_types(id, description, parent_id, header_id)
    VALUES 
    (8, 'Таблица 2, Положительные температуры', 1, 1),
    (9, 'Таблица 2, Отрицательные температуры', 1, 1)
    ON CONFLICT (id) DO NOTHING;


    UPDATE public.calc_correction_types SET header_id = 1 WHERE id IN (1, 8, 9);
    UPDATE public.calc_correction_types SET header_id = 2 WHERE id IN (4, 5);
    UPDATE public.calc_correction_types SET header_id = 3 WHERE id IN (6, 7);



    INSERT INTO public.calc_correction_heights (height)
    SELECT h FROM (VALUES (1600), (2000), (2400), (3000), (4000)) AS t(h)
    WHERE NOT EXISTS (SELECT 1 FROM public.calc_correction_heights WHERE height = t.h);

    UPDATE public.calc_correction SET type_id = 8 WHERE type_id = 7 AND height_id <= 4;

    DELETE FROM public.calc_correction WHERE type_id = 8;
    INSERT INTO public.calc_correction(height_id, type_id, row_values) VALUES
    (1, 8, ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 35, 40, 45]),
    (2, 8, ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 35, 40, 45]),
    (3, 8, ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 35, 40, 45]),
    (4, 8, ARRAY[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 20, 30, 35, 40, 45]),
    (5, 8, ARRAY[2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 21, 31, 36, 41, 46]),
    (6, 8, ARRAY[2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 21, 31, 36, 41, 46]),
    (7, 8, ARRAY[2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 21, 31, 36, 41, 46]),
    (8, 8, ARRAY[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 22, 32, 37, 42, 47]),
    (9, 8, ARRAY[3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 22, 32, 37, 42, 47]);

    DELETE FROM public.calc_correction WHERE type_id = 9;
    INSERT INTO public.calc_correction(height_id, type_id, row_values) VALUES
    (1, 9, ARRAY[-1, -2, -3, -4, -5, -6, -7, -8, -8, -9, -20, -29, -39, -49, -55]),
    (2, 9, ARRAY[-1, -2, -3, -4, -5, -6, -6, -7, -8, -9, -19, -29, -39, -48, -54]),
    (3, 9, ARRAY[-1, -2, -3, -4, -5, -6, -6, -7, -7, -8, -18, -28, -37, -46, -52]),
    (4, 9, ARRAY[-1, -2, -3, -4, -4, -5, -5, -6, -7, -8, -17, -26, -35, -44, -50]),
    (5, 9, ARRAY[-2, -3, -4, -5, -5, -6, -6, -7, -8, -9, -18, -27, -36, -45, -51]),
    (6, 9, ARRAY[-2, -3, -4, -5, -5, -6, -6, -7, -8, -9, -18, -27, -36, -45, -51]),
    (7, 9, ARRAY[-2, -3, -4, -5, -5, -6, -6, -7, -8, -9, -18, -27, -36, -45, -51]),
    (8, 9, ARRAY[-3, -4, -5, -6, -6, -7, -7, -8, -9, -10, -19, -28, -37, -46, -52]),
    (9, 9, ARRAY[-3, -4, -5, -6, -6, -7, -7, -8, -9, -10, -19, -28, -37, -46, -52]);

    DELETE FROM public.calc_correction WHERE type_id = 6;
    INSERT INTO public.calc_correction(height_id, type_id, row_values) VALUES
    (1, 6, ARRAY[4, 6, 8, 9, 10, 12, 14, 15, 16, 18, 20, 21, 22]),
    (2, 6, ARRAY[5, 7, 10, 11, 12, 14, 17, 18, 20, 22, 23, 25, 27]),
    (3, 6, ARRAY[5, 8, 10, 11, 13, 15, 18, 19, 21, 23, 25, 27, 28]),
    (4, 6, ARRAY[5, 8, 11, 12, 13, 16, 19, 20, 23, 24, 26, 28, 30]),
    (5, 6, ARRAY[6, 9, 12, 13, 14, 17, 20, 21, 24, 25, 27, 29, 31]),
    (6, 6, ARRAY[6, 9, 12, 13, 14, 17, 20, 21, 24, 25, 27, 29, 31]),
    (7, 6, ARRAY[7, 10, 13, 14, 15, 18, 21, 22, 25, 26, 28, 30, 32]),
    (8, 6, ARRAY[7, 10, 13, 14, 15, 18, 21, 22, 25, 26, 28, 30, 32]),
    (9, 6, ARRAY[8, 11, 14, 15, 16, 19, 22, 23, 26, 27, 29, 31, 33]);

    DELETE FROM public.calc_correction WHERE type_id = 7;
    INSERT INTO public.calc_correction(height_id, type_id, row_values) VALUES
    (1, 7, ARRAY[1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7]),
    (2, 7, ARRAY[2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8]),
    (3, 7, ARRAY[3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9]),
    (4, 7, ARRAY[3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9]),
    (5, 7, ARRAY[4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10]),
    (6, 7, ARRAY[4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10]),
    (7, 7, ARRAY[5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11]),
    (8, 7, ARRAY[5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11]),
    (9, 7, ARRAY[6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12]);

END $$;