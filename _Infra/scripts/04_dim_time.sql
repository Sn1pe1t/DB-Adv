CREATE OR REPLACE FUNCTION fill_dim_time(year_from int, year_to int) RETURNS void
LANGUAGE sql AS $$
    INSERT INTO dim_time
    SELECT to_char(m, 'YYYYMM')::int,
           m::date,
           (m + interval '1 month - 1 day')::date,
           (ARRAY['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
                  'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'])[extract(month FROM m)::int],
           extract(year FROM m),
           extract(quarter FROM m),
           extract(quarter FROM m) || ' квартал'
    FROM generate_series(make_date(year_from, 1, 1)::timestamp,
                         make_date(year_to, 12, 1)::timestamp,
                         interval '1 month') AS m
    ON CONFLICT DO NOTHING
$$;

SELECT fill_dim_time(2015, 2030);
