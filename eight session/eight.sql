USE master
GO
create database test8

USE test8
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


--ایجاد جدول با Primary Key
CREATE TABLE Departments (
   DepartmentID INT PRIMARY KEY,
   DepartmentName NVARCHAR(50) NOT
NULL
);


--ایجاد جدول Employeesبا رابطه با Departements
CREATE TABLE Employees (
    EmployeesID INT PRIMARY KEY,
	FristName NVARCHAR(50),
	LastName NVARCHAR(50),
	DepartmentID INT,
	CONSTRAINT FK_Dept FOREIGN KEY (DepartmentID)
	REFERENCES
Departments(DepartmentID)
);


--ایمیل منحصر به فرد برای کاربران
ALTER TABLE Users
ADD CONSTRAINT UQ_Email UNIQUE
(Email);

--قیمت محصولات باید بزرگتر از صفر باشد
ALTER TABLE Products
ADD CONSTRAINT CHK_Price CHECK (Price> 0);

--تعداد سفارش ها باید مثبت باشد
ALTER TABLE Orders
ADD CONSTRAINT CHK_Quantity CHECK (Quantity > 0);

--اجباری کردن مقدار برای ستون 
ALTER TABLE Users
ALTER COLUMN FirstName NVARCHAR(50)
NOT NULL;

--ایجاد Trigger برای ثبت تاریخ ایجاد سفارش
CREATE TRIGGER trg_InsertOrder
ON Orders
AFTER INSERT
AS
BEGIN
    UPDATE Orders
	SET OrderData = GETDATE()
	FROM Orders o
	INNER JOIN inserted i ON
o.OrderID = i.OrderID;
END;


--ثبت تغییرات قیمت محصول
CREATE TRIGGER trg_UpdateProductPrice ON Products
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Price)
	BEGIN
	    INSERT INTO
ProductsPriceLog(ProductsID,OldPrice, NewPrice, ChangeDate)
    SELECT d.ProductsID, d.Price, i.Price, GETDATE()
	            FROM deleted d
				INNER JOIN inserted i ON
d.ProductsID = i.ProductsID;
   END
END


--ثبت لاگ هنگام حذف سفارش
CREATE TRIGGER trg_DeleteOrder
ON Orders
AFTER DELETE
AS
BEGIN
    INSERT INTO OrdersLog(OrderID,DeletedDate)
	SELECT OrderID, GETDATE() FROM
deleted;
END;


--جلوگیری از حذف مستقیم کاربران
CREATE TRIGGER trg_PreventUserDelete
ON Users
INSTEAD OF DELETE
AS
BEGIN
    PRINT 'حذف کاربر مستقیم مجاز نیست';
END;