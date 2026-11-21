do $$
begin
    create schema if not exists olap_v2;

    create sequence if not exists olap_v2.seq_ranges;
    create sequence if not exists olap_v2.seq_categories;
    create sequence if not exists olap_v2.seq_vendor_groups;
    create sequence if not exists olap_v2.seq_vendors;
    create sequence if not exists olap_v2.seq_products;
    create sequence if not exists olap_v2.seq_personnel;
    create sequence if not exists olap_v2.seq_storages;
    create sequence if not exists olap_v2.seq_time;

    create table if not exists olap_v2.dim_ranges (
        id bigint primary key default nextval('olap_v2.seq_ranges'),
        external_id bigint unique,
        name text,
        factor numeric,
        date_add timestamp default now()
    );

    create table if not exists olap_v2.dim_categories (
        id bigint primary key default nextval('olap_v2.seq_categories'),
        external_id bigint unique,
        name text,
        parent_external_id bigint,
        date_add timestamp default now()
    );

    create table if not exists olap_v2.dim_vendor_groups (
        id bigint primary key default nextval('olap_v2.seq_vendor_groups'),
        external_id bigint unique,
        name text,
        date_add timestamp default now()
    );

    create table if not exists olap_v2.dim_vendors (
        id bigint primary key default nextval('olap_v2.seq_vendors'),
        external_id bigint unique,
        name text,
        group_id bigint references olap_v2.dim_vendor_groups(id),
        date_add timestamp default now()
    );

    create table if not exists olap_v2.dim_products (
        id bigint primary key default nextval('olap_v2.seq_products'),
        external_id bigint unique,
        name text,
        category_id bigint references olap_v2.dim_categories(id),
        vendor_id bigint references olap_v2.dim_vendors(id),
        range_id bigint references olap_v2.dim_ranges(id),
        date_add timestamp default now()
    );

    create table if not exists olap_v2.dim_personnel (
        id bigint primary key default nextval('olap_v2.seq_personnel'),
        external_id bigint unique,
        name text,
        date_add timestamp default now()
    );

    create table if not exists olap_v2.dim_storages (
        id bigint primary key default nextval('olap_v2.seq_storages'),
        external_id bigint unique,
        name text,
        date_add timestamp default now()
    );

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

    -- Факты: закупка продукции
    create table if not exists olap_v2.fact_purchases (
        source_id bigint primary key,
        time_id bigint references olap_v2.dim_time(id),
        product_id bigint references olap_v2.dim_products(id),
        vendor_id bigint references olap_v2.dim_vendors(id),
        storage_id bigint references olap_v2.dim_storages(id),
        quantity numeric,
        amount numeric
    );

    -- Факты: продажа товара
    create table if not exists olap_v2.fact_sales (
        source_id bigint primary key,
        time_id bigint references olap_v2.dim_time(id),
        ticket_number numeric,
        product_name text,
        quantity numeric,
        price numeric,
        amount numeric
    );

    -- Факты: работа персонала
    create table if not exists olap_v2.fact_work_hours (
        source_id bigint primary key,
        time_id bigint references olap_v2.dim_time(id),
        person_id bigint references olap_v2.dim_personnel(id),
        system_period double precision,
        manual_period double precision
    );

    -- Факты: остатки (движение и фактические остатки)
    create table if not exists olap_v2.fact_stock_moves (
        source_id bigint primary key,
        week_start date,
        product_id bigint references olap_v2.dim_products(id),
        storage_id bigint references olap_v2.dim_storages(id),
        quantity_change numeric
    );

    create table if not exists olap_v2.fact_stock_balance (
        snapshot_date date,
        storage_id bigint references olap_v2.dim_storages(id),
        product_code text,
        onhand numeric,
        primary key (snapshot_date, storage_id, product_code)
    );
end $$;