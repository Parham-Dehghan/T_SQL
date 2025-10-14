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