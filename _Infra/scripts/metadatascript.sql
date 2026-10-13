select
    row_number() over (order by t.sort, t.name) as "№",
    t.name                                      as "Наименование",
    t.type                                      as "Тип"
from (
    select 1 as sort, table_name as name, 'Таблица' as type
    from information_schema.tables
    where table_catalog = 'PGSQL-Database'
      and table_schema = 'public'
      and table_type = 'BASE TABLE'

    union all

    select 2, sequence_name, 'Последовательность'
    from information_schema.sequences
    where sequence_catalog = 'PGSQL-Database'
      and sequence_schema = 'public'

    union all

    select 3, constraint_name,
           case constraint_type
               when 'PRIMARY KEY' then 'Первичный ключ'
               when 'FOREIGN KEY' then 'Внешний ключ'
               when 'UNIQUE'      then 'Уникальность'
               when 'CHECK'       then 'Проверка'
           end
    from information_schema.table_constraints
    where constraint_catalog = 'PGSQL-Database'
      and constraint_schema = 'public'
      and constraint_name not like '%not_null'
) t
order by t.sort, t.name;