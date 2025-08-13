--درست کردن دیتا بیس
CREATE DATABASE MyDatabase;


--تغییر نام 
alter database my_database
   modify Name = myDatabase5


--حذف کردن دیتابیس
use master
go
DROP DATABASE IF EXISTS myDatabase5;