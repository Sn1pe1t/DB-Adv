USE Front;
GO

-- 1. Единицы измерения
SELECT ID AS src_code, sizeid AS uom_title, portionrate AS multiplier
FROM dbo.[size];

-- 2. Группы номенклатуры
SELECT id AS src_code, [description] AS group_title, NULLIF(ParentID, 0) AS parent_src_code
FROM dbo.category;

-- 3. Поставщики и группы поставщиков
SELECT v.id AS src_code, v.clientid AS supplier_title,
       v.clientgroup AS parent_group_code, vg.[description] AS parent_group_title
FROM dbo.vendors v
LEFT JOIN dbo.vendorgroup vg ON v.clientgroup = vg.vendorgroupid;

-- 4. Номенклатура
SELECT p.id AS src_code, p.[description] AS item_title,
       p.CategoryID AS group_src_code, p.SizeID AS uom_src_code
FROM dbo.product p;

-- 5. Сотрудники
SELECT personid AS src_code,
       LTRIM(RTRIM(CONCAT(firstname, N' ', lastname))) AS employee_name
FROM dbo.personnel;

-- 6. Склады
SELECT id AS src_code, [description] AS warehouse_title
FROM dbo.storages;

-- 7. Закупки продукции
SELECT o.ID AS doc_line_id,
       CAST(d.Period AS DATE) AS doc_date,
       o.ProductID AS item_src_code,
       o.VendorID AS supplier_src_code,
       o.StorageID AS warehouse_src_code,
       o.[Count] AS qty,
       o.Amount AS total_cost
FROM dbo.bm_StorageOperations o
INNER JOIN dbo.bm_JournalBarnetDocs d ON o.DocumentID = d.ID
WHERE o.OperationID = 1 AND d.DocumentTypeID = 4 AND d.Period IS NOT NULL;

-- 8. Продажа товара
SELECT ID AS sale_line_id,
       CAST(TicketDate AS DATE) AS sale_date,
       TicketNumber AS receipt_no,
       BludoName AS dish_name,
       quantity AS qty,
       price AS unit_price,
       amount AS line_sum
FROM dbo.vw_SalesTicketInfo
WHERE TicketDate IS NOT NULL;

-- 9. Работа персонала
SELECT ID AS shift_id,
       CAST(DateR AS DATE) AS shift_date,
       PersonID AS employee_src_code,
       SystemPeriod AS auto_hours,
       ManualPeriod AS edited_hours
FROM dbo.bm_WorkHours
WHERE DateR IS NOT NULL;

-- 10. Движение остатков
SELECT o.ID AS move_id,
       CAST(d.Period AS DATE) AS move_date,
       o.ProductID AS item_src_code,
       o.StorageID AS warehouse_src_code,
       CASE
           WHEN o.OperationID = 1 THEN ABS(o.[Count])
           WHEN o.OperationID = 2 THEN -ABS(o.[Count])
           ELSE 0
       END AS delta_qty
FROM dbo.bm_StorageOperations o
INNER JOIN dbo.bm_JournalBarnetDocs d ON o.DocumentID = d.ID
WHERE o.OperationID IN (1, 2) AND d.Period IS NOT NULL;

-- 11. Текущие остатки на складах
SELECT CAST(GETDATE() AS DATE) AS snap_date,
       storageid AS warehouse_src_code,
       CAST(productid AS NVARCHAR(100)) AS sku_code,
       onhand AS rem_qty
FROM dbo.storagesonhand;
GO