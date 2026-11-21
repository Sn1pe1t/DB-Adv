WITH src AS (
    SELECT id AS code, sizeid AS name, portionrate AS factor
    FROM size
)
SELECT 'INSERT INTO dim_ranges (code, name, factor) VALUES' + CHAR(10)
     + STRING_AGG(CAST(CONCAT('    (', code, ', ', ISNULL(QUOTENAME(name, ''''), 'NULL'), ', ', ISNULL(CAST(factor AS varchar(30)), 'NULL'), ')') AS nvarchar(max)), ',' + CHAR(10))
     + ';' AS sql_text
FROM src;


WITH src AS (
    SELECT id AS code, description AS name, NULLIF(ParentID, 0) AS parent_code
    FROM category
)
SELECT 'INSERT INTO dim_category (code, name, parent_code) VALUES' + CHAR(10)
     + STRING_AGG(CAST(CONCAT('    (', code, ', ', ISNULL(QUOTENAME(name, ''''), 'NULL'), ', ', ISNULL(CAST(parent_code AS varchar(20)), 'NULL'), ')') AS nvarchar(max)), ',' + CHAR(10))
     + ';' AS sql_text
FROM src;


WITH src AS (
    SELECT v.id AS code, v.clientid AS name, v.clientgroup AS group_code, g.description AS group_name
    FROM vendors v
    LEFT JOIN vendorgroup g ON g.vendorgroupid = v.clientgroup
)
SELECT 'INSERT INTO dim_vendors (code, name, group_code, group_name) VALUES' + CHAR(10)
     + STRING_AGG(CAST(CONCAT('    (', code, ', ', ISNULL(QUOTENAME(name, ''''), 'NULL'), ', ', ISNULL(CAST(group_code AS varchar(20)), 'NULL'), ', ', ISNULL(QUOTENAME(group_name, ''''), 'NULL'), ')') AS nvarchar(max)), ',' + CHAR(10))
     + ';' AS sql_text
FROM src;


WITH src AS (
    SELECT p.id AS code, p.description AS name, p.CategoryID AS category_code, c.description AS category_name
    FROM product p
    LEFT JOIN category c ON c.id = p.CategoryID
)
SELECT 'INSERT INTO dim_product (code, name, category_code, category_name) VALUES' + CHAR(10)
     + STRING_AGG(CAST(CONCAT('    (', code, ', ', ISNULL(QUOTENAME(name, ''''), 'NULL'), ', ', ISNULL(CAST(category_code AS varchar(20)), 'NULL'), ', ', ISNULL(QUOTENAME(category_name, ''''), 'NULL'), ')') AS nvarchar(max)), ',' + CHAR(10))
     + ';' AS sql_text
FROM src;


WITH src AS (
    SELECT personid AS code, LTRIM(RTRIM(CONCAT_WS(' ', lastname, firstname, middlename))) AS name
    FROM personnel
)
SELECT 'INSERT INTO dim_personnel (code, name) VALUES' + CHAR(10)
     + STRING_AGG(CAST(CONCAT('    (', code, ', ', ISNULL(QUOTENAME(name, ''''), 'NULL'), ')') AS nvarchar(max)), ',' + CHAR(10))
     + ';' AS sql_text
FROM src;


WITH src AS (
    SELECT id AS code, description AS name
    FROM storage
)
SELECT 'INSERT INTO dim_storage (code, name) VALUES' + CHAR(10)
     + STRING_AGG(CAST(CONCAT('    (', code, ', ', ISNULL(QUOTENAME(name, ''''), 'NULL'), ')') AS nvarchar(max)), ',' + CHAR(10))
     + ';' AS sql_text
FROM src;
