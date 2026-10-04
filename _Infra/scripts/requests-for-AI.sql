 
-- Запрос 1: количество пачек по пользователям
 
select t1."Код", t1."Фамилия", count(t2."Код") as batch_count
from "Пользователи" t1
left join "Пачки" t2 on t1."Код" = t2."Код пользователя"
group by t1."Код", t1."Фамилия";
 
 
-- Запрос 2: проверка пустых пачек
 
select t1."Код" as batch_id, count(t2."Код") as param_count
from "Пачки" t1
left join "Параметры" t2 on t1."Код" = t2."Код пачки"
group by t1."Код"
having count(t2."Код") = 0;
 
 
-- Запрос 3: проверка количества параметров в пачке
 
select "Код пачки" as batch_id, count(*) as param_count
from "Параметры"
group by "Код пачки"
having count(*) != 5;
 
 
-- Запрос 4: проверка значений вне диапазона
 
select t1.* from "Параметры" t1
join "Типы параметров" t2 on t1."Код типа параметра" = t2."Код"
where t2."Мин значение" is not null
  and (
        cast(t1."Значение" as numeric) < t2."Мин значение"
     or cast(t1."Значение" as numeric) > t2."Макс значение"
  );
 
 
-- Запрос 5: проверка единиц измерения
 
select t1.* from "Параметры" t1
left join "Типы параметров"   t2 on t1."Код типа параметра" = t2."Код"
left join "Единицы измерения" t3 on t2."Код единицы измерения" = t3."Код"
where t2."Код" is null
   or t3."Код" is null;