do $$
begin
    -- Справочники
    insert into olap_v2.dim_ranges (external_id, name, factor) values
        (1, 'порция', 1.000),
        (42, 'кг', 1000.000),
        (69, 'шт', 1.000)
    on conflict (external_id) do update
        set name = excluded.name, factor = excluded.factor;

    insert into olap_v2.dim_categories (external_id, name, parent_external_id) values
        (147, 'Меню доставка', null),
        (149, 'Склад', null),
        (200, 'Овощи фрукты', 199)
    on conflict (external_id) do update
        set name = excluded.name, parent_external_id = excluded.parent_external_id;

    insert into olap_v2.dim_vendor_groups (external_id, name) values
        (31, 'Поставщики')
    on conflict (external_id) do update
        set name = excluded.name;

    insert into olap_v2.dim_vendors (external_id, name, group_id)
    select 107, 'Овощи', g.id
    from olap_v2.dim_vendor_groups g where g.external_id = 31
    on conflict (external_id) do update
        set name = excluded.name, group_id = excluded.group_id;

    insert into olap_v2.dim_products (external_id, name, category_id, vendor_id, range_id)
    select 4339, 'Лимоны', c.id, v.id, r.id
    from olap_v2.dim_categories c, olap_v2.dim_vendors v, olap_v2.dim_ranges r
    where c.external_id = 200 and v.external_id = 107 and r.external_id = 42
    on conflict (external_id) do update
        set name = excluded.name, category_id = excluded.category_id,
            vendor_id = excluded.vendor_id, range_id = excluded.range_id;

    insert into olap_v2.dim_personnel (external_id, name) values
        (898, 'Татьяна Безик'),
        (904, 'Касса 1')
    on conflict (external_id) do update
        set name = excluded.name;

    insert into olap_v2.dim_storages (external_id, name) values
        (1, 'Основной склад')
    on conflict (external_id) do update
        set name = excluded.name;

    -- Факты закупок
    insert into olap_v2.fact_purchases (source_id, time_id, product_id, vendor_id, storage_id, quantity, amount)
    select 1001, t.id, p.id, v.id, s.id, 15.5000, 2170.00
    from olap_v2.dim_time t
    left join olap_v2.dim_products p on p.external_id = 4339
    left join olap_v2.dim_vendors v on v.external_id = 107
    left join olap_v2.dim_storages s on s.external_id = 1
    where t.external_id = 202601
    on conflict (source_id) do update
        set time_id = excluded.time_id, product_id = excluded.product_id,
            vendor_id = excluded.vendor_id, storage_id = excluded.storage_id,
            quantity = excluded.quantity, amount = excluded.amount;

    -- Факты продаж
    insert into olap_v2.fact_sales (source_id, time_id, ticket_number, product_name, quantity, price, amount)
    select 2001, t.id, 50012, 'Лимоны', 2.0000, 250.00, 500.00
    from olap_v2.dim_time t
    where t.external_id = 202601
    on conflict (source_id) do update
        set time_id = excluded.time_id, ticket_number = excluded.ticket_number,
            product_name = excluded.product_name, quantity = excluded.quantity,
            price = excluded.price, amount = excluded.amount;

    -- Факты работы персонала
    insert into olap_v2.fact_work_hours (source_id, time_id, person_id, system_period, manual_period)
    select 3001, t.id, pe.id, 8.0, 8.0
    from olap_v2.dim_time t
    left join olap_v2.dim_personnel pe on pe.external_id = 898
    where t.external_id = 202601
    on conflict (source_id) do update
        set time_id = excluded.time_id, person_id = excluded.person_id,
            system_period = excluded.system_period, manual_period = excluded.manual_period;

    -- Факты остатков: движение
    insert into olap_v2.fact_stock_moves (source_id, week_start, product_id, storage_id, quantity_change)
    select 4001,
           date '2026-01-15' - (extract(isodow from date '2026-01-15')::integer - 1),
           p.id, s.id, 15.5000
    from olap_v2.dim_products p, olap_v2.dim_storages s
    where p.external_id = 4339 and s.external_id = 1
    on conflict (source_id) do update
        set week_start = excluded.week_start, product_id = excluded.product_id,
            storage_id = excluded.storage_id, quantity_change = excluded.quantity_change;

    -- Факты остатков: баланс
    insert into olap_v2.fact_stock_balance (snapshot_date, storage_id, product_code, onhand)
    select date '2026-01-31', s.id, '4339', 8.3000
    from olap_v2.dim_storages s
    where s.external_id = 1
    on conflict (snapshot_date, storage_id, product_code) do update
        set onhand = excluded.onhand;
end $$;