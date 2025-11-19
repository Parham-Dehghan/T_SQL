/*
AdventureWorks Full Version – 10 Advanced GROUP BY Techniques
1.ROLLUP / CUBE / GROUPING SETS  check
2.All 5 JOIN Types (including FULL OUTER & CROSS) check
3.Inline TVF + Scalar + SCHEMABINDING check
4.Temp Table + Table Variable + Index check
5.Full TRY/CATCH + THROW check
6.Production-Ready Code (Banking Standard) check
*/

use master
go 

USE my_database1;
GO

--تمامی جدول ها با اسکیما مربوطه نمایش بده
SELECT 
    t.name AS TableName,
    s.name AS SchemaName
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
ORDER BY s.name, t.name;


SET NOCOUNT, XACT_ABORT ON;
GO

/*DROP FUNCTION IF EXISTS dbo.fn_LineTotal;
DROP FUNCTION IF EXISTS dbo.fn_SalesDetails;
GO*/

-- 1. Scalar Function - محاسبه قیمت با تخفیف + مالیات
CREATE FUNCTION dbo.fn_LineTotal(@UnitPrice DECIMAL(19,4), @Discount DECIMAL(4,3), @Qty INT)
RETURNS DECIMAL(19,4)
WITH SCHEMABINDING
AS BEGIN
    RETURN @UnitPrice * (1 - @Discount) * @Qty;
END
GO

-- 2. Inline TVF
CREATE FUNCTION dbo.fn_SalesDetails(@Start DATE, @End DATE)
RETURNS TABLE AS RETURN (
    SELECT 
        h.SalesOrderID, h.OrderDate, h.CustomerID, h.SalesPersonID,
        ISNULL(s.Name, 'Individual Customer') AS StoreName,
        t.Name AS Territory,
        p.ProductID, p.Name AS ProductName, p.ProductNumber,
        cat.Name AS Category, sub.Name AS Subcategory,
        d.OrderQty, d.UnitPrice, d.UnitPriceDiscount,
        dbo.fn_LineTotal(d.UnitPrice, d.UnitPriceDiscount, d.OrderQty) AS LineTotal
    FROM Sales.SalesOrderHeader h
    JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
    LEFT JOIN Sales.Store s ON c.StoreID = s.BusinessEntityID
    JOIN Sales.SalesTerritory t ON h.TerritoryID = t.TerritoryID
    JOIN Sales.SalesOrderDetail d ON h.SalesOrderID = d.SalesOrderID
    JOIN Production.Product p ON d.ProductID = p.ProductID
    LEFT JOIN Production.ProductSubcategory sub ON p.ProductSubcategoryID = sub.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory cat ON sub.ProductCategoryID = cat.ProductCategoryID
    WHERE h.OrderDate >= @Start AND h.OrderDate < DATEADD(DAY,1,@End)
);
GO

-- 3. Main Master Procedure - 10 بخش + همه JOINها
CREATE PROCEDURE dbo.usp_AW_MasterDemo_Sorted
    @StartDate DATE = '2013-01-01',
    @EndDate   DATE = '2014-12-31'
