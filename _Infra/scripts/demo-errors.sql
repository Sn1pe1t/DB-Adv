-- 2. Список параметров с ошибками
-- N - код пачки. Проверку выполняет функция Проверка_Параметров

with p as (
	-- проекция: параметры пачки в одной строке
	select
		pk."Код"              as pack,
		pk."Код оборудования" as equipment_code,
		e."Название"          as equipment,
		h."Значение"          as height,
		t."Значение"          as temperature,
		pr."Значение"         as pressure,
		d."Значение"          as direction,
		s."Значение"          as speed,
		r."Значение"          as drift
	from "Пачки" pk
	left join "Типы оборудования" e on e."Код" = pk."Код оборудования"
	left join "Параметры" h  on h."Код пачки"  = pk."Код" and h."Код типа параметра"  = 1
	left join "Параметры" t  on t."Код пачки"  = pk."Код" and t."Код типа параметра"  = 2
	left join "Параметры" pr on pr."Код пачки" = pk."Код" and pr."Код типа параметра" = 3
	left join "Параметры" d  on d."Код пачки"  = pk."Код" and d."Код типа параметра"  = 4
	left join "Параметры" s  on s."Код пачки"  = pk."Код" and s."Код типа параметра"  = 5
	left join "Параметры" r  on r."Код пачки"  = pk."Код" and r."Код типа параметра"  = 6
),
r as (
	-- список ошибок по каждой пачке
	select
		p.*,
		public."Проверка_Параметров"(
			row(equipment_code, height, temperature, pressure, direction, speed, drift)::public."Список параметров"
		) as err
	from p
)
select
	pack        as "№",
	equipment   as "Тип оборудования",
	height      as "Высота метеопоста",
	temperature as "Температура",
	pressure    as "Давление",
	direction   as "Направление ветра",
	speed       as "Скорость ветра",
	drift       as "Дальность сноса пуль",
	err <> ''   as "Флаг: Есть ошибка",
	err         as "Описание ошибки"
from r
order by pack;


-- 3. Лучший стрелок
-- пользователи, количество пачек и допущенных ошибок; чем меньше ошибок, тем выше место

with p as (
	select
		pk."Код"              as pack,
		pk."Код пользователя" as user_code,
		pk."Код оборудования" as equipment_code,
		h."Значение"          as height,
		t."Значение"          as temperature,
		pr."Значение"         as pressure,
		d."Значение"          as direction,
		s."Значение"          as speed,
		r."Значение"          as drift
	from "Пачки" pk
	left join "Параметры" h  on h."Код пачки"  = pk."Код" and h."Код типа параметра"  = 1
	left join "Параметры" t  on t."Код пачки"  = pk."Код" and t."Код типа параметра"  = 2
	left join "Параметры" pr on pr."Код пачки" = pk."Код" and pr."Код типа параметра" = 3
	left join "Параметры" d  on d."Код пачки"  = pk."Код" and d."Код типа параметра"  = 4
	left join "Параметры" s  on s."Код пачки"  = pk."Код" and s."Код типа параметра"  = 5
	left join "Параметры" r  on r."Код пачки"  = pk."Код" and r."Код типа параметра"  = 6
),
r as (
	select
		user_code,
		public."Проверка_Параметров"(
			row(equipment_code, height, temperature, pressure, direction, speed, drift)::public."Список параметров"
		) as err
	from p
),
u as (
	-- группировка: пачки и ошибки по пользователям (ошибок в строке столько, сколько элементов через '; ')
	select
		user_code,
		count(*) as packs,
		sum(case when err = '' then 0 else cardinality(string_to_array(err, '; ')) end) as errors
	from r
	group by user_code
)
select
	dense_rank() over (order by u.errors) as "Место",
	us."Фамилия" || ' ' || us."Имя"       as "Стрелок",
	u.packs                               as "Пачек",
	u.errors                              as "Ошибок"
from u
join "Пользователи" us on us."Код" = u.user_code
order by "Место", "Стрелок";
