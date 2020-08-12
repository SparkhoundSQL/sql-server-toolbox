/*
use master
go
drop database enctest
go
drop CERTIFICATE TDECert_enctest_2012 
go
drop master key
go
*/
USE [master]
GO

--For Transparent Data Encryption (TDE) enabled databases with a single data file, 
--the default MAXTRANSFERSIZE is 65536 (64 KB). For non-TDE encrypted databases the 
--default MAXTRANSFERSIZE is 1048576 (1 MB) when using backup to DISK, and 65536 (64 KB) when using VDI or TAPE. 
--https://docs.microsoft.com/en-us/sql/t-sql/statements/backup-transact-sql?view=sql-server-2017


--Setup testing database.
CREATE DATABASE [enctest]
GO
use enctest
go
CREATE TABLE dbo.filler (id int identity(1,1) NOT NULL PRIMARY KEY, fillertext1 varchar(1000) not null)
go

--Begin encrypting
USE master
go
CREATE MASTER KEY  ENCRYPTION BY PASSWORD = '$123testpassword-VM1';
--SELECT * FROM sys.symmetric_keys where name = '##MS_DatabaseMasterKey##'
GO
CREATE CERTIFICATE TDECert_enctest_2012 
WITH SUBJECT = 'Testing TDE Cert'
, START_DATE = '3/14/2011' --Today's Date
, EXPIRY_DATE = '3/14/2071'; --Future Date
--SELECT * FROM sys.certificates where name = 'TDECert_enctest_2012'
GO
BACKUP SERVICE MASTER KEY --not actually important for TDE, but important overall and should be backed up regardless. See also: toolbox\backup service master key.sql
TO FILE = 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\data\SQLServiceMasterKey_20120314.snk' 
    ENCRYPTION BY PASSWORD = '$1234testpassword'

BACKUP MASTER KEY --each instance can have its own master key.
TO FILE = 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\data\SQLMasterKey_20120314.key' 
    ENCRYPTION BY PASSWORD = '$123testpassword' --This password is for the FILE. The Master Key's password above is different.

BACKUP CERTIFICATE TDECert_enctest_2012 
TO FILE = 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\data\TestingTDEcert2014.cer'
 WITH PRIVATE KEY ( FILE = 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\data\TestingTDEcert2014.key' , 
    ENCRYPTION BY PASSWORD = '$12345testpassword123' );
GO


USE enctest
go
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE TDECert_enctest_2012
GO
BACKUP DATABASE enctest to DISK = 'e:\sql\enctest_backup_test_before_encryption_20121121.bak'
go
INSERT INTO dbo.filler (fillertext1) Values ('testing - post unencrypted backup')
GO
ALTER DATABASE enctest SET ENCRYPTION ON
GO
SELECT pvt_key_last_backup_date, 
       Db_name(dek.database_id) AS encrypteddatabase ,c.name AS Certificate_Name , *
FROM   master.sys.certificates c 
       left outer JOIN master.sys.dm_database_encryption_keys dek 
         ON c.thumbprint = dek.encryptor_thumbprint 
go

SELECT [name], is_encrypted FROM sys.databases order by is_encrypted desc, name asc
GO
/* The value 3 represents an encrypted state on the database and transaction logs. */
SELECT d.name, dek.*
FROM sys.dm_database_encryption_keys dek
inner join sys.databases d
on dek.database_id = d.database_id
WHERE encryption_state = 3
and d.database_id > 4
GO

use master
go
--Backup encrypted database
BACKUP DATABASE enctest to DISK = 'e:\sql\enctest_backup_test_after_encryption_20121122.bak' WITH INIT
GO
use master
go
--Prove I can restore the encrypted database
ALTER DATABASE enctest SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
--Tail-end backup
BACKUP LOG enctest to DISK = 'e:\sql\enctest_backup_test_after_encryption_20121122.trn' WITH INIT
GO
RESTORE DATABASE enctest FROM  DISK = N'e:\sql\enctest_backup_test_after_encryption_20121122.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10, NORECOVERY
GO
RESTORE LOG enctest FROM  DISK = N'e:\sql\enctest_backup_test_after_encryption_20121122.trn' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10, RECOVERY
GO
ALTER DATABASE enctest SET  MULTI_USER
GO

