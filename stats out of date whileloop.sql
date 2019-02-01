--This script only works in SQL2008R2SP2+ or SQL2012SP1+. 

--This generates an UPDATE STATISTICS script for all databases. Can be used in a maintenance plan (see bottom). Safe to execute. 
--This version does not work in Azure SQL DB. Instead, see toolbox\stats out of date.sql.
--Use toolbox\stats out of date.sql to examine a particular database.

--TODO BEFORE EXECUTING: comment out three lines below in <SQL2014 because incremental stastics not supported.

declare @tsql nvarchar(max) = 
 N'use [?];
    SELECT distinct
--			s.name AS SchemaName 
--          , o.name AS ObjectName 
--          , STA.name AS StatName 
--		  , Object_Type = ISNULL(i.type_desc + '' Index'', ''Statistics Object'')
--          , Stats_Last_Updated = ISNULL(sp.last_updated, o.create_date)
--		  , Rows_Changed = ISNULL(sp.modification_counter,0) --Rows Changed since last update
--		  , PartitionNumber = CASE WHEN MAX(p.partition_number) OVER (PARTITION by STA.name, i.name)  > 1 THEN p.partition_number ELSE null END
----		  , STA.is_incremental --Only works in SQL 2014+, comment out this line in prior versions.
--		  , ''[?]'' AS [?],
		   TSQL = CASE WHEN i.type_desc like ''%columnstore%'' THEN NULL ELSE
		    N''USE [?]; '' + 
			N''UPDATE STATISTICS '' 
               + QUOTENAME(s.name) + N''.'' + QUOTENAME(o.name) + N'' '' 
               + QUOTENAME(STA.name) + N'' '' 
			   + ''WITH RESAMPLE''
			   + CASE WHEN 
						STA.Is_Incremental = 1 and  --Only works in SQL 2014+, comment out this line in prior versions.
						MAX(p.partition_number) OVER (PARTITION by STA.name, i.name)  > 1 THEN '' ON PARTITIONS ('' + cast(p.partition_number as varchar(5)) + '') '' ELSE '''' END
               
			END
   FROM sys.objects  o   
		 INNER JOIN sys.stats STA ON STA.object_id = o.object_id  
			CROSS APPLY sys.dm_db_stats_properties (STA.object_id, STA.stats_id) sp -- Only works in SQL2008R2SP2+ or SQL2012SP1+
         INNER JOIN sys.schemas AS s 
             ON o.schema_id = s.schema_id 
		 LEFT OUTER JOIN sys.indexes as i
			on i.index_id = STA.stats_id
			and (i.type_desc not like ''%columnstore%'')
	     LEFT OUTER join sys.dm_db_partition_stats p 
			on (
			STA.Is_Incremental = 1 and  --Only works in SQL 2014+, comment out this line in prior versions. 
			p.object_id = o.object_id  and 
			i.index_id = p.index_id
			)
         LEFT JOIN 
         (SELECT IUS.object_id 
                ,MIN(ISNULL(IUS.last_user_update, IUS.last_system_update)) AS LastUpdate 
          FROM sys.dm_db_index_usage_stats AS IUS 
          WHERE database_id = DB_ID() 
                AND NOT ISNULL(IUS.last_user_update, IUS.last_system_update) IS NULL 
          GROUP BY IUS.object_id 
         ) AS IUS 
             ON IUS.object_id = STA.object_id 
    WHERE o.type IN (''U'', ''V'')    -- only user tables and views 
          AND DATEDIFF(d, ISNULL(STATS_DATE(STA.object_id, STA.stats_id), N''1900-01-01'')  , IUS.LastUpdate) > 30 --indexes that haven''t been updated in the last month
		  AND sp.modification_counter > 10000
    OPTION (MAXDOP 1);
	print ''[?]'' '

declare @dblist table (id int not null identity(1,1) primary key, dbname sysname not null)
declare @tsqllist table (id int not null identity(1,1) primary key, tsqltext nvarchar(4000) not null) 
declare @x int = 1, @xmax int = null, @dbname sysname, @runtsql nvarchar(max) = null
insert into @dblist 
select name from sys.databases
where state_desc = 'online' and (database_id > 4 or name = 'msdb')
select @xmax = max(id) from @dblist l

while (@x <= @xmax)
BEGIN
	select @dbname = dbname from @dblist l where @x = id

	select @runtsql = replace(@tsql, N'?', @dbname)

	--generates scripts, does not actually perform the UPDATE STATISTICS. See below.
	--Writes all the TSQL into a table variable which is displayed later
	insert into @tsqllist (tsqltext) 
	exec sp_executesql @runtsql --safe, does not actually update stats
	
	set @x = @x + 1
END

--Shows all stats in all databases that need to be updated
select * from @tsqllist

--OPTIONALLY - execute all UPDATE Stats
/*
declare @s int = 1, @scount int = null
select @scount = max(id), @runtsql = null from @tsqllist l
while (@s <= @scount)
BEGIN
	
	--actually executes the scripts.
	select @runtsql = tsqltext from @tsqllist where id = @s
	exec sp_executesql @runtsql
	
	set @s = @s + 1
	
END
*/




/*

USE [WideWorldImporters]; UPDATE STATISTICS [Sales].[InvoiceLines] [_WA_Sys_0000000D_1E6F845E] WITH RESAMPLE
USE [WideWorldImporters]; UPDATE STATISTICS [Sales].[Invoices] [_WA_Sys_0000000A_7849DB76] WITH RESAMPLE

*/
