/* Automated index maint script
Added by William Assaf, Sparkhound 20140304
Last Modified by William Assaf, Sparkhound 20170922, integrated smart stats updates
--Primary objective is to never perform an offline index rebuild unless it is the only option.
*/
--#TODO For each database:
--Change name after USE below
--Change name in ALTER ... BULK_LOGGED below
--Change name in ALTER ... FULL near end

--USE WideWorldImporters --#TODO Change database name
GO
DECLARE @TestMode		bit
DECLARE @StartWindow	tinyint
DECLARE @EndWindow		tinyint

SELECT @TestMode	 =	1	-- flip to 1 to run out of cycle, without actually executing any code.
SELECT @StartWindow	 =	0	-- Range (0-23). 24-hour of the day. Ex: 4 = 4am, 16 = 4pm. 0 = midnight.
SELECT @EndWindow	 =	23	-- Range (0-23). 24-hour of the day. Ex: 4 = 4am, 16 = 4pm. 0 = midnight.

SET XACT_ABORT ON;

BEGIN TRY 

		--IF @TestMode = 0 
		--ALTER DATABASE wideWorldImporters SET RECOVERY BULK_LOGGED; --#TODO Change database name

		SET NOCOUNT ON;

		DECLARE @objectid int
		, @indexid int
		, @partitioncount bigint
		, @SchemaName sysname
		, @ObjectName sysname
		, @indexname sysname
		, @partitionnum bigint
		, @partitions bigint
		, @frag float
		, @Command varchar(8000)
		, @Can_Reorg bit
		, @Can_RebuildOnline nvarchar(60)
		, @Can_Compress bit
		, @ProductVersion varchar(15)
	    , @ServerEdition varchar(30)

       SET @ServerEdition = convert(varchar(30),(SELECT SERVERPROPERTY('Edition')))
	   SET @ProductVersion = convert(varchar(15),(SELECT SERVERPROPERTY('ProductVersion')))

		-- ensure the temporary table does not exist
		IF EXISTS (SELECT name FROM tempdb.sys.objects WHERE name like '%C__work_to_do%')
			DROP TABLE #C__work_to_do;

		CREATE TABLE #C__work_to_do
		(
		  objectid			int		NOT NULL
		, indexid			int		NOT NULL
		, partitionnum		int		NOT NULL
		, frag				decimal(9,2)	NOT NULL
		, Can_Reorg			bit		NOT NULL
		, Can_RebuildOnline	bit		NOT NULL
		, Can_Compress		bit		NOT NULL
		, indexname			sysname	NOT NULL,

		PRIMARY KEY (  objectid, indexid, partitionnum	)
		)

		-- conditionally select from the function, converting object and index IDs to names.
		INSERT INTO #C__work_to_do
		(  objectid			
		, indexid			
		, partitionnum		
		, frag				
		, Can_Reorg			
		, Can_RebuildOnline	
		, Can_Compress
		, indexname			
		)
			SELECT  
					objectid		=	s.object_id
				,	indexid			=	s.index_id
				,	partitionnum	=	s.partition_number
				,	frag			=	max(s.avg_fragmentation_in_percent)
				,	Can_Reorg		=	i.ALLOW_PAGE_LOCKS --An index cannot be reorganized when ALLOW_PAGE_LOCKS is set to 0.
				,Can_RebuildOnline	=	
						CASE 
							WHEN A.index_id is not null and A.user_type_id is not null 
								THEN 0 -- Cannot do ONLINE REBUILDs with certain data types in the index (key or INCLUDE).
							WHEN A.index_id is null and s.index_id <= 1 and A.user_type_id is not null 
								THEN 0 -- Cannot do ONLINE REBUILDs with certain data types in the index (key or INCLUDE).
							WHEN i.type_desc in ('xml','spatial') THEN 0 -- Cannot do ONLINE REBUILDs for certain index types.
							WHEN (left(@ProductVersion,2) >= 10 ) and (@ServerEdition like 'Developer%' or @ServerEdition like 'Enterprise%' )
								THEN 1
							ELSE 0
						END
				,	Can_Compress	=	CASE	WHEN
									   (left(@ProductVersion,2) >= 10 ) and (@ServerEdition like 'Developer%' or @ServerEdition like 'Enterprise%' )
											THEN 1
											ELSE 0
										END
				,	indexname		=	i.name --select object_name(object_id), * 
			FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL , NULL, 'LIMITED') s
			inner join --select * from
			sys.indexes i on s.object_id = i.object_id and s.index_id = i.index_id
			left outer join 
			(
				select 
					c.object_id, ic.index_id, user_type_id = COALESCE(t.user_type_id, null)
				from sys.columns c
				left outer join sys.index_columns ic
				on ic.object_id = c.object_id
				and ic.column_id = c.column_id 
				left outer join sys.types t 
				on c.user_type_id = t.user_type_id
				WHERE 
				( t.name in (N'image', N'text', N'ntext', N'xml')
							or	(t.name in ('varchar', 'nvarchar', 'varbinary') 
								 and c.max_length = -1 --indicates (MAX)
								)
						)
			) A 
			on i.object_id = A.object_id
			AND i.index_id = A.index_id
			WHERE 		
				1=1
			AND	s.avg_fragmentation_in_percent > 10.0 
			AND s.index_id > 0 --
			AND s.page_count > 1280 --12800 pages is 100mb
			and i.name is not null
			group by 
					s.object_id
				,	s.index_id
				,	s.partition_number
				,	i.ALLOW_PAGE_LOCKS
				,	A.index_id
				,	A.user_type_id
				,	i.type_desc
				,	i.name; 
		
		IF CURSOR_STATUS('local', 'curIndexPartitions') >= 0
		BEGIN
		 	CLOSE curIndexPartitions;
			DEALLOCATE curIndexPartitions;
		END
		
		-- Declare the cursor for the list of partitions to be processed.
		DECLARE curIndexPartitions CURSOR LOCAL FAST_FORWARD FOR 
		SELECT * FROM #C__work_to_do;
		
		-- Open the cursor.
		OPEN curIndexPartitions;

		-- Loop through the partitions.
		FETCH NEXT
		   FROM curIndexPartitions
		   INTO @objectid, @indexid, @partitionnum, @frag, @Can_Reorg, @Can_RebuildOnline, @Can_Compress, @indexname;

		WHILE @@FETCH_STATUS = 0
			BEGIN
				BEGIN TRY 
				
						DECLARE @currenthour	int =	datepart(hour, sysdatetime())

						IF(@StartWindow > @EndWindow -- wraps midnight
							AND (	@currenthour >= @StartWindow 
								OR	(@currenthour <= @StartWindow 
								AND @currenthour < @EndWindow)
								)

							)
							OR 
							(@StartWindow <= @EndWindow -- AM only or PM only
							AND @currenthour >= @StartWindow 
							and @currenthour < @EndWindow
							)
							OR
							@TestMode = 1
						BEGIN --Begin Time frame
					
								SELECT @ObjectName = o.name
									,	@SchemaName  = s.name
								FROM sys.objects AS o
								INNER JOIN sys.schemas as s ON s.schema_id = o.schema_id
								WHERE o.object_id = @objectid;
			        			
								--SELECT @objectid, @indexid, @partitionnum, @frag, @Can_Reorg, @Can_RebuildOnline, @indexname, @ObjectName, @SchemaName
					
								SELECT @partitioncount = count (*) 
								FROM sys.partitions
								WHERE object_id = @objectid AND index_id = @indexid;
			       
								SELECT @Command = '';

								-- 30 is an arbitrary decision point at which to switch between reorganizing and rebuilding
								IF @frag < 30.0 and @Can_Reorg = 1
									BEGIN
						
										--print '0';
							
										SELECT @Command = 'ALTER INDEX [' + @indexname + '] ON [' + @SchemaName + '].[' + @ObjectName + '] REORGANIZE ';
							
										IF @partitioncount > 1
											SELECT @Command = @Command + ' PARTITION=' + CONVERT (CHAR, @partitionnum);
								
										SELECT @Command = @Command + '; UPDATE STATISTICS [' + @SchemaName + '].[' + @ObjectName + '] ([' + @indexname + ']); '
							
									END
						
								IF @frag >= 60.0
									BEGIN
							
										--Doing an INDEX REBUILD with ONLINE = ON reduces the impact of locking to the production server, 
										--	though it will still create resource contention by keeping the drives and tempdb busy.
										--  Unlike REORGANIZE steps, a REBUILD also updates the STATISTICS of an index.
										IF @Can_RebuildOnline = 1
										BEGIN
											--print '1'
							
											SELECT @Command = 'ALTER INDEX [' + @indexname +'] ON [' + @SchemaName + '].[' + @ObjectName + '] REBUILD ';
								
											IF @partitioncount > 1
												SELECT @Command = @Command + ' PARTITION=' + CONVERT (CHAR, @partitionnum);
									
											SELECT @Command = @Command + ' WITH (ONLINE = ON'
								
											IF @Can_Compress = 1
											SELECT @Command = @Command + ', DATA_COMPRESSION = PAGE'
		
											select @Command = @Command + ');'
										END
							
										--REORGANIZE processes are always ONLINE and are less intense than REBUILDs.  
										ELSE IF @Can_Reorg = 1
										BEGIN
							
											--print '2'
							
											SELECT @Command = 'ALTER INDEX [' + @indexname +'] ON [' + @SchemaName + '].[' + @ObjectName + '] REORGANIZE ';
								
											IF @partitioncount > 1
												SELECT @Command = @Command + ' PARTITION=' + CONVERT (CHAR, @partitionnum);
								
											SELECT @Command = @Command + '; UPDATE STATISTICS [' + @SchemaName + '].[' + @ObjectName + '] ([' + @indexname + ']); '
								
										END
							
										--OPTIONAL: Only do a full, offline index rebuild in the middle of the night.
										--ELSE IF datepart(hour, sysdatetime()) < 3 --inclusive both hours.
										ELSE 
										BEGIN	
							
											--print '3'		
								
											SELECT @Command = 'ALTER INDEX [' + @indexname + '] ON [' + @SchemaName + '.' + @ObjectName + '] REBUILD';
								
											IF @partitioncount > 1
												SELECT @Command = @Command + ' PARTITION = ' + CONVERT (CHAR, @partitionnum);
															
											IF @Can_Compress = 1						
												SELECT @Command = @Command + ' WITH (DATA_COMPRESSION = PAGE); '
								
										
										END
									END
								IF @Command <> ''
								BEGIN
									INSERT INTO DBALogging.dbo.IndexMaintLog (CurrentDatabase, Command, ObjectName, BeginTimeStamp, StartWindow, EndWindow, TestMode)
									SELECT DB_NAME(), @Command, '[' + DB_Name() + '].[' + @ObjectName + '].[' + @SchemaName + ']', sysdatetime(), @StartWindow, @EndWindow, @TestMode
						
									BEGIN TRY 
										IF @TestMode = 0 EXEC (@Command);

										PRINT N'Executed:  ' + @Command + ' Frag level: ' + str(@frag)
										UPDATE DBALogging.dbo.IndexMaintLog 
										SET EndTimeStamp = sysdatetime()
										,	Duration_s = datediff(s, BeginTimeStamp, sysdatetime())
										where id = SCOPE_IDENTITY() and EndTimeStamp is null

									END TRY 
									BEGIN CATCH
										Print N'Error: ' + ERROR_MESSAGE()
										UPDATE DBALogging.dbo.IndexMaintLog 
										SET ErrorMessage = cast(ERROR_NUMBER() as char(9)) + ERROR_MESSAGE()
										where id = SCOPE_IDENTITY() and EndTimeStamp is null
									END CATCH
	
								END



						END --End Time frame
						
				END TRY
				BEGIN CATCH
					PRINT N'Failed to execute the command:  ' + @Command + N' Error Message: ' + ERROR_MESSAGE()
				END CATCH

			FETCH NEXT FROM curIndexPartitions 
				INTO @objectid, @indexid, @partitionnum, @frag, @Can_Reorg, @Can_RebuildOnline, @Can_Compress, @indexname;
			END

		-- Close and deallocate the cursor.
		IF CURSOR_STATUS('local', N'curIndexPartitions') >= 0
		BEGIN
		 	CLOSE curIndexPartitions;
			DEALLOCATE curIndexPartitions;
		END

		-- drop the temporary table
		IF EXISTS (SELECT name FROM tempdb.sys.objects WHERE name like '%C__work_to_do%')
		DROP TABLE #C__work_to_do;

		--Begin smart update stats

		select @currenthour	=	datepart(hour, sysdatetime())

		IF(@StartWindow > @EndWindow -- wraps midnight
			AND (	@currenthour >= @StartWindow 
				OR	(@currenthour <= @StartWindow 
				AND @currenthour < @EndWindow)
				)

			)
			OR 
			(@StartWindow <= @EndWindow -- AM only or PM only
			AND @currenthour >= @StartWindow 
			and @currenthour < @EndWindow
			)
			OR
			@TestMode = 1
		BEGIN
			declare @tsqllist table (id int not null identity(1,1) primary key, SchemaName sysname, ObjectName sysname, tsqltext nvarchar(4000) not null) 
			
			insert into @tsqllist ( SchemaName, ObjectName, tsqltext) 
			 SELECT distinct
						s.Name AS SchemaName 
					  , o.Name AS ObjectName 
					 -- , STA.name AS StatName 
					 -- , Object_Type = ISNULL(i.type_desc + ' Index', 'Statistics Object')
					 -- , Stats_Last_Updated = ISNULL(sp.last_updated, o.create_date)
					 -- , Rows_Changed = ISNULL(sp.modification_counter,0) --Rows Changed since last update
					 -- , PartitionNumber = CASE WHEN MAX(p.partition_number) OVER (PARTITION by STA.name, i.name)  > 1 THEN p.partition_number ELSE null END
					 -- , STA.is_incremental, --Only works in SQL 2014+, comment out this line in prior versions.
				, tsqltext = CASE WHEN i.type_desc like '%columnstore%' THEN NULL ELSE
						N'UPDATE STATISTICS '
							+ QUOTENAME(s.name) + N'.' + QUOTENAME(o.name) + N' '
							+ QUOTENAME(STA.name) + N' '
							+ 'WITH RESAMPLE'
							+ CASE WHEN 
			--						STA.Is_Incremental = 1 and  --Only works in SQL 2014+, comment out this line in prior versions.
									MAX(p.partition_number) OVER (PARTITION by STA.name, i.name)  > 1 THEN ' ON PARTITIONS (' + cast(p.partition_number as varchar(5)) + ') ' ELSE '' END
								END
			   FROM sys.objects  o   
					 INNER JOIN sys.stats STA ON STA.object_id = o.object_id  
						CROSS APPLY sys.dm_db_stats_properties (STA.object_id, STA.stats_id) sp -- Only works in SQL2008R2SP2+ or SQL2012SP1+
					 INNER JOIN sys.schemas AS s 
						 ON o.schema_id = s.schema_id 
					 LEFT OUTER JOIN sys.indexes as i
						on i.index_id = STA.stats_id
						and (i.type_desc not like '%columnstore%')
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
				WHERE o.type IN ('U', 'V')    -- only user tables and views 
					  AND DATEDIFF(d, ISNULL(STATS_DATE(STA.object_id, STA.stats_id), N'1900-01-01')  , IUS.LastUpdate) > 30 --indexes that haven''t been updated in the last month
					  AND sp.modification_counter > 10000
				OPTION (MAXDOP 1);

			--select * from @tsqllist

			declare @s int = 1, @scount int = null, @runtsql nvarchar(4000) = null
			select @scount = max(id) from @tsqllist l
			while (@s <= @scount)
			BEGIN
					--Check that we are still in  time frame
					select @currenthour	=	datepart(hour, sysdatetime())
					IF(@StartWindow > @EndWindow -- wraps midnight
						AND (	@currenthour >= @StartWindow 
							OR	(@currenthour <= @StartWindow 
							AND @currenthour < @EndWindow)
							)

						)
						OR 
						(@StartWindow <= @EndWindow -- AM only or PM only
						AND @currenthour >= @StartWindow 
						and @currenthour < @EndWindow
						)
						OR
						@TestMode = 1
					BEGIN
						print 'beginning stats'
						--actually executes the scripts.
						select	@runtsql = tsqltext
							,	@ObjectName = ObjectName
							,	@SchemaName	 = SchemaName
						 from @tsqllist where id = @s
						
						INSERT INTO DBALogging.dbo.IndexMaintLog (CurrentDatabase, Command, ObjectName, BeginTimeStamp, StartWindow, EndWindow, TestMode)
						SELECT DB_NAME(), @runtsql, '[' + DB_Name() + '].[' + @ObjectName + '].[' + @SchemaName + ']', sysdatetime(), @StartWindow, @EndWindow, @TestMode
						
						BEGIN TRY 
							IF @TestMode = 0 EXEC (@runtsql);

							PRINT N'Executed:  ' + @runtsql 
							UPDATE DBALogging.dbo.IndexMaintLog 
							SET EndTimeStamp = sysdatetime()
							,	Duration_s = datediff(s, BeginTimeStamp, sysdatetime())
							where id = SCOPE_IDENTITY() and EndTimeStamp is null

						END TRY 
						BEGIN CATCH
							Print N'Error: ' + ERROR_MESSAGE()
							UPDATE DBALogging.dbo.IndexMaintLog 
							SET ErrorMessage = cast(ERROR_NUMBER() as char(9)) + ERROR_MESSAGE()
							where id = SCOPE_IDENTITY() and EndTimeStamp is null
						END CATCH


						set @s = @s + 1

					END
			END
		
			print 'end update stats'
		END

		--IF @TestMode = 0 
		--ALTER DATABASE [WideWorldImporters] SET RECOVERY FULL --#TODO Change database name

	END TRY
	BEGIN CATCH
		PRINT N'Failed to execute. Error Message: ' + ERROR_MESSAGE()
		INSERT INTO DBALogging.dbo.IndexMaintLog (CurrentDatabase, ErrorMessage , BeginTimeStamp, TestMode)
		SELECT DB_NAME(), cast(ERROR_NUMBER() as char(9)) + ERROR_MESSAGE(),  sysdatetime(), @TestMode
		
		IF EXISTS (SELECT name FROM tempdb.sys.objects WHERE name like '%C__work_to_do%')
		DROP TABLE #C__work_to_do;

		IF CURSOR_STATUS('local', N'curIndexPartitions') >= 0
		BEGIN
		 	CLOSE curIndexPartitions;
			DEALLOCATE curIndexPartitions;
		END


	END CATCH
GO

/*
DROP TABLE DBALogging.dbo.IndexMaintLog;
CREATE TABLE DBALogging.dbo.IndexMaintLog
(	id int not null identity(1,1) PRIMARY KEY
,	CurrentDatabase sysname not null DEFAULT (DB_NAME())
,	Command nvarchar(1000) null
,	ObjectName nvarchar(100) null 
,	BeginTimeStamp	datetime2(0)  null 
,	TestMode bit  null
,	StartWindow tinyint  null
,	EndWindow tinyint  null
,	EndTimeStamp datetime2(0) null
,	Duration_s int null
,	ErrorMessage nvarchar(4000) null
)

alter table DBALogging.dbo.IndexMaintLog
alter column BeginTimeStamp	datetime2(2)  null 

alter table DBALogging.dbo.IndexMaintLog
alter column EndTimeStamp	datetime2(2)  null 


select * from DBALogging.dbo.indexmaintlog

*/
