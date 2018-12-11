--Test

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
,	user_access_desc		--should be MULTI_USER
,	is_auto_close_on		--should be 0
,	is_auto_shrink_on		--should be 0
,	is_auto_create_stats_on	--should be 1 except for some SharePoint db's
,	is_auto_update_stats_on	--should be 1 except for some SharePoint db's
into #DBSettings
from sys.databases
--where state_desc = 'ONLINE'

--Compatibility Level Check
select
 	[Database Name]			= name
,	[Compatibility Level]	= [compatibility_level]
,	[SQL Server Version] = SERVERPROPERTY('ProductVersion')
,	[State]					= dbstate		
from #DBSettings
order by [compatibility_level]

--Databases where page verify option is not CHECKSUM
select
 	[Database Name]			= name
,	[Page Verify Option]	= page_verify_option_desc
,	[State]					= dbstate		
from #DBSettings
where page_verify_option_desc <> 'CHECKSUM'

--Databases where auto-close and/or auto-shrink is enabled
select 
 	[Database Name]			= name
,	[Is Auto Close On]		= is_auto_close_on		--should be 0
,	[Is Auto Shrink On]		= is_auto_shrink_on		--should be 0
,	[State]					= dbstate	
from #DBSettings
where is_auto_close_on = 1		
   OR is_auto_shrink_on	= 1	

--Databases where auto create and/or auto update stats is disabled
select 
	[Database Name]				= name
,	[Is Auto Create Stats On]	= is_auto_create_stats_on	--should be 1 except for some SharePoint db's
,	[Is Auto Update Stats On]	= is_auto_update_stats_on	--should be 1 except for some SharePoint db's
,	[State]						= dbstate		
from #DBSettings
where is_auto_create_stats_on = 0
   OR is_auto_update_stats_on = 0

