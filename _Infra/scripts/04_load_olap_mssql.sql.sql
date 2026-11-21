USE Front;
GO

CREATE OR ALTER PROCEDURE olap_analytics.sp_load_resources
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- ==========================================
        -- 1. ЗАГРУЗКА СПРАВОЧНИКОВ (DIMENSIONS)
        -- ==========================================

        -- Единицы измерения
        MERGE olap_analytics.ref_uom AS t
        USING (
            SELECT ID AS src_code, sizeid AS uom_title, portionrate AS multiplier
            FROM dbo.[size]
            WHERE ID IS NOT NULL
        ) AS s
        ON t.src_code = s.src_code
        WHEN MATCHED THEN
            UPDATE SET uom_title = s.uom_title, multiplier = s.multiplier
        WHEN NOT MATCHED THEN
            INSERT (src_code, uom_title, multiplier)
            VALUES (s.src_code, s.uom_title, s.multiplier);

        -- Группы номенклатуры
        MERGE olap_analytics.ref_item_groups AS t
        USING (
            SELECT id AS src_code, [description] AS group_title, NULLIF(ParentID, 0) AS parent_src_code
            FROM dbo.category
            WHERE id IS NOT NULL
        ) AS s
        ON t.src_code = s.src_code
        WHEN MATCHED THEN
            UPDATE SET group_title = s.group_title, parent_src_code = s.parent_src_code
        WHEN NOT MATCHED THEN
            INSERT (src_code, group_title, parent_src_code)
            VALUES (s.src_code, s.group_title, s.parent_src_code);

        -- Поставщики
        MERGE olap_analytics.ref_suppliers AS t
        USING (
            SELECT v.id AS src_code,
                   v.clientid AS supplier_title,
                   v.clientgroup AS parent_group_code,
                   vg.[description] AS parent_group_title
            FROM dbo.vendors v
            LEFT JOIN dbo.vendorgroup vg ON v.clientgroup = vg.vendorgroupid
            WHERE v.id IS NOT NULL
        ) AS s
        ON t.src_code = s.src_code
        WHEN MATCHED THEN
            UPDATE SET supplier_title = s.supplier_title,
                       parent_group_code = s.parent_group_code,
                       parent_group_title = s.parent_group_title
        WHEN NOT MATCHED THEN
            INSERT (src_code, supplier_title, parent_group_code, parent_group_title)
            VALUES (s.src_code, s.supplier_title, s.parent_group_code, s.parent_group_title);

        -- Номенклатура
        MERGE olap_analytics.ref_items AS t
        USING (
            SELECT p.id AS src_code,
                   p.[description] AS item_title,
                   g.group_key,
                   u.uom_key
            FROM dbo.product p
            LEFT JOIN olap_analytics.ref_item_groups g ON p.CategoryID = g.src_code
            LEFT JOIN olap_analytics.ref_uom u ON p.SizeID = u.src_code
            WHERE p.id IS NOT NULL
        ) AS s
        ON t.src_code = s.src_code
        WHEN MATCHED THEN
            UPDATE SET item_title = s.item_title,
                       group_key = s.group_key,
                       uom_key = s.uom_key
        WHEN NOT MATCHED THEN
            INSERT (src_code, item_title, group_key, uom_key)
            VALUES (s.src_code, s.item_title, s.group_key, s.uom_key);

        -- Сотрудники
        MERGE olap_analytics.ref_employees AS t
        USING (
            SELECT personid AS src_code,
                   LTRIM(RTRIM(CONCAT(firstname, N' ', lastname))) AS employee_name
            FROM dbo.personnel
            WHERE personid IS NOT NULL
        ) AS s
        ON t.src_code = s.src_code
        WHEN MATCHED THEN
            UPDATE SET employee_name = s.employee_name
        WHEN NOT MATCHED THEN
            INSERT (src_code, employee_name)
            VALUES (s.src_code, s.employee_name);

        -- Склады
        MERGE olap_analytics.ref_warehouses AS t
        USING (
            SELECT id AS src_code, [description] AS warehouse_title
            FROM dbo.storages
            WHERE id IS NOT NULL
        ) AS s
        ON t.src_code = s.src_code
        WHEN MATCHED THEN
            UPDATE SET warehouse_title = s.warehouse_title
        WHEN NOT MATCHED THEN
            INSERT (src_code, warehouse_title)
            VALUES (s.src_code, s.warehouse_title);

        -- ==========================================
        -- 2. ЗАГРУЗКА ФАКТОВ ПО НАПРАВЛЕНИЯМ (FACTS)
        -- ==========================================

        -- Направление 1: Закупка продукции
        MERGE olap_analytics.fct_procurement AS t
        USING (
            SELECT o.ID AS doc_line_id,
                   cm.period_key,
                   CAST(d.Period AS DATE) AS doc_date,
                   it.item_key,
                   sp.supplier_key,
                   wh.warehouse_key,
                   o.[Count] AS qty,
                   o.Amount AS total_cost
            FROM dbo.bm_StorageOperations o
            INNER JOIN dbo.bm_JournalBarnetDocs d ON o.DocumentID = d.ID
            INNER JOIN olap_analytics.ref_calendar_months cm
                ON cm.period_code = CAST(YEAR(d.Period) AS BIGINT) * 100 + MONTH(d.Period)
            LEFT JOIN olap_analytics.ref_items it ON o.ProductID = it.src_code
            LEFT JOIN olap_analytics.ref_suppliers sp ON o.VendorID = sp.src_code
            LEFT JOIN olap_analytics.ref_warehouses wh ON o.StorageID = wh.src_code
            WHERE o.OperationID = 1
              AND d.DocumentTypeID = 4
              AND d.Period IS NOT NULL
        ) AS s
        ON t.doc_line_id = s.doc_line_id
        WHEN MATCHED THEN
            UPDATE SET period_key = s.period_key, doc_date = s.doc_date,
                       item_key = s.item_key, supplier_key = s.supplier_key,
                       warehouse_key = s.warehouse_key, qty = s.qty, total_cost = s.total_cost
        WHEN NOT MATCHED THEN
            INSERT (doc_line_id, period_key, doc_date, item_key, supplier_key, warehouse_key, qty, total_cost)
            VALUES (s.doc_line_id, s.period_key, s.doc_date, s.item_key, s.supplier_key, s.warehouse_key, s.qty, s.total_cost);

        -- Направление 2: Продажа товара
        MERGE olap_analytics.fct_pos_sales AS t
        USING (
            SELECT sl.ID AS sale_line_id,
                   cm.period_key,
                   CAST(sl.TicketDate AS DATE) AS sale_date,
                   sl.TicketNumber AS receipt_no,
                   sl.BludoName AS dish_name,
                   sl.quantity AS qty,
                   sl.price AS unit_price,
                   sl.amount AS line_sum
            FROM dbo.vw_SalesTicketInfo sl
            INNER JOIN olap_analytics.ref_calendar_months cm
                ON cm.period_code = CAST(YEAR(sl.TicketDate) AS BIGINT) * 100 + MONTH(sl.TicketDate)
            WHERE sl.TicketDate IS NOT NULL
        ) AS s
        ON t.sale_line_id = s.sale_line_id
        WHEN MATCHED THEN
            UPDATE SET period_key = s.period_key, sale_date = s.sale_date,
                       receipt_no = s.receipt_no, dish_name = s.dish_name,
                       qty = s.qty, unit_price = s.unit_price, line_sum = s.line_sum
        WHEN NOT MATCHED THEN
            INSERT (sale_line_id, period_key, sale_date, receipt_no, dish_name, qty, unit_price, line_sum)
            VALUES (s.sale_line_id, s.period_key, s.sale_date, s.receipt_no, s.dish_name, s.qty, s.unit_price, s.line_sum);

        -- Направление 3: Работа персонала
        MERGE olap_analytics.fct_staff_shifts AS t
        USING (
            SELECT w.ID AS shift_id,
                   cm.period_key,
                   CAST(w.DateR AS DATE) AS shift_date,
                   em.employee_key,
                   w.SystemPeriod AS auto_hours,
                   w.ManualPeriod AS edited_hours
            FROM dbo.bm_WorkHours w
            INNER JOIN olap_analytics.ref_calendar_months cm
                ON cm.period_code = CAST(YEAR(w.DateR) AS BIGINT) * 100 + MONTH(w.DateR)
            LEFT JOIN olap_analytics.ref_employees em ON w.PersonID = em.src_code
            WHERE w.DateR IS NOT NULL
        ) AS s
        ON t.shift_id = s.shift_id
        WHEN MATCHED THEN
            UPDATE SET period_key = s.period_key, shift_date = s.shift_date,
                       employee_key = s.employee_key, auto_hours = s.auto_hours,
                       edited_hours = s.edited_hours
        WHEN NOT MATCHED THEN
            INSERT (shift_id, period_key, shift_date, employee_key, auto_hours, edited_hours)
            VALUES (s.shift_id, s.period_key, s.shift_date, s.employee_key, s.auto_hours, s.edited_hours);

        -- Направление 4.1: Движение остатков (с привязкой к понедельнику недели)
        MERGE olap_analytics.fct_stock_ledger AS t
        USING (
            SELECT o.ID AS move_id,
                   DATEADD(DAY, -((DATEPART(WEEKDAY, d.Period) + @@DATEFIRST - 2) % 7), CAST(d.Period AS DATE)) AS week_monday,
                   it.item_key,
                   wh.warehouse_key,
                   CASE
                       WHEN o.OperationID = 1 THEN ABS(o.[Count])
                       WHEN o.OperationID = 2 THEN -ABS(o.[Count])
                       ELSE 0
                   END AS delta_qty
            FROM dbo.bm_StorageOperations o
            INNER JOIN dbo.bm_JournalBarnetDocs d ON o.DocumentID = d.ID
            LEFT JOIN olap_analytics.ref_items it ON o.ProductID = it.src_code
            LEFT JOIN olap_analytics.ref_warehouses wh ON o.StorageID = wh.src_code
            WHERE o.OperationID IN (1, 2)
              AND d.Period IS NOT NULL
        ) AS s
        ON t.move_id = s.move_id
        WHEN MATCHED THEN
            UPDATE SET week_monday = s.week_monday, item_key = s.item_key,
                       warehouse_key = s.warehouse_key, delta_qty = s.delta_qty
        WHEN NOT MATCHED THEN
            INSERT (move_id, week_monday, item_key, warehouse_key, delta_qty)
            VALUES (s.move_id, s.week_monday, s.item_key, s.warehouse_key, s.delta_qty);

        -- Направление 4.2: Текущие остатки на складе
        MERGE olap_analytics.fct_stock_snapshots AS t
        USING (
            SELECT CAST(GETDATE() AS DATE) AS snap_date,
                   wh.warehouse_key,
                   CAST(soh.productid AS NVARCHAR(100)) AS sku_code,
                   SUM(soh.onhand) AS rem_qty
            FROM dbo.storagesonhand soh
            INNER JOIN olap_analytics.ref_warehouses wh ON soh.storageid = wh.src_code
            WHERE soh.productid IS NOT NULL
            GROUP BY wh.warehouse_key, CAST(soh.productid AS NVARCHAR(100))
        ) AS s
        ON t.snap_date = s.snap_date
           AND t.warehouse_key = s.warehouse_key
           AND t.sku_code = s.sku_code
        WHEN MATCHED THEN
            UPDATE SET rem_qty = s.rem_qty
        WHEN NOT MATCHED THEN
            INSERT (snap_date, warehouse_key, sku_code, rem_qty)
            VALUES (s.snap_date, s.warehouse_key, s.sku_code, s.rem_qty);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- Запуск переноса и проверка количества загруженных строк
EXEC olap_analytics.sp_load_resources;
GO

SELECT N'Закупки' AS [Направление], COUNT(*) AS [Записей] FROM olap_analytics.fct_procurement
UNION ALL SELECT N'Продажи', COUNT(*) FROM olap_analytics.fct_pos_sales
UNION ALL SELECT N'Сотрудники', COUNT(*) FROM olap_analytics.ref_employees
UNION ALL SELECT N'Рабочие часы', COUNT(*) FROM olap_analytics.fct_staff_shifts
UNION ALL SELECT N'Движение запасов', COUNT(*) FROM olap_analytics.fct_stock_ledger
UNION ALL SELECT N'Текущие остатки', COUNT(*) FROM olap_analytics.fct_stock_snapshots;
GO