--TODO Set current database context to desired database.

--Execute this version of the script for the current desired database context only.
--Look below for an all-databases version, but it cannot build the CREATE statement.
--Demo lab script to generate a missing index suggestion: toolbox\lab - missing index setup demo.sql

--Cleared when SQL Server restarts. This DMV returns the service start time for both SQL Server and Azure SQL DB.
select sqlserver_start_time from sys.dm_os_sys_info;
GO

SELECT 
	mid.statement 
/* --This block SQL 2017+ only
,	create_index_statement_2017 =	'CREATE NONCLUSTERED INDEX IDX_NC_' + replace(t.name, ' ' ,'')
	+ TRANSLATE(ISNULL(replace(mid.equality_columns, ' ' ,''),'') , '],[' ,'___') --Translate is only supported for SQL 2017+
	+ TRANSLATE(ISNULL(replace(mid.inequality_columns, ' ' ,''),''), '],[' ,'___')
	+ ' ON ' + statement 
	+ ' (' + ISNULL (mid.equality_columns,'') 
    + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ', ' ELSE '' END 
    + ISNULL (mid.inequality_columns, '')
	+ ')' 
	+ ISNULL (' INCLUDE (' + mid.included_columns + ')', '')  COLLATE SQL_Latin1_General_CP1_CI_AS
	--+ ISNULL (' WITH (ONLINE = ON, SORT_IN_TEMPDB = ON)', '')  COLLATE SQL_Latin1_General_CP1_CI_AS --For SQL Server Enterprise Only
*/

,	create_index_statement	=	'CREATE NONCLUSTERED INDEX IDX_NC_' + replace(t.name, ' ' ,'')
	+ replace(replace(replace(ISNULL(replace(mid.equality_columns, ' ' ,''),'') , '],[' ,'_'),'[','_'),']','') 
	+ replace(replace(replace(ISNULL(replace(mid.inequality_columns, ' ' ,''),''), '],[' ,'_'),'[','_'),']','') 
	+ ' ON ' + statement 
	+ ' (' + ISNULL (mid.equality_columns,'') 
    + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ', ' ELSE '' END 
    + ISNULL (mid.inequality_columns, '')
	+ ')' 
	+ ISNULL (' INCLUDE (' + mid.included_columns + ')', '')  COLLATE SQL_Latin1_General_CP1_CI_AS
	--+ ISNULL (' WITH (ONLINE = ON, SORT_IN_TEMPDB = ON)', '')  COLLATE SQL_Latin1_General_CP1_CI_AS --For SQL Server Enterprise Only
,	unique_compiles, migs.user_seeks, migs.user_scans, last_user_seek, migs.avg_total_user_cost, avg_user_impact
, mid.equality_columns,  mid.inequality_columns, mid.included_columns
, quartile
--select *
FROM sys.dm_db_missing_index_groups mig
INNER JOIN 
(select *, quartile = NTILE(4) OVER (ORDER BY avg_total_user_cost asc) from sys.dm_db_missing_index_group_stats) migs 
ON migs.group_handle = mig.index_group_handle
--and migs.quartile = 1 --get only the top 25% of suggestions based on cost.
INNER JOIN sys.dm_db_missing_index_details mid 
ON mig.index_handle = mid.index_handle
inner join sys.tables t 
on t.object_id = mid.object_id
inner join sys.schemas s
on s.schema_id = t.schema_id
WHERE 1=1
and mid.database_id = db_id()
--and		(datediff(week, last_user_seek, getdate())) < 1
--and		migs.unique_compiles > 1
--and		migs.quartile >= 3
--and		migs.user_seeks > 10
--and		migs.avg_user_impact > 75
--and		t.name like '%pt_time_salesorder_ids%'
--order by avg_user_impact * avg_total_user_cost desc;
order by create_index_statement;

/*

--All databases

SELECT 
	mid.statement
,	unique_compiles, migs.user_seeks, migs.user_scans, last_user_seek, migs.avg_total_user_cost
, avg_user_impact, mid.equality_columns,  mid.inequality_columns, mid.included_columns
, quartile
--select *
FROM sys.dm_db_missing_index_groups mig
INNER JOIN 
(select *, quartile = NTILE(5) OVER (ORDER BY avg_total_user_cost asc) from sys.dm_db_missing_index_group_stats) migs 
ON migs.group_handle = mig.index_group_handle
--and migs.quartile = 1 --get only the top 20% of suggestions based on cost.
INNER JOIN sys.dm_db_missing_index_details mid 
ON mig.index_handle = mid.index_handle
WHERE 1=1
--and		(datediff(week, last_user_seek, getdate())) < 1
--and		migs.unique_compiles > 1
--and		migs.quartile >= 3
--and		migs.user_seeks > 10
--and		migs.avg_user_impact > 75
order by avg_user_impact * avg_total_user_cost desc 

*/

/*
--Needs Query Store to be enabled and Read/Write
--Find the latest query text for the top 10 highest anticipated improvements for user queries
--SQL Server 2019 feature ONLY
SELECT TOP 10 
    SUBSTRING
    (
            sql_text.text,
            misq.last_statement_start_offset / 2 + 1,
            (
            CASE misq.last_statement_Start_offset
                WHEN -1 THEN datalength(sql_text.text)
                ELSE misq.last_statement_end_offset
            END - misq.last_statement_start_offset
            ) / 2 + 1
    ),
    misq.*
FROM sys.dm_db_missing_index_group_stats_query AS misq
CROSS APPLY sys.dm_exec_sql_text(last_sql_handle) AS sql_text
ORDER BY avg_total_user_cost * avg_user_impact * (user_seeks + user_scans) DESC; 
*/