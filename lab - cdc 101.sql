USE cdc

GO

--Enable CDC on current database
--EXEC sys.sp_cdc_disable_db
EXEC sys.sp_cdc_enable_db

--drop TABLE dbo.cdctest
CREATE TABLE dbo.cdctest
(	ID int NOT NULL IDENTITY(1,1) 
,	text1 varchar(50) NOT NULL
,	text2 varchar(50) NOT NULL
,   CONSTRAINT [PK_cdctest] PRIMARY KEY CLUSTERED (ID) 
)
go
--SQL Server agent must be running!
EXEC sys.sp_cdc_enable_table
    @source_schema = 'dbo' -- Schema of Source Table
,   @source_name = 'cdctest' -- Name of Source Table
,   @role_name = 'cdc_Admin' -- A database role that has Access to Change Data, if new it will be created.
,   @supports_net_changes = 1 -- Supports Querying for net changes functions: cdc.fn_cdc_get_net_changes_<capture_instance>
,   @index_name = 'PK_cdctest' -- Unique Index or Primary Key of Source Table
,	@captured_column_list = 'ID, text1'
,	@capture_instance = 'dbo_cdctest'
GO
--ALTER TABLE [dbo].[cdctest] ENABLE CHANGE_TRACKING WITH(TRACK_COLUMNS_UPDATED = ON)
GO
--ALTER TABLE [dbo].[cdctest] DISABLE CHANGE_TRACKING 
GO
SELECT [name], is_tracked_by_cdc  FROM sys.tables where is_tracked_by_cdc = 1
GO  
--verify and get the instance name
exec sys.sp_cdc_help_change_data_capture

GO
--provides the create script for two functions
EXEC sys.sp_cdc_generate_wrapper_function @capture_instance = dbo_cdctest


--drop function [fn_all_changes_dbo_cdctest] 
--drop function [fn_net_changes_dbo_cdctest] 
go
   create function [fn_all_changes_dbo_cdctest]   ( @start_time datetime = null,    @end_time datetime = null,    @row_filter_option nvarchar(30) = N'all'   )   returns @resultset table ( [__CDC_STARTLSN] binary(10), [__CDC_SEQVAL] binary(10), [ID] int, [text1] varchar(50), [text2] varchar(50), [whatever] int, [__$command_id] int,  [__CDC_OPERATION] varchar(2)     ) as   begin    declare @from_lsn binary(10), @to_lsn binary(10)         if (@start_time is null)     select @from_lsn = [sys].[fn_cdc_get_min_lsn]('dbo_cdctest')    else    begin     if ([sys].[fn_cdc_map_lsn_to_time]([sys].[fn_cdc_get_min_lsn]('dbo_cdctest')) > @start_time) or        ([sys].[fn_cdc_map_lsn_to_time]([sys].[fn_cdc_get_max_lsn]()) < @start_time)      select @from_lsn = null     else      select @from_lsn = [sys].[fn_cdc_increment_lsn]([sys].[fn_cdc_map_time_to_lsn]('largest less than or equal',@start_time))    end        if (@end_time is null)     select @to_lsn = [sys].[fn_cdc_get_max_lsn]()    else    begin     if [sys].[fn_cdc_map_lsn_to_time]([sys].[fn_cdc_get_max_lsn]()) < @end_time      select @to_lsn = null     else      select @to_lsn = [sys].[fn_cdc_map_time_to_lsn]('largest less than or equal',@end_time)    end        if @from_lsn is not null and @to_lsn is not null and     (@from_lsn = [sys].[fn_cdc_increment_lsn](@to_lsn))     return         insert into @resultset    select [__$start_lsn] as [__CDC_STARTLSN], [__$seqval] as [__CDC_SEQVAL], [ID], [text1], [text2], [whatever], [__$command_id],      case [__$operation]      when 1 then 'D'      when 2 then 'I'      when 3 then 'UO'      when 4 then 'UN'      when 5 then 'M'      else null     end as [__CDC_OPERATION]       from [cdc].[fn_cdc_get_all_changes_dbo_cdctest](@from_lsn, @to_lsn, @row_filter_option) order by [__$seqval], [__$operation]        return   end
  go
   create function [fn_net_changes_dbo_cdctest]   ( @start_time datetime = null,    @end_time datetime = null,    @row_filter_option nvarchar(30) = N'all'   )   returns @resultset table (  [ID] int, [text1] varchar(50), [text2] varchar(50), [whatever] int, [__$command_id] int,  [__CDC_OPERATION] varchar(2)     ) as   begin    declare @from_lsn binary(10), @to_lsn binary(10)         if (@start_time is null)     select @from_lsn = [sys].[fn_cdc_get_min_lsn]('dbo_cdctest')    else    begin     if ([sys].[fn_cdc_map_lsn_to_time]([sys].[fn_cdc_get_min_lsn]('dbo_cdctest')) > @start_time) or        ([sys].[fn_cdc_map_lsn_to_time]([sys].[fn_cdc_get_max_lsn]()) < @start_time)      select @from_lsn = null     else      select @from_lsn = [sys].[fn_cdc_increment_lsn]([sys].[fn_cdc_map_time_to_lsn]('largest less than or equal',@start_time))    end        if (@end_time is null)     select @to_lsn = [sys].[fn_cdc_get_max_lsn]()    else    begin     if [sys].[fn_cdc_map_lsn_to_time]([sys].[fn_cdc_get_max_lsn]()) < @end_time      select @to_lsn = null     else      select @to_lsn = [sys].[fn_cdc_map_time_to_lsn]('largest less than or equal',@end_time)    end        if @from_lsn is not null and @to_lsn is not null and     (@from_lsn = [sys].[fn_cdc_increment_lsn](@to_lsn))     return         insert into @resultset    select  [ID], [text1], [text2], [whatever], [__$command_id],      case [__$operation]      when 1 then 'D'      when 2 then 'I'      when 3 then 'UO'      when 4 then 'UN'      when 5 then 'M'      else null     end as [__CDC_OPERATION]       from [cdc].[fn_cdc_get_net_changes_dbo_cdctest](@from_lsn, @to_lsn, @row_filter_option)          return   end

