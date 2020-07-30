--1. see toolbox\lab - tde encryption workshop 2014.sql
--2. Note you should also backup the Service Master Key!!
--3. Generate three strong passwords.
--4. See important TODO to copy these files OFFSITE.
USE master
go
CREATE MASTER KEY  ENCRYPTION BY PASSWORD = '$123testpassword-VM1'; --The master database master key password 1
GO
--Proof it is now there
SELECT * FROM sys.symmetric_keys where name = '##MS_DatabaseMasterKey##'
GO
CREATE CERTIFICATE TDECert_enctest_2012 
WITH SUBJECT = 'Testing TDE Cert'
, START_DATE = '7/30/2019' --Today's Date
, EXPIRY_DATE = '7/30/2099'; --Future Date
GO
--Proof it is now there
SELECT * FROM sys.certificates where name = 'TDECert_enctest_2012'
GO

--You must take backups for recovery of both the master DB master key and the cert.
BACKUP MASTER KEY --each instance can have its own master key.
TO FILE = 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\data\SQLMasterKey_20120314.key' 
    ENCRYPTION BY PASSWORD = '$123testpassword' --This password is for the new master key backup file. The Master Key's password above is different. Password 2

BACKUP CERTIFICATE TDECert_enctest_2012 
TO FILE = 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\data\TestingTDEcert2014.cer'
 WITH PRIVATE KEY ( FILE = 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\data\TestingTDEcert2014.key' , --This is a new key file for the cert backup, NOT the same as the key for the MASTER KEY backup above.
    ENCRYPTION BY PASSWORD = '$12345testpassword123' ); --This password is for the cert backup's key file. The Master Key's password above is different. Password 3
GO

USE [enctest] --In this case, enctest is the sample name of the database you want to encrypt with TDE. 
go
--Create the key in the TDE database using the server cert we created earlier.
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TDECert_enctest_2012
GO
--This actually enables TDE on the database. This begins an asynchronous encryption process, it will finish immediately and encrypt behind the scenes.
ALTER DATABASE enctest SET ENCRYPTION ON
GO

--Proof it is encrypted.
SELECT [name], is_encrypted FROM sys.databases order by is_encrypted desc, name asc
GO
--Then check "tde status.sql" for encryption progress.

/* IMPORTANT:
Copy the three passwords, MOVE the master key file, the cert backup, and the cert backup key, OFFSITE to a secure enterprise storage.
DO NOT LOSE THEM. If you lose these files or passwords, you will NOT be able to restore/recover the database!!!
*/