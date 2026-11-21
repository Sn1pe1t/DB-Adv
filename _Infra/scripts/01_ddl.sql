DO $$
BEGIN
    CREATE TABLE IF NOT EXISTS dim_time (
        code          int         PRIMARY KEY,
        date_start    date        NOT NULL,
        date_end      date        NOT NULL,
        month_name    varchar(20) NOT NULL,
        year_no       smallint    NOT NULL,
        quarter_no    smallint    NOT NULL,
        quarter_name  varchar(20) NOT NULL
    );

    CREATE TABLE IF NOT EXISTS dim_ranges (
        code    bigint PRIMARY KEY,
        name    text   NOT NULL,
        factor  numeric(18,3)
    );

    CREATE TABLE IF NOT EXISTS dim_category (
        code         bigint PRIMARY KEY,
        name         text   NOT NULL,
        parent_code  bigint
    );

    CREATE TABLE IF NOT EXISTS dim_vendors (
        code        bigint PRIMARY KEY,
        name        text   NOT NULL,
        group_code  bigint,
        group_name  text
    );

    CREATE TABLE IF NOT EXISTS dim_product (
        code           bigint PRIMARY KEY,
        name           text   NOT NULL,
        category_code  bigint,
        category_name  text
    );

    CREATE TABLE IF NOT EXISTS dim_personnel (
        code  bigint PRIMARY KEY,
        name  text   NOT NULL
    );

    CREATE TABLE IF NOT EXISTS dim_storage (
        code  bigint PRIMARY KEY,
        name  text   NOT NULL
    );
END $$;