begin tran
INSERT INTO dbo.cdctest (text1, text2) values ('first','first')
UPDATE dbo.cdctest set text1 = 'second'
UPDATE dbo.cdctest set text1 = 'third'
UPDATE dbo.cdctest set text1 = 'fourth'
UPDATE dbo.cdctest set text2 = 'second'
UPDATE dbo.cdctest set text2 = 'third'
UPDATE dbo.cdctest set text2 = 'fourth'
commit tran
select * from cdctest

/* --Must add the user to the role group specified in the sp_cdc_enable_table parameter @role_name or will get this error:
Msg 313, Level 16, State 3, Line 1
An insufficient number of arguments were supplied for the procedure or function cdc.fn_cdc_get_all_changes_ ... .
The statement has been terminated.
*/

USE w
GO
--View CDC metadata 

		select * from dbo.fn_all_changes_dbo_cdctest ('2018-03-18 20:13:00.850','2018-03-18 20:54:00.850', 'all') --will fail, buggy if date provided precedes first recorded change
		select * from dbo.fn_all_changes_dbo_cdctest ('2018-03-18 20:13:00.850','2018-03-18 20:54:00.850', 'all with mask') --will fail, buggy if date provided precedes first recorded change
		select * from dbo.fn_all_changes_dbo_cdctest ('2018-03-18 20:13:00.850','2018-03-18 20:54:00.850', 'all with merge') --will fail, buggy if date provided precedes first recorded change
		select * from dbo.fn_net_changes_dbo_cdctest ('2018-03-18 16:51:00.850','2018-03-18 20:54:00.850', 'all') --will fail, buggy if date provided precedes first recorded change
		select * from dbo.fn_net_changes_dbo_cdctest ('2018-03-18 16:51:00.850',null, 'all with mask') --will fail, buggy if date provided precedes first recorded change
		select * from dbo.fn_net_changes_dbo_cdctest ('2018-03-18 16:51:00.850',null, 'all with merge') --will fail, buggy if date provided precedes first recorded change
		
		
		select * from dbo.fn_all_changes_dbo_cdctest ('2018-03-18 16:51:00.850','2018-03-18 20:54:00.850', 'all update old') --will fail, buggy if date provided precedes first recorded change
		select * from cdc.fn_cdc_get_all_changes_dbo_cdctest (sys.fn_cdc_map_time_to_lsn('smallest greater than','2018-03-18 16:51:00.850')
			,sys.fn_cdc_map_time_to_lsn('largest less than or equal','2018-03-18 20:54:00.850'), 'all update old')


		select * from dbo.fn_all_changes_dbo_cdctest (null,null, 'all') --returns all recorded changes
		select * from dbo.fn_net_changes_dbo_cdctest (null,null, 'all') --returns all recorded changes

		select t.name, * from cdc.change_tables ct
			inner join sys.tables t on ct.object_id = t.object_id

		select object_name(object_id), * from cdc.captured_columns where object_id = object_id('cdc.dbo_cdctest_CT')

		select * from dbo.fn_all_changes_dbo_cdctest (null,null, 'all') 
		select * from cdc.dbo_cdctest_CT order by __$start_lsn

		select 
			__$Operation = case __$operation when 1 THEN 'Delete' WHEN 2 THEN 'Insert' WHEN 3 
										THEN 'Update, before' WHEN 4 THEN 'Update, after' END
		,	PrimaryKeyID = ID
		--all data columns
		,	text1		
		 from cdc.dbo_cdctest_CT order by __$start_lsn desc, __$seqval desc

		/*
		1 = delete
		2 = insert
		3 = update (captured column values are those before the update operation). This value applies only when the row filter option 'all update old' is specified.
		4 = update (captured column values are those after the update operation)
		*/


