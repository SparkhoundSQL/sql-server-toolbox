--This script only works in SQL2008R2SP2+ or SQL2012SP1+

--TODO BEFORE EXECUTING: comment out three lines below in <SQL2014 because incremental stastics not supported.
--https://msdn.microsoft.com/en-us/library/jj553546.aspx
--http://sqlperformance.com/2014/02/sql-statistics/2014-incremental-statistics
--https://connect.microsoft.com/SQLServer/feedback/details/468517/update-statistics-at-the-partition-level

    SELECT distinct
		   s.name AS SchemaName 
          ,o.name AS ObjectName 
          ,sta.name AS StatName 
		  , Object_Type = ISNULL(i.type_desc + ' Index', 'Statistics Object')
          , Stats_Last_Updated = ISNULL(sp.last_updated, o.create_date)
		  , Rows_Changed = ISNULL(sp.modification_counter,0) --Rows Changed since last update
		 , PartitionNumber = CASE WHEN MAX(p.partition_number) OVER (PARTITION by sta.name, i.name)  > 1 THEN p.partition_number ELSE null END
		  , sta.is_incremental --Only works in SQL 2014+, comment out this line in prior versions.
		 , TSQL = CASE WHEN i.type_desc like '%columnstore%' THEN NULL ELSE
			N'UPDATE STATISTICS ' 
               + QUOTENAME(s.name) + N'.' + QUOTENAME(o.name) + N' ' 
               + QUOTENAME(sta.name) + N' ' 
			   + 'WITH RESAMPLE'
			   + CASE WHEN 
						sta.is_incremental = 1 and  --Only works in SQL 2014+, comment out this line in prior versions.
						MAX(p.partition_number) OVER (PARTITION by sta.name, i.name)  > 1 THEN ' ON PARTITIONS (' + cast(p.partition_number as varchar(5)) + ') ' ELSE '' END
               
			END
   FROM sys.objects  o   
		 INNER JOIN sys.stats sta ON sta.object_id = o.object_id  
			CROSS APPLY sys.dm_db_stats_properties (sta.object_id, sta.stats_id) sp -- Only works in SQL2008R2SP2+ or SQL2012SP1+
         INNER JOIN sys.schemas AS s 
             ON o.schema_id = s.schema_id 
		 LEFT OUTER JOIN sys.indexes as i
			on i.index_id = sta.stats_id
			
	     LEFT OUTER join sys.dm_db_partition_stats p 
			on (
			sta.is_incremental = 1 and  --Only works in SQL 2014+, comment out this line in prior versions. 
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
             ON IUS.object_id = sta.object_id 
    WHERE o.type IN ('U', 'V')    -- only user tables and views 
          --AND DATEDIFF(d, ISNULL(STATS_DATE(sta.object_id, sta.stats_id), N'1900-01-01')  , IUS.LastUpdate) > 30 --indexes that haven't been updated in the last month
		  --AND sp.modification_counter > 1000
    ORDER BY Rows_Changed desc, Stats_Last_Updated desc

	/*

	UPDATE STATISTICS [sales].[sales] [PK__sales__3213E83F11F8B16A] WITH RESAMPLE 

	*/