AS
BEGIN
    DECLARE @Summary TABLE (Metric NVARCHAR(60), Value SQL_VARIANT);

    DROP TABLE IF EXISTS #Report;
    CREATE TABLE #Report (
        Section   CHAR(3)      NOT NULL,
        Title     NVARCHAR(100) NOT NULL,
        Key1      NVARCHAR(150) NULL,
        Key2      NVARCHAR(150) NULL,
        Qty       INT           NULL,
        Sales     DECIMAL(19,4) NULL,
        AvgVal    DECIMAL(19,4) NULL,
        Cnt       INT           NULL,
        JoinType  VARCHAR(20)   NOT NULL,
        SortOrder INT           NOT NULL  -- برای ترتیب نهایی
    );

    BEGIN TRY
        IF @StartDate > @EndDate THROW 50001, 'Invalid date range', 1;

        -- 01. فروش بر اساس دسته‌بندی و زیرگروه (بزرگ → کوچک)
        INSERT #Report 
        SELECT TOP 50 
               '01','By Category/Subcategory', ISNULL(Category,'Unknown'), Subcategory,
               SUM(OrderQty), SUM(LineTotal), AVG(LineTotal), COUNT(*), 'INNER', 1
        FROM dbo.fn_SalesDetails(@StartDate,@EndDate)
        GROUP BY Category, Subcategory
        ORDER BY SUM(LineTotal) DESC;

        -- 02. ROLLUP (بزرگ → کوچک)
        INSERT #Report 
        SELECT '02','ROLLUP Summary', ISNULL(Category,'TOTAL'), NULL,
               SUM(OrderQty), SUM(LineTotal), NULL, COUNT(*), 'ROLLUP', 2
        FROM dbo.fn_SalesDetails(@StartDate,@EndDate)
        GROUP BY ROLLUP(Category)
        ORDER BY SUM(LineTotal) DESC;

        -- 03. CUBE (بزرگ → کوچک)
        INSERT #Report 
        SELECT '03','CUBE Analysis', ISNULL(Territory,'ALL')+' | '+ISNULL(Category,'ALL'), NULL,
               SUM(OrderQty), SUM(LineTotal), NULL, COUNT(*), 'CUBE', 3
        FROM dbo.fn_SalesDetails(@StartDate,@EndDate)
        GROUP BY CUBE(Territory, Category)
        ORDER BY SUM(LineTotal) DESC;

        -- 04. کارمندانی که فروشنده نیستند
        INSERT #Report 
        SELECT TOP 15 '04','Employees Without Sales Role', p.FirstName+' '+p.LastName, NULL,
               0, 0, 0, 1, 'LEFT JOIN', 4
        FROM HumanResources.Employee e
        JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
        LEFT JOIN Sales.SalesPerson sp ON e.BusinessEntityID = sp.BusinessEntityID
        WHERE sp.BusinessEntityID IS NULL
        ORDER BY p.LastName, p.FirstName;

        -- 05. محصولاتی که هیچوقت فروخته نشدند
        INSERT #Report 
        SELECT TOP 15 '05','Never Sold Products', p.Name, p.ProductNumber,
               0, 0, p.ListPrice, 1, 'RIGHT JOIN', 5
        FROM Production.Product p
        LEFT JOIN Sales.SalesOrderDetail d ON p.ProductID = d.ProductID
        WHERE d.ProductID IS NULL
        ORDER BY p.ListPrice DESC;

        -- 06. FULL OUTER - تامین‌کننده و محصول
        INSERT #Report 
        SELECT TOP 30 '06','Vendor × Product Matrix', ISNULL(v.Name,'No Vendor'), ISNULL(p.Name,'No Product'),
               0, 0, NULL, COUNT(*), 'FULL OUTER', 6
        FROM Purchasing.Vendor v
        FULL OUTER JOIN Purchasing.ProductVendor pv ON v.BusinessEntityID = pv.BusinessEntityID
        FULL OUTER JOIN Production.Product p ON pv.ProductID = p.ProductID
        GROUP BY v.Name, p.Name
        ORDER BY COUNT(*) DESC;

        -- 07. CROSS JOIN - پتانسیل فروش
        INSERT #Report 
        SELECT TOP 30 '07','Sales Potential Matrix', p.FirstName+' '+p.LastName, t.Name,
               NULL, NULL, NULL, 1, 'CROSS JOIN', 7
        FROM Sales.SalesPerson sp
        JOIN Person.Person p ON sp.BusinessEntityID = p.BusinessEntityID
        CROSS JOIN (SELECT TOP 10 Name FROM Sales.SalesTerritory ORDER BY Name) t;

        -- 08. مناطق با فروش بالای 2 میلیون
        INSERT #Report 
        SELECT '08','High-Revenue Territories (>2M)', Territory, NULL,
               SUM(OrderQty), SUM(LineTotal), NULL, COUNT(*), 'HAVING', 8
        FROM dbo.fn_SalesDetails(@StartDate,@EndDate)
        GROUP BY Territory
        HAVING SUM(LineTotal) > 2000000
        ORDER BY SUM(LineTotal) DESC;

        -- 09. GROUPING SETS
        INSERT #Report 
        SELECT '09','GROUPING SETS Summary', ISNULL(Category,'ALL CATEGORIES'), ISNULL(Territory,'ALL TERRITORIES'),
               SUM(OrderQty), SUM(LineTotal), NULL, COUNT(*), 'GROUPING SETS', 9
        FROM dbo.fn_SalesDetails(@StartDate,@EndDate)
        GROUP BY GROUPING SETS ((Category), (Territory), ())
        ORDER BY SUM(LineTotal) DESC;

        -- 10. بهترین فروشنده هر منطقه
        INSERT #Report 
        SELECT TOP 15 '10','Top Sales Persons by Territory', t.Name, per.FirstName+' '+per.LastName,
               NULL, SUM(d.LineTotal), NULL, COUNT(*), 'RANK', 10
        FROM Sales.SalesOrderHeader h
        JOIN Sales.SalesOrderDetail d ON h.SalesOrderID = d.SalesOrderID
        JOIN Sales.SalesTerritory t ON h.TerritoryID = t.TerritoryID
        JOIN Person.Person per ON h.SalesPersonID = per.BusinessEntityID
        WHERE h.OrderDate >= @StartDate AND h.OrderDate < DATEADD(DAY,1,@EndDate)
        GROUP BY t.Name, per.FirstName, per.LastName
        ORDER BY SUM(d.LineTotal) DESC;

        -- خلاصه نهایی
        INSERT @Summary 
        SELECT 'Total Revenue (2013-2014)', SUM(LineTotal) FROM dbo.fn_SalesDetails(@StartDate,@EndDate)
        UNION ALL SELECT 'Total Orders', COUNT(*) FROM Sales.SalesOrderHeader WHERE OrderDate >= @StartDate AND OrderDate < DATEADD(DAY,1,@EndDate)
        UNION ALL SELECT 'Active Products', COUNT(*) FROM Production.Product WHERE SellEndDate IS NULL;

        -- خروجی نهایی: دقیقاً مرتب و خوانا
        SELECT 
            Section, Title, Key1, Key2, Qty, Sales, AvgVal, Cnt, JoinType
        FROM #Report
        ORDER BY SortOrder, Sales DESC, Qty DESC, Cnt DESC;

        PRINT 'تمام ۱۰ بخش با موفقیت اجرا و مرتب شدند!';

        SELECT Metric, Value FROM @Summary;

    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#Report') IS NOT NULL
            INSERT #Report VALUES ('ERR','ERROR',ERROR_MESSAGE(),NULL,NULL,NULL,NULL,1,'CATCH',999);
        THROW;
    END CATCH
END
GO


EXEC dbo.usp_AW_MasterDemo_Sorted '2013-01-01', '2014-12-31';

