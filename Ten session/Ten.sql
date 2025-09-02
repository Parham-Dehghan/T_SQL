USE master
GO
create database test10
USE test10
GO


--جدول کاربران
CREATE TABLE Users (
   UserID INT IDENTITY(1,1)PRIMARY KEY,--شناسه یکتا
   FirstName NVARCHAR(50) NOT NULL,--نام
   LastName NVARCHAR(50) NOT NULL,--نام و نام حانوادگی
   Email NVARCHAR(50) NOT NULL,--ایمیل
   DataCreated DATETIME DEFAULT GETDATE()--تاریخ ایجاد
);

--جدول محصولات
CREATE TABLE Products (
    ProductsID INT IDENTITY(1,1)PRIMARY KEY,--شناسه یکتا
	ProductName NVARCHAR(100) NOT NULL,
	Price DECIMAL(10,2) NOT NULL,
	Stock INT DEFAULT 0,
	DataAdded DATETIME DEFAULT GETDATE()
);

--جدول سفارشات
CREATE TABLE Orders(
    OrderID INT IDENTITY(1,1)PRIMARY KEY,--شناسه یکتا
	UserID INT NOT NULL,
	ProductID INT NOT NULL,
	Quantity INT DEFAULT 1,
	OrderData DATETIME DEFAULT GETDATE(),
	FOREIGN KEY (UserID) REFERENCES Users(UserID),
	FOREIGN KEY (ProductID) REFERENCES Products(ProductsID)
);

-- جدول دسته‌بندی‌ها
CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL
);

INSERT INTO Categories (CategoryName)
VALUES
(N'لوازم الکترونیکی'),
(N'لوازم جانبی'),
(N'پوشاک'),
(N'کتاب');

CREATE TABLE Employees (
    EmployeeID INT PRIMARY KEY IDENTITY(1,1),
    FirstName NVARCHAR(50) NOT NULL,
    LastName NVARCHAR(50) NOT NULL,
    ManagerID INT NULL,
    FOREIGN KEY (ManagerID) REFERENCES Employees(EmployeeID)
);

INSERT INTO Employees (FirstName, LastName, ManagerID)
VALUES
('Ali', 'Rezayi', NULL),       -- مدیر کل
('Sara', 'Ahmadi', 1),         -- کارمند با مدیر Ali
('Reza', 'Karimi', 1),
('Neda', 'Mohammadi', 2),      -- کارمند با مدیر Sara
('Hossein', 'Shahri', 3);      -- کارمند با مدیر Reza



-- افزودن کاربران
INSERT INTO Users (FirstName, LastName, Email)
VALUES
('Parham', 'Dehghan', 'parham@example.com'),
('Ali', 'Rezaei', 'ali@example.com'),
('Sara', 'Ahmadi', 'sara@example.com'),
('Reza', 'Karimi', 'reza@example.com'),
('Neda', 'Mohammadi', 'neda@example.com'),
('Hossein', 'Shahri', 'hossein@example.com'),
('Maryam', 'Hosseini', 'maryam@example.com'),
('Kaveh', 'Rahimi', 'kaveh@example.com'),
('Leila', 'Sadeghi', 'leila@example.com'),
('Amir', 'Jafari', 'amir@example.com');

-- افزودن محصولات
INSERT INTO Products (ProductName, Price, Stock)
VALUES
('Laptop', 1500.00, 10),
('Mouse', 25.50, 50),
('Keyboard', 45.00, 40),
('Monitor', 300.00, 20),
('USB Cable', 10.00, 100),
('Printer', 200.00, 15),
('Webcam', 80.00, 25),
('Headphones', 60.00, 30),
('Smartphone', 800.00, 12),
('Tablet', 400.00, 18);

-- ثبت سفارشات
INSERT INTO Orders (UserID, ProductID, Quantity)
VALUES
(1, 1, 1),
(2, 2, 2),
(3, 3, 1),
(4, 4, 1),
(5, 5, 3),
(6, 6, 2),
(7, 7, 1),
(8, 8, 4),
(9, 9, 1),
(10, 10, 2),
(1, 2, 2),
(2, 3, 1),
(3, 4, 2),
(4, 5, 5),
(5, 1, 1),
(6, 2, 3),
(7, 3, 1),
(8, 4, 2),
(9, 5, 1),
(10, 6, 1);


--ایجاد CTE برای نمایش کاربران با تعداد سفارش
WITH UserOrders AS(
     SELECT UserID, COUNT(OrderID) AS
OrdersCount
     FROM Orders
	 GROUP BY UserID
)
SELECT u.FirstName, u.LastName, uo.OrdersCount
FROM Users u
INNER JOIN UserOrders uo ON u.UserID = uo.UserID;

--متوالی CTE چند
WITH UserOrders AS (
     SELECT UserID , COUNT(OrderID) AS OrdersCount
	 FROM Orders
	 GROUP BY UserID
),
HighOrders AS (
   SELECT UserID
   FROM UserOrders
   WHERE OrdersCount > 5
)
SELECT u.FirstName, u.LastName
FROM Users u
INNER JOIN HighOrders h ON u.UserID = h.UserID;


--جدول نمونه : Departments با ParentID
CREATE TABLE Departments (
     DepartmentID INT PRIMARY KEY,
	 DepartmentName NVARCHAR(50),
	 ParentID INT NULL
);

--داده نمونه
INSERT INTO Departments VALUES
(1, 'm' , NULL),
(2, 'H' , 1),
(3, 'I' , 1),
(4, 'H' , 2),
(5, 'I' , 2);

--بازگشتی برای نمایش سلسله مراتب CTE 
WITH DeptHierarchy AS(
    SELECT DepartmentID, DepartmentName , ParentID , 0 AS Level 
	FROM Departments
	WHERE ParentID IS NULL 
	UNION ALL
	SELECT d.DepartmentID , d.DepartmentName , d.ParentID , dh.Level + 1
	FROM Departments d
	INNER JOIN DeptHierarchy dh ON
d.ParentID = dh.DepartmentID
)
SELECT * FROM DeptHierarchy
ORDER BY Level, DepartmentID;

-- نمایش کارمندان و مدیران آنها
SELECT 
    e.EmployeeID,
    e.FirstName AS EmployeeName, 
    m.FirstName AS ManagerName
FROM Employees e
LEFT JOIN Employees m ON e.ManagerID = m.EmployeeID;


CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY IDENTITY(1,1),
    CategoryName NVARCHAR(100) NOT NULL
);


ALTER TABLE Products
ADD CategoryID INT;


-- نمایش گران‌ترین محصول در هر دسته‌بندی
SELECT 
    c.CategoryName, 
    p.ProductName, 
    p.Price
FROM Categories c
CROSS APPLY (
      SELECT TOP 1 ProductName, Price
      FROM Products
      WHERE Products.CategoryID = c.CategoryID
      ORDER BY Price DESC
) p;
