do $$
begin
    create schema if not exists olap_v2;
    create sequence if not exists olap_v2.seq_time;

    create table if not exists olap_v2.dim_time (
        id bigint primary key default nextval('olap_v2.seq_time'),
        external_id bigint unique,
        date_start date,
        date_end date,
        month_name text,
        year_num integer,
        quarter_num integer,
        quarter_name text
    );

    insert into olap_v2.dim_time
        (external_id, date_start, date_end, month_name, year_num, quarter_num, quarter_name)
    select
        extract(year from d)::bigint * 100 + extract(month from d)::bigint,
        d::date,
        (d + interval '1 month - 1 day')::date,
        (array['Январь','Февраль','Март','Апрель','Май','Июнь',
               'Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'])
            [extract(month from d)::integer],
        extract(year from d)::integer,
        extract(quarter from d)::integer,
        extract(quarter from d)::integer || ' квартал'
    from generate_series(date '2015-01-01', date '2035-12-01', interval '1 month') as m(d)
    on conflict (external_id) do nothing;
end $$;

select
    id           as "Код",
    date_start   as "Дата начала месяца",
    date_end     as "Дата окончания месяца",
    month_name   as "Название месяца",
    year_num     as "Год",
    quarter_num  as "Номер квартала",
    quarter_name as "Название квартала"
from olap_v2.dim_time
order by id;