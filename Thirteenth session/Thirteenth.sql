use master
go 

create database Thirteenth

use Thirteenth
go

CREATE TABLE Employees(
    EmployeeID INT IDENTITY(1,1)
PRIMARY KEY,
    FirstName NVARCHAR(50),
	LastName NVARCHAR(50),
	DepartmentID INT,
	Salary INT,
);

--درج داده ها 
 INSERT INTO Employees(FirstName , LastName , DepartmentID , Salary)
 VALUES
 ('Ali','Ahmadi',1,12000),
 ('Sara','Karimi',1,17000),
 ('Reza','Mohammadi',2,14000),
 ('Neda','Shirazi',2,18000),
 ('Amir','Hosseini',3,9000),
 ('Maryam','Rahimi',3,13000);



 SELECT FirstName, LastName, Salary
 FROM Employees
 WHERE Salary >(SELECT AVG(Salary) FROM Employees);


 WITH SalaryCTE AS(
     SELECT DepartmentID, AVG(Salary)
AS AvgSalary
   FROM Employees
   GROUP BY DepartmentID
)
SELECT 
    e.FirstName,
	e.LastName,
	e.salary,
	s.AvgSalary
FROM Employees e
JOIN SalaryCTE s
ON e.DepartmentID = s.DepartmentID
WHERE e.Salary > s.AvgSalary;


--رتبه بندی
SELECT 
    FirstName, LastName,
DepartmentID, Salary,
   RANK() OVER(PARTITION BY 
   DepartmentID ORDER BY Salary DESC) AS
   SalaryRank
   FROM Employees

--ذخیره کویری های پر تکرار
CREATE PROCEDURE
GetHighSalaryEmployees
    @MinSalary INT
AS
BEGIN
    SELECT FirstName, LastName,
Salary
     FROM Employees
	 WHERE Salary > @MinSalary;
END;

--اجرا تابع بالا
EXEC GetHighSalaryEmployees
@MinSalary = 15000;


-- ساخت جدول Orders
CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    CustomerID INT,
    OrderDate DATE,
    Amount INT
);

-- درج داده‌های نمونه
INSERT INTO Orders (CustomerID, OrderDate, Amount) VALUES
(101, '2025-01-12', 250000),
(102, '2025-01-15', 120000),
(101, '2025-02-01', 310000),
(103, '2025-02-10', 90000),
(104, '2025-03-05', 450000),
(102, '2025-03-20', 150000);


--تمرین 1 : مشتریانی که مجموع خریدشان بیش از 300,000 است
SELECT
     CustomerID,
	 SUM(Amount) AS TotalAmount
FROM Orders
GROUP BY CustomerID
HAVING SUM(Amount) > 300000;

--آخرین سفارش هر مشتری 
SELECT *
FROM(
    SELECT *,
	        ROW_NUMBER() OVER
(PARTITION BY CustomerID ORDER BY
OrderDate DESC) AS rn
    FROM Orders
) AS t
WHERE rn = 1;


--مجموع فروش در هر ماه با CTE
WITH MonthlySales AS (
    SELECT 
        YEAR(OrderDate) AS Year,
        MONTH(OrderDate) AS Month,
        SUM(Amount) AS TotalSales
    FROM Orders
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)
SELECT * FROM MonthlySales;


--ساخت Stored Procedureبرای بازه زمانی 
CREATE PROCEDURE GetOrdersByDateRange
    @StartDate DATE,
    @EndDate DATE
AS
BEGIN
    SELECT * 
    FROM Orders
    WHERE OrderDate BETWEEN @StartDate AND @EndDate
    ORDER BY OrderDate;
END;

--خط کد برای اجرا تابع بالا
EXEC GetOrdersByDateRange @StartDate = '2025-01-01', @EndDate = '2025-02-28';

use master
go
DROP DATABASE IF EXISTS Thirteenth