USE master
go

CREATE DATABASE test3; --ایجاد دیتا بیس
go
USE test3;-- فرا خوانی دیتا بیس
go



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

INSERT INTO Users (FirstName, LastName, Email)
VALUES
('Parham', 'Dehghan', 'parham@example.com'),
('Ali', 'Rezaei', 'ali@example.com');

-- افزودن محصولات
INSERT INTO Products (ProductName, Price, Stock)
VALUES
('Laptop', 1500.00, 10),
('Mouse', 25.50, 50);

-- ثبت سفارش
INSERT INTO Orders (UserID, ProductID, Quantity)
VALUES
(1, 1, 1),  -- Parham سفارش لپ‌تاپ
(2, 2, 2);  -- Ali سفارش موس