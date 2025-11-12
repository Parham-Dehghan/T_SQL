use master
go 

create database Fourteenth

use Fourteenth
go

CREATE TABLE Employees(
    EmployeeID INT IDENTITY(1,1)
PRIMARY KEY,
    FirstName NVARCHAR(50),
	LastName NVARCHAR(50),
	DepartmentID INT,
	Salary INT,
);
