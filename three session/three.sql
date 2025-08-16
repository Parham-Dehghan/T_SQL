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

--نمایش جدول انتخاب شده
SELECT * FROM Users

--نمایش ستون های انتخاب شده از جدول
SELECT FirstName, Lastname FROM Users;


-- تمام ستون‌های محصولاتی که قیمت آنها بیشتر از ۱۰۰۰ هست را نمایش می دهد
SELECT * FROM Products
WHERE Price > 1000;

-- تمام ستون‌های Users که نام کوچک آنها «پرهام» است را انتخاب می کنیم
SELECT * FROM Users
WHERE FirstName = 'Parham';


---- تمام ستون‌های محصولات را انتخاب می کند و نتایج را بر اساس قیمت به صورت صعودی مرتب می کند
SELECT * FROM Products
ORDER BY Price ASC;

-- تمام ستون‌ها را از Users انتخاب می کند و نتایج را بر اساس DataCreated به ترتیب نزولی مرتب می کند.
SELECT * FROM Users
ORDER BY DataCreated DESC;


--تعداد رکورد ها در جدول user نشون میده
SELECT COUNT(*) AS TotalUsers FROM Users;


--جمع تعداد سفارشات  از جدول محصولات نشان میدهد
SELECT SUM(Quantity) AS TotalQuantity FROM Orders;

--کمترین قیمت و بیشترین قیمت و میانگین قیمت رو از ستون قیمت در جدول محصولات  میگیره
SELECT MIN(Price) AS MinPrice,
       MAX(Price) AS MaxPrice,
	   AVG(Price) AS AvgPrice
FROM Products;

-- نشان میدهد که هر ایدی چه مقداری خرید داشته است
SELECT UserID , COUNT(*) AS
OrderCount
FROM Orders
GROUP BY UserID;

--- جمع تعداد خرید ها و جمع تعداد ایدی ها بیش از یک خرید داشتن
SELECT UserID , SUM(Quantity) AS
TotalQuantity
FROM Orders
GROUP BY UserID
HAVING SUM(Quantity) > 1;