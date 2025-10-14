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



