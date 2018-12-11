--Last Update: 12/11/2018

IF OBJECT_ID('tempdb..#DBSettings') IS NOT NULL
    BEGIN
	   DROP TABLE #DBSettings;
    END;

select 
	name
,	[compatibility_level]	--should be latest (130 = SQL2016, 120 = SQL2014, 110 = SQL2012, 100 = SQL2008, 90 = SQL2005)
,	[dbstate] = case when state_desc = 'online' and is_read_only = 1 then state_desc + ' ' +'(Read-Only)' else state_desc end 		
,	recovery_model_desc
,	page_verify_option_desc
,	user_access_desc				--should be MULTI_USER
,	is_auto_close_on				--should be 0
,	is_auto_shrink_on				--should be 0
,	is_auto_create_stats_on			--should be 1 except for some SharePoint db's
,	is_auto_update_stats_on			--should be 1 except for some SharePoint db's
,	is_auto_update_stats_async_on	--should be 1 except for some SharePoint db's
,	log_reuse_wait
,	log_reuse_wait_desc
,	target_recovery_time_in_seconds
into #DBSettings
from sys.databases
--where state_desc = 'ONLINE'

--Compatibility Level Check
select
 	[Database Name]			= name
,	[Compatibility Level]	= [compatibility_level]
,	[SQL Server Version]	= SERVERPROPERTY('ProductVersion')
,	[State]					= dbstate		
from #DBSettings
order by [compatibility_level]

--Databases where page verify option is not CHECKSUM
select
 	[Database Name]			= name
,	[Page Verify Option]	= page_verify_option_desc
,	[Alter]					= 'ALTER DATABASE [' + name +'] SET PAGE_VERIFY CHECKSUM WITH NO_WAIT;'
,	[Revert]				= 'ALTER DATABASE [' + name +'] SET PAGE_VERIFY ' + page_verify_option_desc COLLATE DATABASE_DEFAULT + ' WITH NO_WAIT;'
,	[State]					= dbstate		
from #DBSettings
where page_verify_option_desc <> 'CHECKSUM'

--Databases where auto-close and/or auto-shrink is enabled
select 
 	[Database Name]			= name
,	[Is Auto Close On]		= is_auto_close_on		--should be 0
,	[Is Auto Shrink On]		= is_auto_shrink_on		--should be 0
,	[Alter]					= CASE
									WHEN is_auto_close_on = 1 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CLOSE OFF WITH NO_WAIT;'
									WHEN is_auto_shrink_on = 1 THEN 'ALTER DATABASE [' + name + '] SET AUTO_SHRINK OFF WITH NO_WAIT;'
									WHEN is_auto_close_on = 1 AND is_auto_shrink_on = 1 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CLOSE OFF WITH NO_WAIT; ALTER DATABASE [' + name + '] SET AUTO_SHRINK OFF WITH NO_WAIT;'
							  ELSE 'N/A'
							  END
,	[Revert]				= CASE
									WHEN is_auto_close_on = 1 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CLOSE ON WITH NO_WAIT;'
									WHEN is_auto_shrink_on = 1 THEN 'ALTER DATABASE [' + name + '] SET AUTO_SHRINK ON WITH NO_WAIT;'
									WHEN is_auto_close_on = 1 AND is_auto_shrink_on = 1 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CLOSE ON WITH NO_WAIT; ALTER DATABASE [' + name + '] SET AUTO_SHRINK ON WITH NO_WAIT;'
							  ELSE 'N/A'
							  END
,	[State]					= dbstate	
from #DBSettings
where is_auto_close_on = 1		
   OR is_auto_shrink_on	= 1	

--Databases where auto create and/or auto update stats is disabled
select 
	[Database Name]					= name
