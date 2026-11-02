-- Функции расчёта Метео приближенный: ДДЧЧМ, ВВВВ, БББТТ
-- Нужны: db-constants.sql (константы) и функции интерполяции (Шаг_Интерполяции, Расчет_Интерполяции)


-- ДДЧЧМ: день месяца, часы, десятки минут (по умолчанию системное время)

CREATE OR REPLACE FUNCTION public."Метео_ДДЧЧМ"(p_time timestamp DEFAULT localtimestamp)
    RETURNS text
    LANGUAGE 'sql'
AS $BODY$
	select to_char(p_time, 'DDHH24') || (extract(minute from p_time)::int / 10)::text
$BODY$;


-- ВВВВ: высота метеопоста, четыре знака (60 -> 0060)
-- для отрицательной высоты в ТЗ правила нет, пишется знак минус и три цифры

CREATE OR REPLACE FUNCTION public."Метео_ВВВВ"(p_height numeric)
    RETURNS text
    LANGUAGE 'sql'
AS $BODY$
	select case
		when p_height >= 0 then lpad(round(p_height)::text, 4, '0')
		else '-' || lpad(round(abs(p_height))::text, 3, '0')
	end
$BODY$;


-- БББТТ: БББ - отклонение давления от табличного, ТТ - отклонение виртуальной температуры
-- отрицательные отклонения: давление +500 (-7 -> 507), температура +50 (-12 -> 62)

CREATE OR REPLACE FUNCTION public."Метео_БББТТ"(p_pressure numeric, p_temperature numeric)
    RETURNS text
    LANGUAGE 'sql'
AS $BODY$
	with d as (
		select
			-- БББ: давление - табличное давление
			round(p_pressure - public."Константа"('Табличное давление')) as dh,
			-- ТТ: T0 = t0 + виртуальная поправка (таблица 1), затем T0 - табличная температура
			-- ниже 0 поправка постоянная, иначе - интерполяция
			round(p_temperature
			      + case when p_temperature < 0
			             then public."Константа"('Виртуальная поправка ниже 0')
			             else public."Расчет_Интерполяции"(p_temperature, public."Шаг_Интерполяции"(p_temperature))
			        end
			      - public."Константа"('Табличная виртуальная температура')) as dt
	)
	select
		case when dh >= 0
			then lpad(dh::text, 3, '0')
			else lpad((abs(dh) + public."Константа"('Смещение отрицательного давления'))::text, 3, '0')
		end
		||
		case when dt >= 0
			then lpad(dt::text, 2, '0')
			else lpad((abs(dt) + public."Константа"('Смещение отрицательной температуры'))::text, 2, '0')
		end
	from d
$BODY$;


-- Проверка по примерам ТЗ: 24093, 0060, 01511 (давление 765, температура 25)

select
	public."Метео_ДДЧЧМ"(timestamp '2026-10-24 09:30:00') as "ДДЧЧМ",
	public."Метео_ВВВВ"(60)                               as "ВВВВ",
	public."Метео_БББТТ"(765, 25)                         as "БББТТ",
	public."Метео_БББТТ"(750, 23)                         as "Пример 1 ТЗ (ТТ = 09)";
