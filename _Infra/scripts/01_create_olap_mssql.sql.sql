USE Front;
GO

IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = N'olap_analytics')
    EXEC(N'CREATE SCHEMA olap_analytics');
GO

-- ==========================================
-- 1. СПРАВОЧНИКИ / ИЗМЕРЕНИЯ (DIMENSIONS)
-- ==========================================

IF OBJECT_ID(N'olap_analytics.ref_uom', N'U') IS NULL
CREATE TABLE olap_analytics.ref_uom (
    uom_key     BIGINT IDENTITY(1,1) PRIMARY KEY,
    src_code    BIGINT UNIQUE,
    uom_title   NVARCHAR(255),
    multiplier  DECIMAL(18, 4),
    created_at  DATETIME2 DEFAULT SYSDATETIME()
);
GO

IF OBJECT_ID(N'olap_analytics.ref_item_groups', N'U') IS NULL
CREATE TABLE olap_analytics.ref_item_groups (
    group_key       BIGINT IDENTITY(1,1) PRIMARY KEY,
    src_code        BIGINT UNIQUE,
    group_title     NVARCHAR(255),
    parent_src_code BIGINT NULL,
    created_at      DATETIME2 DEFAULT SYSDATETIME()
);
GO

IF OBJECT_ID(N'olap_analytics.ref_suppliers', N'U') IS NULL
CREATE TABLE olap_analytics.ref_suppliers (
    supplier_key       BIGINT IDENTITY(1,1) PRIMARY KEY,
    src_code           BIGINT UNIQUE,
    supplier_title     NVARCHAR(255),
    parent_group_code  BIGINT NULL,
    parent_group_title NVARCHAR(255),
    created_at         DATETIME2 DEFAULT SYSDATETIME()
);
GO

IF OBJECT_ID(N'olap_analytics.ref_items', N'U') IS NULL
CREATE TABLE olap_analytics.ref_items (
    item_key    BIGINT IDENTITY(1,1) PRIMARY KEY,
    src_code    BIGINT UNIQUE,
    item_title  NVARCHAR(255),
    group_key   BIGINT NULL REFERENCES olap_analytics.ref_item_groups(group_key),
    uom_key     BIGINT NULL REFERENCES olap_analytics.ref_uom(uom_key),
    created_at  DATETIME2 DEFAULT SYSDATETIME()
);
GO

IF OBJECT_ID(N'olap_analytics.ref_employees', N'U') IS NULL
CREATE TABLE olap_analytics.ref_employees (
    employee_key  BIGINT IDENTITY(1,1) PRIMARY KEY,
    src_code      BIGINT UNIQUE,
    employee_name NVARCHAR(255),
    created_at    DATETIME2 DEFAULT SYSDATETIME()
);
GO

IF OBJECT_ID(N'olap_analytics.ref_warehouses', N'U') IS NULL
CREATE TABLE olap_analytics.ref_warehouses (
    warehouse_key   BIGINT IDENTITY(1,1) PRIMARY KEY,
    src_code        BIGINT UNIQUE,
    warehouse_title NVARCHAR(255),
    created_at      DATETIME2 DEFAULT SYSDATETIME()
);
GO

-- Метрика ВРЕМЯ (7 полей по ТЗ + период-код YYYYMM)
IF OBJECT_ID(N'olap_analytics.ref_calendar_months', N'U') IS NULL
CREATE TABLE olap_analytics.ref_calendar_months (
    period_key   BIGINT IDENTITY(1,1) PRIMARY KEY, -- Код
    period_code  BIGINT UNIQUE,
    date_start   DATE,                             -- Дата начала месяца
    date_end     DATE,                             -- Дата окончания месяца
    month_name   NVARCHAR(50),                     -- Название месяца
    [year]       INT,                              -- Год
    quarter_num  INT,                              -- Номер квартала
    quarter_name NVARCHAR(50)                      -- Название квартала
);
GO

-- ==========================================
-- 2. ТАБЛИЦЫ ФАКТОВ ПО НАПРАВЛЕНИЯМ (FACTS)
-- ==========================================

-- 1. Анализ закупки продукции
IF OBJECT_ID(N'olap_analytics.fct_procurement', N'U') IS NULL
CREATE TABLE olap_analytics.fct_procurement (
    doc_line_id   BIGINT PRIMARY KEY,
    period_key    BIGINT NULL REFERENCES olap_analytics.ref_calendar_months(period_key),
    doc_date      DATE,
    item_key      BIGINT NULL REFERENCES olap_analytics.ref_items(item_key),
    supplier_key  BIGINT NULL REFERENCES olap_analytics.ref_suppliers(supplier_key),
    warehouse_key BIGINT NULL REFERENCES olap_analytics.ref_warehouses(warehouse_key),
    qty           DECIMAL(18, 4),
    total_cost    DECIMAL(18, 2)
);
GO

-- 2. Анализ продажи товара
IF OBJECT_ID(N'olap_analytics.fct_pos_sales', N'U') IS NULL
CREATE TABLE olap_analytics.fct_pos_sales (
    sale_line_id BIGINT PRIMARY KEY,
    period_key   BIGINT NULL REFERENCES olap_analytics.ref_calendar_months(period_key),
    sale_date    DATE,
    receipt_no   DECIMAL(18, 0),
    dish_name    NVARCHAR(255),
    qty          DECIMAL(18, 4),
    unit_price   DECIMAL(18, 2),
    line_sum     DECIMAL(18, 2)
);
GO

-- 3. Анализ работы персонала
IF OBJECT_ID(N'olap_analytics.fct_staff_shifts', N'U') IS NULL
CREATE TABLE olap_analytics.fct_staff_shifts (
    shift_id     BIGINT PRIMARY KEY,
    period_key   BIGINT NULL REFERENCES olap_analytics.ref_calendar_months(period_key),
    shift_date   DATE,
    employee_key BIGINT NULL REFERENCES olap_analytics.ref_employees(employee_key),
    auto_hours   FLOAT,
    edited_hours FLOAT
);
GO

-- 4. Анализ остатков (движение по неделям + срезы)
IF OBJECT_ID(N'olap_analytics.fct_stock_ledger', N'U') IS NULL
CREATE TABLE olap_analytics.fct_stock_ledger (
    move_id       BIGINT PRIMARY KEY,
    week_monday   DATE,
    item_key      BIGINT NULL REFERENCES olap_analytics.ref_items(item_key),
    warehouse_key BIGINT NULL REFERENCES olap_analytics.ref_warehouses(warehouse_key),
    delta_qty     DECIMAL(18, 4)
);
GO

IF OBJECT_ID(N'olap_analytics.fct_stock_snapshots', N'U') IS NULL
CREATE TABLE olap_analytics.fct_stock_snapshots (
    snap_date     DATE NOT NULL,
    warehouse_key BIGINT NOT NULL REFERENCES olap_analytics.ref_warehouses(warehouse_key),
    sku_code      NVARCHAR(100) NOT NULL,
    rem_qty       DECIMAL(18, 4),
    CONSTRAINT PK_fct_stock_snapshots PRIMARY KEY (snap_date, warehouse_key, sku_code)
);
GO