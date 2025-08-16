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

--نمایش اسم افرادی که با A شروع میشه
SELECT * FROM Users
WHERE FirstName LIKE 'A%';

--نمایش نام محصولاتی که داخلش top هستش
SELECT * FROM Products
WHERE ProductName LIKE '%top%';

--مقادیر تکراری در دوتا جدول حذف می کند و نمایش میدهد
SELECT FirstName AS Name FROM Users 
UNION 
SELECT ProductName AS Name FROM Products;


--تمام افرادی که سفارش ثیت کردن و فقط سفارش دارن نمایش داده شوند
SELECT * FROM Users
WHERE UserID IN (SELECT DISTINCT 
UserID FROM Orders);

--سفارشات گروه بندی می شود و سفارش هایی که بیش از یکبار سفارش دارن نمایش داده شود
SELECT * FROM Products
WHERE ProductsID IN(
    SELECT ProductID
	FROM Orders
	GROUP BY ProductID
	HAVING COUNT(*) > 1
);

-- این کوئری تمام کاربران را که حداقل یک سفارش دارند همراه با اطلاعات سفارششان نمایش می‌دهد.
SELECT u.UserID, u.FirstName, u.LastName, o.OrderID, o.ProductID, o.Quantity
FROM Users u
INNER JOIN Orders o
    ON u.UserID = o.UserID;

-- این کوئری تمام کاربران را نمایش می‌دهد، حتی اگر سفارشی ثبت نکرده باشند.
-- ستون‌های سفارش (OrderID, ProductID, Quantity) در صورتی که سفارشی نباشد، NULL خواهند بود.
SELECT u.UserID, u.FirstName, u.LastName, o.OrderID, o.ProductID, o.Quantity
FROM Users u
LEFT JOIN Orders o
    ON u.UserID = o.UserID;

-- این کوئری تمام سفارشات را نمایش می‌دهد، حتی اگر کاربر مربوطه وجود نداشته باشد.
-- ستون‌های کاربر (UserID, FirstName, LastName) در صورتی که کاربر موجود نباشد، NULL خواهند بود.
SELECT u.UserID, u.FirstName, u.LastName, o.OrderID, o.ProductID, o.Quantity
FROM Users u
RIGHT JOIN Orders o
    ON u.UserID = o.UserID;


--انتخاب 3 محصول با بالاترین قیمت به ترتیب نزولی
SELECT TOP 3 * FROM Products
ORDER BY Price DESC;