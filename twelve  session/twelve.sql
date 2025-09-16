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


--برای انتخاب جدول Dynamic SQl برای انتخاب جدول
DECLARE @tableName NVARCHAR(50) = 'Accounts';

DECLARE @sql NVARCHAR (MAX);

SET @sql = N'SELECT * FROM' + QUOTENAME(@tableName);

EXEC(@sql);

-- TRY...CATCH با Error Handling
BEGIN TRY
    --کویری ای که ممکنه خطا بده
	UPDATE Accounts
	SET Balance = Balance - 5000
	WHERE AccountID = 1;
END TRY
BEGIN CATCH 
    PRINT'خطا رخ داد!';
END CATCH;


--نمایش جزییات خطا
BEGIN TRY
     DELETE FROM Accounts WHERE 
AccountID = 100; -- وجود ندارد
END TRY 
BEGIN CATCH 
    SELECT 
	   ERROR_NUMBER() AS ErrorNumber,
	   ERROR_SEVERITY() AS Severity,
	   ERROR_STATE() AS State,
	   ERROR_PROCEDURE() AS ProcedureName,
	   ERROR_LINE() AS ErrorLine,
	   ERROR_MESSAGE() AS ErrorMessage;
END CATCH;
--نکته : توابع ()*_ERROR اطلاعات کامل خطا رو برمی گردونند 


-- Safe money transfer
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @Amount DECIMAL(18,2) = 700;

    -- Deduct from Account 1
    UPDATE Accounts
    SET Balance = Balance - @Amount
    WHERE AccountID = 1;

    -- Add to Account 3
    UPDATE Accounts
    SET Balance = Balance + @Amount
    WHERE AccountID = 3;

    COMMIT;
    PRINT 'Transfer completed successfully.';
END TRY
BEGIN CATCH
    ROLLBACK;
    PRINT 'Transfer failed.';
    SELECT 
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_MESSAGE() AS ErrorMessage;
END CATCH;

use master
go
DROP DATABASE IF EXISTS test12