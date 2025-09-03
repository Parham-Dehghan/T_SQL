use master
go 

create database eleven


use eleven
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


--شروع یک Transaction
BEGIN TRANSACTION;

UPDATE Accounts
SET Balance = Balance - 200
WHERE AccountID = 1;

UPDATE Accounts
SET Balance = Balance + 200
WHERE AccountID = 2;

COMMIT;--ذخیره تغییرات

BEGIN TRANSACTION;

UPDATE Accounts
SET Balance = Balance - 5000 --خطا

WHERE AccountID = 1;

ROLLBACK;

--بررسی تراکنش ها فعال
SELECT @@TRANCOUNT AS 
ActiveTransactions;


BEGIN TRANSACTION

UPDATE Accounts
SET Balance = Balance - 100
WHERE AccountID = 1;

SAVE TRANSACTION Savepoint1; --ذخیره نقطه وسط

UPDATE Accounts
SET Balance = Balance + 100
WHERE AccountID = 3;

COMMIT;



ROLLBACK TRANSACTION SavePoint1;


BEGIN TRANSACTION;

UPDATE Accounts
SET Balance = Balance - 100
WHERE AccountID = 1;


--نمایش lock های فعال
SELECT 
     request_session_id,
resource_type, resource_description, request_mode
FROM sys.dm_tran_locks;