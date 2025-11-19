use master
go 

USE my_database1;
GO
SET NOCOUNT, XACT_ABORT ON;
GO

USE AdventureWorksLT;
GO
SET NOCOUNT, XACT_ABORT ON;
GO

-- 1. Scalar Function
IF OBJECT_ID('dbo.fn_NetPrice') IS NOT NULL DROP FUNCTION dbo.fn_NetPrice;
GO
CREATE FUNCTION dbo.fn_NetPrice(@Price DECIMAL(19,4), @Discount DECIMAL(19,4))
RETURNS DECIMAL(19,4)
WITH SCHEMABINDING
AS BEGIN
    RETURN @Price * (1 - @Discount);
END
GO

-- 2. Inline TVF
IF OBJECT_ID('dbo.fn_Sales') IS NOT NULL DROP FUNCTION dbo.fn_Sales;
GO
CREATE FUNCTION dbo.fn_Sales(@Start DATE, @End DATE)
RETURNS TABLE AS RETURN (
    SELECT 
        h.SalesOrderID, h.OrderDate, h.CustomerID,
        c.CompanyName, p.ProductID, p.Name ProductName,
        pc.Name CategoryName, d.OrderQty, d.UnitPrice,
        d.UnitPriceDiscount, dbo.fn_NetPrice(d.UnitPrice, d.UnitPriceDiscount) NetPrice,
        d.OrderQty * dbo.fn_NetPrice(d.UnitPrice, d.UnitPriceDiscount) LineTotal
    FROM SalesLT.SalesOrderHeader h
    JOIN SalesLT.Customer c ON h.CustomerID = c.CustomerID
    JOIN SalesLT.SalesOrderDetail d ON h.SalesOrderID = d.SalesOrderID
    JOIN SalesLT.Product p ON d.ProductID = p.ProductID
    LEFT JOIN SalesLT.ProductCategory pc ON p.ProductCategoryID = pc.ProductCategoryID
    WHERE h.OrderDate >= @Start AND h.OrderDate < DATEADD(DAY,1,@End)
);
GO

-- 3. Main Procedure
IF OBJECT_ID('dbo.usp_AdvancedDemo') IS NOT NULL DROP PROC dbo.usp_AdvancedDemo;
GO
CREATE PROCEDURE dbo.usp_AdvancedDemo
    @StartDate DATE = '2013-01-01',
    @EndDate   DATE = '2014-12-31'
AS
BEGIN
    DECLARE @Summary TABLE (Metric NVARCHAR(50), Value SQL_VARIANT);

    IF OBJECT_ID('tempdb..#R') IS NOT NULL DROP TABLE #R;
    CREATE TABLE #R (
        Sec CHAR(3), Info NVARCHAR(100), KeyVal NVARCHAR(100),
        Qty INT, Sales DECIMAL(19,4), AvgVal DECIMAL(19,4), Cnt INT, JoinType VARCHAR(20)
    );

    BEGIN TRY
        IF @StartDate > @EndDate THROW 50001, 'Invalid date range', 1;

        -- 1. GROUP BY + SUM + AVG
        INSERT #R SELECT '01','By Category',CategoryName,SUM(OrderQty),SUM(LineTotal),AVG(NetPrice),COUNT(*),'INNER'
               FROM dbo.fn_Sales(@StartDate,@EndDate) GROUP BY CategoryName;

        -- 2. ROLLUP
        INSERT #R SELECT '02','ROLLUP',ISNULL(CategoryName,'TOTAL'),SUM(OrderQty),SUM(LineTotal),NULL,COUNT(*),'ROLLUP'
               FROM dbo.fn_Sales(@StartDate,@EndDate) GROUP BY ROLLUP(CategoryName);

        -- 3. CUBE
        INSERT #R SELECT '03','CUBE',ISNULL(CategoryName,'ALL')+'|'+ISNULL(CAST(YEAR(OrderDate)AS VARCHAR(4)),'ALL'),
               SUM(OrderQty),SUM(LineTotal),NULL,COUNT(*),'CUBE'
               FROM dbo.fn_Sales(@StartDate,@EndDate) GROUP BY CUBE(CategoryName,YEAR(OrderDate));

        -- 4. LEFT JOIN
        INSERT #R SELECT '04','No Orders',CompanyName,0,0,0,1,'LEFT'
               FROM SalesLT.Customer c LEFT JOIN SalesLT.SalesOrderHeader h ON c.CustomerID=h.CustomerID
               WHERE h.CustomerID IS NULL;

        -- 5. RIGHT JOIN
        INSERT #R SELECT '05','Never Sold',p.Name,0,0,p.ListPrice,1,'RIGHT'
               FROM SalesLT.Product p LEFT JOIN SalesLT.SalesOrderDetail d ON p.ProductID=d.ProductID
               WHERE d.ProductID IS NULL;

        -- 6. FULL OUTER
        INSERT #R SELECT '06','Full',ISNULL(pc.Name,'None'),ISNULL(SUM(d.OrderQty),0),ISNULL(SUM(d.LineTotal),0),NULL,COUNT(*),'FULL'
               FROM SalesLT.ProductCategory pc
               FULL OUTER JOIN SalesLT.Product p ON pc.ProductCategoryID=p.ProductCategoryID
               FULL OUTER JOIN SalesLT.SalesOrderDetail d ON p.ProductID=d.ProductID
               GROUP BY pc.Name;

        -- 7. CROSS JOIN
        INSERT #R SELECT TOP 15 '07','Potential',c.CompanyName+' × '+pc.Name,NULL,NULL,NULL,1,'CROSS'
               FROM (SELECT TOP 5 CompanyName FROM SalesLT.Customer) c
               CROSS JOIN (SELECT TOP 3 Name FROM SalesLT.ProductCategory) pc;

        -- Summary
        INSERT @Summary VALUES
            ('Total Sales', (SELECT SUM(LineTotal) FROM dbo.fn_Sales(@StartDate,@EndDate))),
            ('Order Count', (SELECT COUNT(DISTINCT SalesOrderID) FROM dbo.fn_Sales(@StartDate,@EndDate))),
            ('Avg Discount', (SELECT AVG(UnitPriceDiscount) FROM SalesLT.SalesOrderDetail));

        SELECT * FROM #R ORDER BY Sec, Sales DESC;
        SELECT * FROM @Summary;

    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#R') IS NOT NULL
            INSERT #R VALUES ('ERR',ERROR_MESSAGE(),'TRY/CATCH',NULL,NULL,NULL,1,'ERROR');
        SELECT 'ERROR' Status, ERROR_MESSAGE() Message;
        THROW;
    END CATCH
END
GO

-- Execute
EXEC dbo.usp_AdvancedDemo '2013-01-01', '2014-12-31';


EXEC dbo.usp_AdventureWorks_MasterClass_Educational 
    @StartDate = '2013-01-01', 
    @EndDate   = '2014-12-31';