--Test DDL changes
/*
alter table dbo.cdctest add test3 varchar(50) NULL
*/
exec sys.sp_cdc_get_ddl_history @capture_instance = dbo_cdctest

select * from cdc.ddl_history

go

--time to last lsn mapping
DECLARE @lsn binary(10);
SELECT @lsn = sys.fn_cdc_map_time_to_lsn ('largest less than or equal',getdate())
select @LSN
SELECT @lsn = sys.fn_cdc_map_time_to_lsn ('smallest greater than or equal','01/01/2010')
select @LSN

go

--Test whether an updated row will appear as changed.
		INSERT INTO dbo.cdctest (text1, text2) values ('eleven','eleven')
		UPDATE dbo.cdctest set  text1= 'twelve', text2 = 'twelve' where text2= 'eleven'
		UPDATE dbo.cdctest set  text1= 'twelve'  where text1= 'twelve' --note that this will not generate a new Change record
		UPDATE dbo.cdctest set  text1= 'twelve'  where text1= 'twelve' --note that this will not generate a new Change record
		UPDATE dbo.cdctest set  text1= 'twelve'  where text1= 'twelve' --note that this will not generate a new Change record
		go
		select * from dbo.cdctest 

		--The new records may take a few seconds to asynchronously show up below.
		--Noticed that for the newest PrimaryKeyID, there is an insert, a single update pair, and no other data indicating that twelve was updated to twelve
		select 
			Operation = case __$operation when 1 THEN 'Delete' WHEN 2 THEN 'Insert' WHEN 3 THEN 'Update, before' WHEN 4 THEN 'Update, after' END
		,	PrimaryKeyID = ID
		,	text1 
		,	__$start_lsn
		,	__$seqval 
		 from cdc.dbo_cdctest_CT 
		 order by __$start_lsn desc, __$seqval desc
 
go

--Must disable CDC before changing the PK

	
		--drop existing PK
		ALTER TABLE [dbo].cdctest DROP CONSTRAINT PK_cdctest 
		GO
 
		--add new PK Clustered index nonclustered indexes
		ALTER TABLE [dbo].cdctest ADD  CONSTRAINT PK_cdctest PRIMARY KEY CLUSTERED 
		(
			[ID] ASC
		)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = ON
		, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90, DATA_COMPRESSION = PAGE) ON [PRIMARY]
		GO

	
		--disable CDC
		EXEC sys.sp_cdc_disable_table
				@source_schema = N'dbo',
				@source_name = N'cdctest',
				@capture_instance = N'dbo_cdctest'
        
		GO
		--drop existing PK
		ALTER TABLE [dbo].cdctest DROP CONSTRAINT PK_cdctest 
		GO
 
		--add new PK Clustered index nonclustered indexes
		ALTER TABLE [dbo].cdctest ADD  CONSTRAINT PK_cdctest PRIMARY KEY CLUSTERED 
		(
			[ID] ASC
		)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = ON
		, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 90, DATA_COMPRESSION = PAGE) ON [PRIMARY]
		GO
