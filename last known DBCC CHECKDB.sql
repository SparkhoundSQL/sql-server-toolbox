CREATE TABLE #DBInfo (ParentObject VARCHAR(255), [Object] VARCHAR(255), Field VARCHAR(255), [Value] VARCHAR(255))
CREATE TABLE #Value (DatabaseName VARCHAR(255), LastDBCCCheckDB DATETIME)
EXECUTE sp_MSforeachdb '
--Insert results of DBCC DBINFO into temp table, transform into simpler table with database name and datetime of last known good DBCC CheckDB
INSERT INTO #DBInfo EXECUTE ("DBCC DBINFO ( ""?"" ) WITH TABLERESULTS");
INSERT INTO #Value (DatabaseName, LastDBCCCheckDB) (SELECT "?", [Value] FROM #DBInfo WHERE Field = "dbi_dbccLastKnownGood");
TRUNCATE TABLE #DBInfo;
'
SELECT v.*, d.state_desc FROM #Value v inner join sys.databases d on v.DatabaseName = d.name 
GO
DROP TABLE #DBInfo
DROP TABLE #Value 

--credit Ryan DeVries: https://www.brentozar.com/archive/2015/08/getting-the-last-good-dbcc-checkdb-date/#comment-2211907