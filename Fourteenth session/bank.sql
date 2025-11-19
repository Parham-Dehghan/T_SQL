USE my_database1;
GO
SET NOCOUNT, XACT_ABORT ON;
GO

CREATE OR ALTER PROCEDURE SP_usp_Sales_ByCategory
    @StartDate DATE,
    @EndDate   DATE
AS
BEGIN
    -- ضد Parameter Sniffing
    DECLARE @s DATE = @StartDate;
    DECLARE @e DATE = DATEADD(DAY, 1, @EndDate);

    -- Temp Table با ایندکس
    IF OBJECT_ID('tempdb..#T') IS NOT NULL DROP TABLE #T;

    CREATE TABLE #T (
        Category    NVARCHAR(50),
        Subcategory NVARCHAR(50),
        Qty         INT,
        Sales       DECIMAL(19,4),
        Orders      INT
    );

    CREATE CLUSTERED INDEX IX_Category ON #T (Category, Subcategory);

    -- کوئری اصلی
    INSERT INTO #T
    SELECT 
        ISNULL(cat.Name, N'نامشخص'),
        ISNULL(sub.Name, N'نامشخص'),
        SUM(d.OrderQty),
        SUM(d.LineTotal),
        COUNT(DISTINCT h.SalesOrderID)
    FROM Sales.SalesOrderHeader h
    JOIN Sales.SalesOrderDetail d ON h.SalesOrderID = d.SalesOrderID
    JOIN Production.Product p ON d.ProductID = p.ProductID
    LEFT JOIN Production.ProductSubcategory sub ON p.ProductSubcategoryID = sub.ProductSubcategoryID
    LEFT JOIN Production.ProductCategory cat ON sub.ProductCategoryID = cat.ProductCategoryID
    WHERE h.OrderDate >= @s
      AND h.OrderDate < @e
      AND h.Status = 5
    GROUP BY ISNULL(cat.Name, N'نامشخص'), ISNULL(sub.Name, N'نامشخص')
    OPTION (RECOMPILE);

    -- خروجی
    SELECT 
        Category,
        Subcategory,
        Qty      AS TotalQty,
        Sales    AS TotalSales,
        Orders   AS OrderCount
    FROM #T
    ORDER BY Sales DESC;

    -- لاگ کوتاه
    PRINT N'ردیف‌ها: ' + CAST(@@ROWCOUNT AS nvarchar(10));
END
GO

-- اجرا
EXEC SP_usp_Sales_ByCategory '2013-01-01', '2014-12-31';