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

-- 1. Scalar Function - محاسبه قیمت با تخفیف + مالیات
IF OBJECT_ID('dbo.fn_LineTotal') IS NOT NULL DROP FUNCTION dbo.fn_LineTotal;
GO
CREATE FUNCTION dbo.fn_LineTotal(@UnitPrice DECIMAL(19,4), @Discount DECIMAL(4,3), @Qty INT)
RETURNS DECIMAL(19,4)
WITH SCHEMABINDING
AS BEGIN
    RETURN @UnitPrice * (1 - @Discount) * @Qty;
END
GO

-- 2. Inline TVF - فروش کامل با تمام جزئیات
IF OBJECT_ID('dbo.fn_SalesDetails') IS NOT NULL DROP FUNCTION dbo.fn_SalesDetails;
GO
CREATE FUNCTION dbo.fn_SalesDetails(@Start DATE, @End DATE)
RETURNS TABLE AS RETURN (
    SELECT 
        h.SalesOrderID, h.OrderDate, h.CustomerID, h.SalesPersonID,
        c.StoreName, c.CustomerType, t.Name AS Territory,
        p.ProductID, p.Name AS ProductName, p.ProductNumber,
        cat.Name AS Category, sub.Name AS Subcategory,
        d.OrderQty, d.UnitPrice, d.UnitPriceDiscount,
        dbo.fn_LineTotal(d.UnitPrice, d.UnitPriceDiscount, d.OrderQty) AS LineTotal
    FROM Sales.SalesOrderHeader h
    JOIN Sales.Customer c ON h.CustomerID = c.CustomerID
    JOIN Sales.SalesTerritory t ON h.TerritoryID = t.TerritoryID
    JOIN Sales.SalesOrderDetail d ON h.SalesOrderID = d.SalesOrderID
    JOIN Production.Product p ON d.ProductID = p.ProductID
    LEFT JOIN Production.ProductSubcategory sub ON p.ProductSubcategoryID = sub.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory cat ON sub.ProductCategoryID = cat.ProductCategoryID
    WHERE h.OrderDate >= @Start AND h.OrderDate < DATEADD(DAY,1,@End)
);
GO

-- 3. Main Master Procedure - 10 بخش + همه JOINها
IF OBJECT_ID('dbo.usp_AW_MasterDemo') IS NOT NULL DROP PROC dbo.usp_AW_MasterDemo;
GO
CREATE PROCEDURE dbo.usp_AW_MasterDemo
    @StartDate DATE = '2013-01-01',
    @EndDate   DATE = '2014-12-31'
