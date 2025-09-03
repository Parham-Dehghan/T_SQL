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