--Drop the database, try to restore.
use master
go
--simulate a new server that doesn't have the certificate.
drop database enctest
go
drop CERTIFICATE TDECert_enctest_2012 
go
drop master key
go 
--Try to restore.  Fail!  Cannot find certificate.
RESTORE DATABASE enctest FROM  DISK = N'e:\sql\enctest_backup_test_after_encryption_20121122.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10, NORECOVERY
GO
RESTORE LOG enctest FROM  DISK = N'e:\sql\enctest_backup_test_after_encryption_20121122.ldf' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10, RECOVERY
GO

--Ok, let's recreate.
use master 
go
CREATE MASTER KEY  ENCRYPTION BY PASSWORD = '$123testpassword2'; --different from before, and OK
--SELECT * FROM sys.symmetric_keys where name = '##MS_DatabaseMasterKey##'
GO
--Restore the TDE cert to this server
CREATE CERTIFICATE TDECert_enctest_2012 
    FROM FILE = 'e:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\data\TestingTDEcert2014.cer'
 WITH PRIVATE KEY ( FILE = 'e:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\data\TestingTDEcert2014.key' , 
    DECRYPTION BY PASSWORD = '$12345testpassword123' ); --Same as before
GO
--Try to restore.  Success!
RESTORE DATABASE enctest FROM  DISK = N'e:\sql\enctest_backup_test_after_encryption_20121122.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10, NORECOVERY
GO
RESTORE LOG enctest FROM  DISK = N'e:\sql\enctest_backup_test_after_encryption_20121122.trn' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10, RECOVERY
GO


select * from enctest.dbo.filler
--Restoring a backup from before encryption removes the encryption!
ALTER DATABASE enctest SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE enctest SET  SINGLE_USER 
GO
RESTORE DATABASE enctest FROM  DISK = N'e:\sql\enctest_backup_test_before_encryption_20121121.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10, RECOVERY
GO
ALTER DATABASE enctest SET  MULTI_USER
GO
--Database is no longer encrypted.
SELECT [name], is_encrypted FROM sys.databases
GO


/*  Test re-creating the cert backup, in case the key or the password for the key has been lost.*/

use master
go

--Backup the existing cert with a new cert backup, with new key and new password
BACKUP CERTIFICATE TDECert_enctest_2012 
TO FILE = 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\data\TestingTDEcert2014_5.cer'
 WITH PRIVATE KEY ( FILE = 'E:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\data\TestingTDEcert2014_5.key' , 
    ENCRYPTION BY PASSWORD = '$12345testpassword12345678' );
GO

--simulate a new server that doesn't have the certificate.
ALTER DATABASE enctest SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
drop database enctest
go
drop CERTIFICATE TDECert_enctest_2012 
go
--drop master key
go
--CREATE MASTER KEY  ENCRYPTION BY PASSWORD = '$123testpassword12345'; --different from before, and OK

--Restore the same Cert using the new key and password
CREATE CERTIFICATE TDECert_enctest_2012 
    FROM FILE = 'e:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\data\TestingTDEcert2014_5.cer'
 WITH PRIVATE KEY ( FILE = 'e:\Program Files\Microsoft SQL Server\MSSQL14.SQL2K17\MSSQL\data\TestingTDEcert2014_5.key' , 
    DECRYPTION BY PASSWORD = '$12345testpassword12345678' ); --Same as before
GO

--Try to restore the database, encrypted before the new cert backup.  Success!
RESTORE DATABASE enctest FROM  DISK = N'e:\sql\enctest_backup_test_after_encryption_20121122.bak' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10, NORECOVERY
GO
RESTORE LOG enctest FROM  DISK = N'e:\sql\enctest_backup_test_after_encryption_20121122.trn' WITH  FILE = 1,  NOUNLOAD,  REPLACE,  STATS = 10, RECOVERY
GO