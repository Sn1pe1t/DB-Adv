
DROP FUNCTION IF EXISTS public.fn_calculate_meteo_corrections(public."Список параметров");


CREATE OR REPLACE FUNCTION public.fn_calculate_meteo_corrections(
    p_params public."Список параметров"
)
RETURNS TABLE (
    height INTEGER,
    delta_tv NUMERIC,
    wind_dir INTEGER,
    wind_speed INTEGER
)
LANGUAGE plpgsql
AS $BODY$
declare
    v_temp_type_id integer;
    v_wind_speed_type_id integer;
    v_wind_dir_type_id integer;
    
    v_temp_header integer[];
    v_wind_header integer[];
    
    v_temp_val numeric;
    v_wind_val numeric;
    
    v_temp_idx integer;
    v_wind_idx integer;
    
    rec record;
    v_dtv numeric;
    v_w_speed integer;
    v_w_dir integer;
    v_is_zero_wind boolean := false;
begin
    v_temp_val := p_params.temperature;

    if v_temp_val >= 0 then
        v_temp_type_id := 8; 
    else
        v_temp_type_id := 9; 
    end if;

    if p_params.equipment = 1 then
        v_wind_speed_type_id := 6; 
        v_wind_dir_type_id   := 7; 
        v_wind_val           := p_params.speed;
        if v_wind_val < 3 then
            v_is_zero_wind := true;
        end if;
    else
        v_wind_speed_type_id := 4; 
        v_wind_dir_type_id   := 5; 
        v_wind_val           := p_params.drift;
        if v_wind_val < 40 then
            v_is_zero_wind := true;
        end if;
    end if;

    select h.header_values into v_temp_header
    from public.calc_correction_types t
    join public.calc_correction_headers h on h.id = t.header_id
    where t.id = v_temp_type_id;

    select h.header_values into v_wind_header
    from public.calc_correction_types t
    join public.calc_correction_headers h on h.id = t.header_id
    where t.id = v_wind_speed_type_id;

    select idx into v_temp_idx
    from unnest(v_temp_header) with ordinality as t(val, idx)
    order by abs(val - abs(v_temp_val))
    limit 1;

    select idx into v_wind_idx
    from unnest(v_wind_header) with ordinality as t(val, idx)
    order by abs(val - coalesce(v_wind_val, 0))
    limit 1;

    for rec in 
        select h.id as h_id, h.height as h_val
        from public.calc_correction_heights h
        order by h.height
    loop
        select row_values[v_temp_idx] into v_dtv
        from public.calc_correction
        where height_id = rec.h_id and type_id = v_temp_type_id;

        if v_is_zero_wind then
            v_w_speed := 0;
            v_w_dir   := 0;
        else
            select row_values[v_wind_idx] into v_w_speed
            from public.calc_correction
            where height_id = rec.h_id and type_id = v_wind_speed_type_id;

            select (p_params.direction + row_values[v_wind_idx]) % 60 into v_w_dir
            from public.calc_correction
            where height_id = rec.h_id and type_id = v_wind_dir_type_id;
        end if;

        height     := rec.h_val;
        delta_tv   := coalesce(v_dtv, 0);
        wind_dir   := coalesce(v_w_dir, 0);
        wind_speed := coalesce(v_w_speed, 0);
        
        return next;
    end loop;
end;
$BODY$;

-- Тестовый вызов
select 
    height     as "Высота (H, м)",
    delta_tv   as "Отклонение температуры (TT)",
    wind_dir   as "Направление ветра (HH)",
    wind_speed as "Скорость ветра (СС)"
from public.fn_calculate_meteo_corrections(
    row(1, 100, 25, 765, 15, 6, null)::public."Список параметров"
);