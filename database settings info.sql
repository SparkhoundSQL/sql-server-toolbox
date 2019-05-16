--Last Update: 12/11/2018

IF OBJECT_ID('tempdb..#DBSettings') IS NOT NULL
    BEGIN
	   DROP TABLE #DBSettings;
    END;

select 
	name
,	[compatibility_level]	
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
from sys.databases;

--Compatibility Level Check
WITH cteDB (Database_Name, [compatibility_level], State, Up_To_Date)
AS (
SELECT 
 	Database_Name			= name
,	[Compatibility Level]	= [compatibility_level] --should be latest (130 = SQL2016, 120 = SQL2014, 110 = SQL2012, 100 = SQL2008, 90 = SQL2005)
,	[State]					= dbstate		
,	Up_To_Date				= CASE WHEN LEFT(convert(char(3), [compatibility_level]),2) <> LEFT(convert(varchar(15), SERVERPROPERTY('ProductVersion')),2) THEN 'Database is in old compatibility mode' ELSE null END
from #DBSettings
)
select
	cteDB.*
,	[SQL Server Version]	= SERVERPROPERTY('ProductVersion')
,	[Alter]					= CASE WHEN Up_To_Date is not null THEN 'ALTER DATABASE [' + Database_Name +'] SET COMPATIBILITY_LEVEL = ' + LEFT(convert(varchar(15), SERVERPROPERTY('ProductVersion')),2) + '0;' ELSE NULL END
,	[Revert]				= CASE WHEN Up_To_Date is not null THEN 'ALTER DATABASE [' + Database_Name +'] SET COMPATIBILITY_LEVEL = ' + convert(char(3), [compatibility_level]) + ';' ELSE NULL END
from cteDB
WHERE Up_to_Date is not null
order by [Database_Name];

--Databases where page verify option is not CHECKSUM
--Changing this setting does not instantly put a checksum on every page. Need to do an index REBUILD of all objets to get CHECKSUMS in place, or, it'll happen slowly over time as data is written.
select
 	[Database Name]			= name
,	[Page Verify Option]	= page_verify_option_desc
,	[Message]				= 'Page Verify Option MUST be CHECKSUM!'
,	[Alter]					= 'ALTER DATABASE [' + name +'] SET PAGE_VERIFY CHECKSUM WITH NO_WAIT; --Need to rebuild indexes on all objects in DB to take effect '
,	[Revert]				= 'ALTER DATABASE [' + name +'] SET PAGE_VERIFY ' + page_verify_option_desc COLLATE DATABASE_DEFAULT + ' WITH NO_WAIT;'
,	[State]					= dbstate		
from #DBSettings
where page_verify_option_desc <> 'CHECKSUM'
ORDER BY name;

--Databases where auto-close and/or auto-shrink is enabled. 
--Strongly recommend NEVER enabling either of these two settings.
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
ORDER BY name;

--Databases where auto create and/or auto update stats is disabled
--Recommend enabling these settings.
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
ORDER BY name;

--Databases log reuse wait and description
--Expected types: NOTHING, CHECKPOINT, LOG_BACKUP, ACTIVE_BACKUP_OR_RESTORE, DATABASE_SNAPSHOT_CREATION, AVAILABILITY_REPLICA, OLDEST_PAGE, XTP_CHECKPOINT
--Potentially problematic if long-lasting, research: DATABASE_MIRRORING, REPLICATION, ACTIVE_TRANSACTION, LOG_SCAN, OTHER_TRANSIENT 
select 
	[Database Name]		= name
,	[Log Reuse Wait]	= log_reuse_wait
,	[Description]		= log_reuse_wait_desc
,	[State]				= dbstate		
,	[Recovery Model]	= recovery_model_desc
from #DBSettings
ORDER BY name;

--Databases where target recovery time in seconds is < 60 (only applies to 2014+), and recommended in 2014+
select 
	[Database Name]			= name
,	[Target Recovery Time]	= target_recovery_time_in_seconds
,	[Alter]					= 'ALTER DATABASE [' + name + '] SET TARGET_RECOVERY_TIME = 60 SECONDS WITH NO_WAIT'
,	[Revert]				= 'ALTER DATABASE [' + name + '] SET TARGET_RECOVERY_TIME = ' + CAST(target_recovery_time_in_seconds AS VARCHAR(3)) + ' SECONDS WITH NO_WAIT'
,	[State]					= dbstate		
from #DBSettings
where target_recovery_time_in_seconds = 0
ORDER BY name;