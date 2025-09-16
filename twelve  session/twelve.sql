--START
-- Dynamic SQL چیست؟
--گاهی نیاز داریم کویری رو به صورت پویا (Dynamic) بسازیم و اجرا کنیم
use master
go 

create database twelve


use twelve
go

CREATE TABLE Accounts (
   AccountID INT PRIMARY KEY,
   AccountHolder NVARCHAR(100),
   Balance DECIMAL (18,2)
);

INSERT INTO Accounts (AccountID , AccountHolder, Balance)VALUES
(1,'Ali', 1000.00),
(2,'Sara',2000.00),
(3,'Raza', 1500.00)


--اجرای Dynamic SQL با EXEC
DECLARE @sql NVARCHAR (MAX);
SET @sql = N'SELECT * FROM Accounts WHERE Balance > 1000';
EXEC(@sql);

--اجرا امن تر با sp_executesql
DECLARE @sql NVARCHAR(MAX);
DECLARE @minBalance DECIMAL(18,2);

SET @minBalance = 1200;
SET @sql = N'SELECT * FROM Accounts WHERE Balance > @bal';

EXEC sp_executesql @sql , N'@bal DECIMAL (18 , 2)' , @bal = @minBalance;