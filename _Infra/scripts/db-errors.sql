-- Информация об ошибках входных параметров
-- Таблица с текстами ошибок

begin;

do 
$$ begin

    drop table if exists "Типы ошибок" cascade;
    drop sequence if exists seq_error_types;

    create sequence seq_error_types;

    create table "Типы ошибок" (
        "Код"      integer      primary key default nextval('seq_error_types'),
        "Название" varchar(100) not null,
        "Описание" varchar(200) not null
    );

    insert into "Типы ошибок" ("Код", "Название", "Описание") values
        (1, 'Не задан',                   'не задан'),
        (2, 'Вне диапазона',              'вне диапазона'),
        (3, 'Не целое число',             'должно быть целым числом'),
        (4, 'Лишние знаки после запятой', 'не более одного знака после запятой');

    perform setval('seq_error_types', (select max("Код") from "Типы ошибок"));

    -- по ТЗ: температура - один знак после запятой, остальные параметры - целые числа
    alter table "Типы параметров" add column if not exists "Знаков после запятой" integer;

    update "Типы параметров"
    set "Знаков после запятой" = case when "Код" = 2 then 1 else 0 end;

end $$;

commit;


-- Тип данных: список параметров

DROP TYPE IF EXISTS public."Список параметров" CASCADE;

CREATE TYPE public."Список параметров" AS (
	equipment   integer,   -- код типа оборудования: 1 = ДМК, 2 = ВР
	height      numeric,   -- высота метеопоста
	temperature numeric,   -- температура
	pressure    numeric,   -- давление
	direction   numeric,   -- направление ветра
	speed       numeric,   -- скорость ветра (ДМК)
	drift       numeric    -- дальность сноса пуль (ВР)
);


-- Функция: проверка параметров, возвращает строку со списком ошибок ('' - ошибок нет)
-- Диапазоны и точность берутся из "Типы параметров", тексты - из "Типы ошибок"

CREATE OR REPLACE FUNCTION public."Проверка_Параметров"("Список" public."Список параметров")
    RETURNS text
    LANGUAGE 'plpgsql'
AS $BODY$
begin

	return coalesce((
		with v as (
			-- код типа параметра и его значение
			select * from (values
				(1, "Список".height),
				(2, "Список".temperature),
				(3, "Список".pressure),
				(4, "Список".direction),
				(5, "Список".speed),
				(6, "Список".drift)
			) as t(code, value)
		),
		e as (
			-- нужные параметры: скорость ветра только для ДМК, дальность сноса пуль только для ВР
			select
				tp."Код"          as code,
				tp."Название"     as name,
				v.value,
				tp."Мин значение" as min_value,
				tp."Макс значение" as max_value,
				tp."Знаков после запятой" as scale
			from v
			join "Типы параметров" tp on tp."Код" = v.code
			where v.code <= 4
			   or (v.code = 5 and "Список".equipment = 1)
			   or (v.code = 6 and "Список".equipment = 2)
		)
		select string_agg(
			e.name || ': ' || case
				when e.value is null then (select "Описание" from "Типы ошибок" where "Код" = 1)
				when e.value < e.min_value or e.value > e.max_value
					then (select "Описание" from "Типы ошибок" where "Код" = 2) || ' ' || e.min_value || '..' || e.max_value
				when e.scale = 0 then (select "Описание" from "Типы ошибок" where "Код" = 3)
				else (select "Описание" from "Типы ошибок" where "Код" = 4)
			end,
			'; ' order by e.code)
		from e
		where e.value is null
		   or e.value < e.min_value
		   or e.value > e.max_value
		   or e.value <> round(e.value, e.scale)
	), '');

end;
$BODY$;


-- Проверка: корректные параметры -> пусто; температура 75 и нет давления -> две ошибки
select
	public."Проверка_Параметров"(row(1, 100, 15, 750, 5, 3, null)::public."Список параметров") as "Корректные",
	public."Проверка_Параметров"(row(1, 100, 75, null, 5, 3, null)::public."Список параметров") as "С ошибками";