,	[Is Auto Create Stats On]		= is_auto_create_stats_on		--should be 1 except for some SharePoint db's
,	[Is Auto Update Stats On]		= is_auto_update_stats_on		--should be 1 except for some SharePoint db's
,	[Is Auto Update Stats Async On]	= is_auto_update_stats_async_on	--should be 1 except for some SharePoint db's
,	[Alter]							= CASE
											WHEN is_auto_create_stats_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CREATE_STATISTICS ON WITH NO_WAIT;'
											WHEN is_auto_update_stats_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS ON WITH NO_WAIT;'
											WHEN is_auto_update_stats_async_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS_ASYNC ON WITH NO_WAIT;'
											WHEN is_auto_create_stats_on = 0 AND is_auto_update_stats_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CREATE_STATISTICS ON WITH NO_WAIT; ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS ON WITH NO_WAIT;'
											WHEN is_auto_create_stats_on = 0 AND is_auto_update_stats_async_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CREATE_STATISTICS ON WITH NO_WAIT; ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS_ASYNC ON WITH NO_WAIT;'
											WHEN is_auto_update_stats_on = 0 AND is_auto_update_stats_async_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS ON WITH NO_WAIT; ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS_ASYNC ON WITH NO_WAIT;'
											WHEN is_auto_create_stats_on = 0 AND is_auto_update_stats_on = 0 AND is_auto_update_stats_async_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CREATE_STATISTICS ON WITH NO_WAIT; ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS ON WITH NO_WAIT; ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS_ASYNC ON WITH NO_WAIT;'
									  ELSE 'N/A'
									  END
,	[Revert]						= CASE
											WHEN is_auto_create_stats_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CREATE_STATISTICS OFF WITH NO_WAIT;'
											WHEN is_auto_update_stats_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS OFF WITH NO_WAIT;'
											WHEN is_auto_update_stats_async_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS_ASYNC OFF WITH NO_WAIT;'
											WHEN is_auto_create_stats_on = 0 AND is_auto_update_stats_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CREATE_STATISTICS OFF WITH NO_WAIT; ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS OFF WITH NO_WAIT;'
											WHEN is_auto_create_stats_on = 0 AND is_auto_update_stats_async_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CREATE_STATISTICS OFF WITH NO_WAIT; ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS_ASYNC OFF WITH NO_WAIT;'
											WHEN is_auto_update_stats_on = 0 AND is_auto_update_stats_async_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS OFF WITH NO_WAIT; ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS_ASYNC OFF WITH NO_WAIT;'
											WHEN is_auto_create_stats_on = 0 AND is_auto_update_stats_on = 0 AND is_auto_update_stats_async_on = 0 THEN 'ALTER DATABASE [' + name + '] SET AUTO_CREATE_STATISTICS OFF WITH NO_WAIT; ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS OFF WITH NO_WAIT; ALTER DATABASE [' + name + '] SET AUTO_UPDATE_STATISTICS_ASYNC OFF WITH NO_WAIT;'
									  ELSE 'N/A'
									  END
,	[State]							= dbstate	
from #DBSettings
where is_auto_create_stats_on = 0
   OR is_auto_update_stats_on = 0
   OR is_auto_update_stats_async_on = 0

--Databases log reuse wait and description
--Types: NOTHING, CHECKPOINT, LOG_BACKUP, ACTIVE_BACKUP_OR_RESTORE, ACTIVE_TRANSACTION, DATABASE_MIRRORING, REPLICATION, DATABASE_SNAPSHOT_CREATION, LOG_SCAN, OTHER_TRANSIENT
select 
	[Database Name]		= name
,	[Log Reuse Wait]	= log_reuse_wait
,	[Description]		= log_reuse_wait_desc
,	[State]				= dbstate		
from #DBSettings

--Databases where target recovery time in seconds is < 60 (only applies to 2014+)
select 
	[Database Name]			= name
,	[Target Recovery Time]	= target_recovery_time_in_seconds
,	[Alter]					= 'ALTER DATABASE [' + name + '] SET TARGET_RECOVERY_TIME = 60 SECONDS WITH NO_WAIT'
,	[Revert]				= 'ALTER DATABASE [' + name + '] SET TARGET_RECOVERY_TIME = ' + CAST(target_recovery_time_in_seconds AS VARCHAR(3)) + ' SECONDS WITH NO_WAIT'
,	[State]					= dbstate		
from #DBSettings
where target_recovery_time_in_seconds < 60