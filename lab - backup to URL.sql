
USE master  
/*
--SQL 2016+
CREATE CREDENTIAL [https://sphsqlbackup.blob.core.windows.net/prodsqlbak] -- this name must match the container path, start with https and must not contain a forward slash.  
   WITH IDENTITY='SHARED ACCESS SIGNATURE'  -- this is a mandatory string and do not change it.   
   , SECRET = N'KThhZXL2l4Kyu1GPvLf9wlhuu6A/K/PQqpNsfxahM3QAm71mBLDcr3CwaQv7RxDCCARJ2pWURxsQKTlM2ATVNA==' -- this is the shared access signature key that you obtained in Lesson 1.   
GO
BACKUP DATABASE [DBALogging] TO  URL = N'https://sphsqlbackup.blob.core.windows.net/prodsqlbak/DBALogging_backup_2017_10_24.bak' 
WITH  NAME = N'DBALogging-Full Database Backup', NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10, CHECKSUM
GO
*/

--Legacy method without SAS
CREATE CREDENTIAL [https://sphsqlbackup.blob.core.windows.net/prodsqlbak] -- this name must match the container path, start with https and must not contain a forward slash.  
   WITH IDENTITY='sphsqlbackup'  -- this is a mandatory string and do not change it.   
   , SECRET = N'KThhZXL2l4Kyu1GPvLf9wlhuu6A/K/PQqpNsfxahM3QAm71mBLDcr3CwaQv7RxDCCARJ2pWURxsQKTlM2ATVNA==' -- this is the shared access signature key that you obtained in Lesson 1.   
GO

BACKUP DATABASE [DBALogging] TO  URL = N'https://sphsqlbackup.blob.core.windows.net/prodsqlbak/test/DBALogging_backup_2017_10_24_151352.bak' 
WITH CREDENTIAL = 'https://sphsqlbackup.blob.core.windows.net/prodsqlbak',
FORMAT, NAME = N'DBALogging-Full Database Backup', NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10, CHECKSUM
GO


