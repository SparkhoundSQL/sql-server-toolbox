select 
	name
,	database_id
,	[compatibility_level]	--should be latest (130 = SQL2016, 120 = SQL2014, 110 = SQL2012, 100 = SQL2008, 90 = SQL2005)
,	user_access_desc		--should be MULTI_USER
,	is_read_only	
,	is_auto_close_on		--should be 0
,	is_auto_shrink_on		--should be 0
,	is_auto_create_stats_on	--should be 1 except for some SharePoint db's
,	is_auto_update_stats_on	--should be 1 except for some SharePoint db's
,	state_desc				
,	recovery_model_Desc
 from sys.databases