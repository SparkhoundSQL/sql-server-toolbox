--TODO Set current database context to desired database.
--This only checks current database context.
--Use toolbox\stats out of date whileloop.sql to scan all databases.

--TODO BEFORE EXECUTING: comment out three lines below in <SQL2014 because incremental stastics not supported.

--This script only works in SQL2008R2SP2+ or SQL2012SP1+. Works in Azure SQL DB.
	
	SELECT distinct
			s.name AS SchemaName 
          , o.name AS ObjectName 
          , STA.name AS StatName 
		  , Object_Type = ISNULL(i.type_desc + ' Index', 'Statistics Object')
          , Stats_Last_Updated = ISNULL(sp.last_updated, o.create_date)
		  , Rows_Changed = ISNULL(sp.modification_counter,0) --Rows Changed since last update
		  , PartitionNumber = CASE WHEN MAX(p.partition_number) OVER (PARTITION by STA.name, i.name)  > 1 THEN p.partition_number ELSE null END --Only works in SQL 2014+, comment out this line in prior versions.
		  , STA.is_incremental --Only works in SQL 2014+, comment out this line in prior versions.
		  
		  
		  , TSQL = CASE WHEN i.type_desc like '%columnstore%' THEN NULL ELSE
		    N'UPDATE STATISTICS '
               + QUOTENAME(s.name) + N'.' + QUOTENAME(o.name) + N' '
               + QUOTENAME(STA.name) + N' '
			   + 'WITH RESAMPLE'
			
				--Below block only works in SQL 2014+, comment out this line in prior versions.
			   + CASE WHEN 
						STA.Is_Incremental = 1 and  
						MAX(p.partition_number) OVER (PARTITION by STA.name, i.name)  > 1 THEN ' ON PARTITIONS (' + cast(p.partition_number as varchar(5)) + ') ' ELSE '' END--Only works in SQL 2014+, comment out this line in prior versions.
			             
			END
			, Stats_Update_History = 'DBCC TRACEON(2388);
DBCC SHOW_STATISTICS('''+QUOTENAME(s.name) + N'.' + QUOTENAME(o.name)+''','''+STA.name+''');
DBCC TRACEOFF(2388);' --This will execute in a single line, but to get the line breaks in SSMS, Tools, Options, Query Results - SQL Server - Results to Grid, then check "Retain CR/LF on copy or save", and close/open the query window.

   FROM sys.objects  o   
		 INNER JOIN sys.stats STA ON STA.object_id = o.object_id  
			CROSS APPLY sys.dm_db_stats_properties (STA.object_id, STA.stats_id) sp -- Only works in SQL2008R2SP2+ or SQL2012SP1+
         INNER JOIN sys.schemas AS s 
             ON o.schema_id = s.schema_id 
		 LEFT OUTER JOIN sys.indexes as i
			on i.index_id = STA.stats_id
			and (i.type_desc not like '%columnstore%')
	     
		 --Below joinonly works in SQL 2014+, comment out this line in prior versions.
			
		LEFT OUTER join sys.dm_db_partition_stats p 
			on (
			STA.Is_Incremental = 1 and  --Only works in SQL 2014+, comment out this line in prior versions. 
			p.object_id = o.object_id and i.index_id = p.index_id
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
    WHERE o.type IN ('U', 'V')    -- only user tables and views 
        --  AND DATEDIFF(d, ISNULL(STATS_DATE(STA.object_id, STA.stats_id), N'1900-01-01')  , IUS.LastUpdate) > 30 --indexes that haven''t been updated in the last month
		--  AND sp.modification_counter > 10000
    ORDER BY Rows_Changed desc, Stats_Last_Updated desc
	OPTION (MAXDOP 1);


	/*

	UPDATE STATISTICS [sales].[sales] [PK__sales__3213E83F11F8B16A] WITH RESAMPLE 
	UPDATE STATISTICS [dbo].[cttest] [PK__cttest__3213E83F99EB5853] WITH RESAMPLE

	*/

	/*

	--Stats update history
	DBCC TRACEON(2388);  DBCC SHOW_STATISTICS('[dbo].[cttest]','PK__cttest__3213E83F99EB5853');  DBCC TRACEOFF(2388);  

	*/
	

--https://msdn.microsoft.com/en-us/library/jj553546.aspx
--http://sqlperformance.com/2014/02/sql-statistics/2014-incremental-statistics
--https://connect.microsoft.com/SQLServer/feedback/details/468517/update-statistics-at-the-partition-level