AS
BEGIN
    DECLARE @Summary TABLE (Metric NVARCHAR(60), Value SQL_VARIANT);

    IF OBJECT_ID('tempdb..#Report') IS NOT NULL DROP TABLE #Report;
    CREATE TABLE #Report (
        Sec CHAR(3), Title NVARCHAR(100), Key1 NVARCHAR(100), Key2 NVARCHAR(100),
        Qty INT, Sales DECIMAL(19,4), AvgVal DECIMAL(19,4), Cnt INT, JoinType VARCHAR(20)
    );

    BEGIN TRY
        IF @StartDate > @EndDate THROW 50001, 'Invalid date range', 1;

        -- 1. فروش بر اساس دسته‌بندی محصول
        INSERT #Report SELECT '01','By Category',Category,Subcategory,SUM(OrderQty),SUM(LineTotal),AVG(LineTotal),COUNT(*),'INNER'
               FROM dbo.fn_SalesDetails(@StartDate,@EndDate) GROUP BY Category,Subcategory;

        -- 2. ROLLUP - جمع جزء + کل
        INSERT #Report SELECT '02','ROLLUP',ISNULL(Category,'TOTAL'),NULL,SUM(OrderQty),SUM(LineTotal),NULL,COUNT(*),'ROLLUP'
               FROM dbo.fn_SalesDetails(@StartDate,@EndDate) GROUP BY ROLLUP(Category);

        -- 3. CUBE - تمام ترکیب‌ها
        INSERT #Report SELECT '03','CUBE',ISNULL(Territory,'ALL')+'|'+ISNULL(Category,'ALL'),NULL,
               SUM(OrderQty),SUM(LineTotal),NULL,COUNT(*),'CUBE'
               FROM dbo.fn_SalesDetails(@StartDate,@EndDate) GROUP BY CUBE(Territory,Category);

        -- 4. LEFT JOIN - کارمندانی که فروش ندارند
        INSERT #Report SELECT '04','No Sales',FirstName+' '+LastName,NULL,0,0,0,1,'LEFT'
               FROM HumanResources.Employee e
               LEFT JOIN Sales.SalesPerson sp ON e.BusinessEntityID = sp.BusinessEntityID
               WHERE sp.BusinessEntityID IS NULL;

        -- 5. RIGHT JOIN - محصولاتی که هیچ‌وقت فروخته نشدند
        INSERT #Report SELECT '05','Never Sold',p.Name,NULL,0,0,p.ListPrice,1,'RIGHT'
               FROM Production.Product p
               LEFT JOIN Sales.SalesOrderDetail d ON p.ProductID = d.ProductID
               WHERE d.ProductID IS NULL;

        -- 6. FULL OUTER - تامین‌کننده و محصول (حتی بدون ارتباط)
        INSERT #Report SELECT '06','Vendor-Product',ISNULL(v.Name,'No Vendor'),ISNULL(p.Name,'No Product'),
               0,0,NULL,COUNT(*),'FULL'
               FROM Purchasing.Vendor v
               FULL OUTER JOIN Purchasing.ProductVendor pv ON v.BusinessEntityID = pv.BusinessEntityID
               FULL OUTER JOIN Production.Product p ON pv.ProductID = p.ProductID
               GROUP BY v.Name, p.Name;

        -- 7. CROSS JOIN - پتانسیل فروش (فروشنده × منطقه)
        INSERT #Report SELECT TOP 20 '07','Sales Potential',
               e.FirstName+' '+e.LastName,t.Name,NULL,NULL,NULL,1,'CROSS'
               FROM (SELECT TOP 5 BusinessEntityID,FirstName,LastName FROM Person.Person WHERE BusinessEntityID IN (SELECT BusinessEntityID FROM Sales.SalesPerson)) e
               CROSS JOIN (SELECT TOP 5 Name FROM Sales.SalesTerritory) t;

        -- 8. GROUP BY با HAVING - فقط مناطق بالای 1 میلیون فروش
        INSERT #Report SELECT '08','High Sales Territories',Territory,NULL,
               SUM(OrderQty),SUM(LineTotal),NULL,COUNT(*),'HAVING'
               FROM dbo.fn_SalesDetails(@StartDate,@EndDate)
               GROUP BY Territory HAVING SUM(LineTotal) > 1000000;

        -- 9. GROUPING SETS - چند گروه‌بندی همزمان
        INSERT #Report SELECT '09','GROUPING SETS',ISNULL(Category,'ALL'),ISNULL(Territory,'ALL'),
               SUM(OrderQty),SUM(LineTotal),NULL,COUNT(*),'GROUPING SETS'
               FROM dbo.fn_SalesDetails(@StartDate,@EndDate)
               GROUP BY GROUPING SETS ( (Category), (Territory), () );

        -- 10. بهترین فروشنده هر منطقه
        INSERT #Report SELECT TOP 10 '10','Top SalesPerson',t.Name, p.FirstName+' '+p.LastName,
               NULL,SUM(d.LineTotal),NULL,COUNT(*),'WINDOW/RANK'
               FROM Sales.SalesOrderHeader h
               JOIN Sales.SalesOrderDetail d ON h.SalesOrderID = d.SalesOrderID
               JOIN Sales.SalesTerritory t ON h.TerritoryID = t.TerritoryID
               JOIN Person.Person p ON h.SalesPersonID = p.BusinessEntityID
               WHERE h.OrderDate >= @StartDate AND h.OrderDate < DATEADD(DAY,1,@EndDate)
               GROUP BY t.Name, p.FirstName, p.LastName;

        -- خلاصه نهایی
        INSERT @Summary VALUES
            ('Total Revenue', (SELECT SUM(LineTotal) FROM dbo.fn_SalesDetails(@StartDate,@EndDate))),
            ('Total Orders', (SELECT COUNT(DISTINCT SalesOrderID) FROM Sales.SalesOrderHeader WHERE OrderDate >= @StartDate AND OrderDate < DATEADD(DAY,1,@EndDate))),
            ('Active Products', (SELECT COUNT(*) FROM Production.Product WHERE SellEndDate IS NULL)),
            ('Avg Order Value', (SELECT AVG(TotalDue) FROM Sales.SalesOrderHeader WHERE OrderDate >= @StartDate AND OrderDate < DATEADD(DAY,1,@EndDate)));

        SELECT * FROM #Report ORDER BY Sec, Sales DESC;
        SELECT Metric, Value FROM @Summary;

    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#Report') IS NOT NULL
            INSERT #Report VALUES ('ERR','ERROR OCCURRED',ERROR_MESSAGE(),NULL,NULL,NULL,NULL,1,'TRY/CATCH');
        THROW;
    END CATCH
END
GO

-- اجرا
EXEC dbo.usp_AW_MasterDemo '2013-01-01', '2014-12-31';

