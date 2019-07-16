--Demonstrate sequence permissions
use w
go


USE [master]
GO
CREATE LOGIN [testseq] WITH PASSWORD=N'test', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO
Use w
create user testseq for login testseq
GO 

create schema test authorization dbo
go
CREATE SEQUENCE Test.CountBy1  
    START WITH 1  
    INCREMENT BY 1 ;  
GO

EXECUTE AS USER = 'testseq';
SELECT NEXT VALUE FOR Test.CountBy1; --FAILS
REVERT
GO
GRANT UPDATE ON OBJECT::Test.CountBy1 to testSeq 
GO
EXECUTE AS USER = 'testseq';
SELECT NEXT VALUE FOR Test.CountBy1; --SUCCEEDS
REVERT
GO
--cleanup
REVOKE UPDATE ON Test.CountBy1 to testSeq 
DROP SEQUENCE Test.CountBy1  
   