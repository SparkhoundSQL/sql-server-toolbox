/*
--Use Cases for CTE's
1. Replace Temp Tables/Table Vars, change multistep processes to single-query
2. Recursion (org charts)
3. Pre-build row-by-row conversions
*/

with cteSimple as (
select * from sys.databases)
select * from cteSimple--;


















with cteSimple (database_name, db_id) as (
select name, database_id from sys.databases)
select * from cteSimple 
 









 
with cteSimple (database_name, database_id) as (
select name, database_id from sys.databases)
select * from cteSimple c
inner join sys.master_files mf on c.database_id = mf.database_id











--compare:

--Temp Table

SELECT name, database_id into #TempSimple
from sys.databases;

select * from #TempSimple c
inner join sys.master_files mf on c.database_id = mf.database_id;

DROP TABLE IF EXISTS #TempSimple;

--vs 

--CTE 
with cteSimple (database_name, database_id) as (
select name, database_id from sys.databases)
select * from cteSimple c
inner join sys.master_files mf on c.database_id = mf.database_id;


