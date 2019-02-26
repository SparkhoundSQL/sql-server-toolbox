--Script to identify incorrect recovery models for Sharepoint. These recovery model assumptions/suggestions are based on the Microsoft/EA suggestions found here: https://technet.microsoft.com/en-us/library/cc678868(v=office.16).aspx
IF OBJECT_ID('tempdb..#SharepointRecovery') IS NOT NULL
    BEGIN
	   DROP TABLE #SharepointRecovery;
    END;

SELECT	  [name]
		, [state_desc]
		, [recovery_model_desc]
		, [databasetype] =				CASE        WHEN name like '%SharePoint_Config%' then 'Configuration' 
													WHEN name like '%Config%' then 'Configuration' 
													WHEN name like '%SharePoint_AdminContent%' then 'Central Administration Content'
													WHEN name like '%WSS_Content%' then 'Content'
													WHEN name like '%Content%' then 'Content'
													WHEN name like '%AppMng_Service%' then 'App Management'
													WHEN name like '%AppManagement%' then 'App Management'
													WHEN name like '%Bdc_Service%' then 'Business Data Connectivity'
													WHEN name like '%BDC%' then 'Business Data Connectivity'
													WHEN name like '%BusinessData%' then 'Business Data Connectivity'
													WHEN name like '%Connectivity%' then 'Business Data Connectivity'
													WHEN name like '%Secure_Store_Service%' then 'Secure Store'
													WHEN name like '%SecureStore%' then 'Secure Store'
													WHEN name like '%SettingsService%' then 'Subscription Settings'
													WHEN name like '%Subscription%' then 'Subscription Settings'
													WHEN name like '%SubscriptionSettings%' then 'Subscription Settings'
													WHEN name like '%WordAutomationServices%' then 'Word Automation Services'
													WHEN name like '%Automation%' then 'Word Automation Services'
													WHEN name like '%Managed Metadata Service%' then 'Managed Metadata'
													WHEN name like '%Metadata%' then 'Managed Metadata'
													WHEN name like '%TranslationService%' then 'Machine Translation Services'
													WHEN name like '%Translation%' then 'Machine Translation Services'
													WHEN name like '%ProjectWebApp%' then 'Project Server'
													WHEN name like '%PowerPivot%' then 'Power Pivot'
													WHEN name like '%PerformancePoint%' then 'PerformancePoint Services'
													WHEN name like '%StateService%' then 'State Service'
													WHEN name	 = 'model' then 'model'
													WHEN name like '%ReportServer%' then 'Report Server Catalog'
													WHEN name like '%ReportingService%' then 'Report Server Catalog'
													WHEN name like '%Search_Service_Application%' then 'Search Administration'
													WHEN name like '%SearchService%' then 'Search Administration'
													WHEN name like '%WSS_Logging%' then 'Usage'
													WHEN name like '%SharePoint_Logging%' then 'Usage'
													WHEN name like '%Usage%' then 'Usage'
													WHEN name like '%Application_Profile%' then 'User Profile Service Application'
													WHEN name like '%Application_Sync%' then 'User Profile Service Application'
													WHEN name like '%Application_Social%' then 'User Profile Service Application'
													WHEN name like '%Profile%' then 'User Profile Service Application'
													WHEN name like '%WF%' AND name like '%Management%' then 'Workflow Management'
													WHEN name like '%SB%' AND name like '%Management%' then 'Service Bus Management'
													WHEN name like '%WF%' AND name not like '%Management%' then 'Workflow'
													WHEN name like '%SB%' AND name not like '%Management%' then 'Service Bus'
													WHEN name	 = 'master' then 'master'
													WHEN name	 = 'msdb' then 'msdb'
													WHEN name	 = 'tempdb' then 'tempdb' END
INTO #SharepointRecovery
FROM sys.databases
WHERE 1=1
	AND state_desc = 'ONLINE'
    AND is_read_only = 0;


--Find incorrect recovery models
SELECT	 [Database Name] =				name
		,[Database Type] =				databasetype
		,[State] =						state_desc
		,[Current Recovery Model] =		recovery_model_desc
		,[RecommendedRecoveryModel] =	CASE recovery_model_desc WHEN 'SIMPLE' THEN 'FULL' 
																 ELSE 'SIMPLE' END
		,[ChangeRecoveryModel] =		CASE recovery_model_desc WHEN 'SIMPLE' THEN 'ALTER DATABASE [' + name + '] SET RECOVERY FULL; GO' 
															     ELSE 'ALTER DATABASE [' + name + '] SET RECOVERY SIMPLE; GO' END
FROM #SharepointRecovery
WHERE	(DatabaseType = 'Configuration' and recovery_model_desc = 'SIMPLE') --configuration databases should be in FULL recovery
     OR	(DatabaseType = 'Central Administration Content' and recovery_model_desc = 'SIMPLE') --Central Administration content databases should be in FULL recovery
	 OR	(DatabaseType = 'Content' and recovery_model_desc = 'SIMPLE') --C databases should be in FULL recovery
	 OR	(DatabaseType = 'App Management' and recovery_model_desc = 'SIMPLE') --App Management databases should be in FULL recovery
	 OR	(DatabaseType = 'Business Data Connectivity' and recovery_model_desc = 'SIMPLE') --Business Data Connectivity databases should be in FULL recovery
	 OR	(DatabaseType = 'Secure Store' and recovery_model_desc = 'SIMPLE') --Secure Store databases should be in FULL recovery
	 OR	(DatabaseType = 'Subscription Settings' and recovery_model_desc = 'SIMPLE') --Subscription Settings databases should be in FULL recovery
	 OR	(DatabaseType = 'Word Automation Services' and recovery_model_desc = 'SIMPLE') --Word Automation Services databases should be in FULL recovery
	 OR	(DatabaseType = 'Managed Metadata' and recovery_model_desc = 'SIMPLE') --Managed Metadata databases should be in FULL recovery
	 OR	(DatabaseType = 'Machine Translation Services' and recovery_model_desc = 'SIMPLE') --Machine Translation Services databases should be in FULL recovery
	 OR	(DatabaseType = 'Project Server' and recovery_model_desc = 'SIMPLE') --Project Server databases should be in FULL recovery
	 OR	(DatabaseType = 'Power Pivot' and recovery_model_desc = 'SIMPLE') --Power Pivot databases should be in FULL recovery
	 OR	(DatabaseType = 'PerformancePoint Services' and recovery_model_desc = 'SIMPLE') --PerformancePoint Services databases should be in FULL recovery
	 OR	(DatabaseType = 'State Service' and recovery_model_desc = 'SIMPLE') --State Service databases should be in FULL recovery
	 OR	(DatabaseType = 'model' and recovery_model_desc = 'SIMPLE') --model should be in FULL recovery
	 OR	(DatabaseType = 'Report Server Catalog' and recovery_model_desc = 'SIMPLE') --Report Server Catalog databases should be in FULL recovery
	 OR	(DatabaseType = 'Search Administration' and recovery_model_desc = 'FULL') --Search Administration databases should be in SIMPLE recovery
	 OR	(DatabaseType = 'Usage' and recovery_model_desc = 'FULL') --Usage databases should be in SIMPLE recovery
	 OR	(DatabaseType = 'User Profile Service Application' and recovery_model_desc = 'FULL') --User Profile service application databases should be in SIMPLE recovery
	 OR	(DatabaseType = 'master' and recovery_model_desc = 'FULL') --master should be in SIMPLE recovery
	 OR	(DatabaseType = 'msdb' and recovery_model_desc = 'FULL') --msdb should be in SIMPLE recovery
	 OR	(DatabaseType = 'tempdb' and recovery_model_desc = 'FULL') --tempdb should be in SIMPLE recovery
	 OR	(DatabaseType = 'Workflow Management' and recovery_model_desc = 'FULL') --Workflow Management databases should be in SIMPLE recovery
	 OR	(DatabaseType = 'Service Bus Management' and recovery_model_desc = 'FULL') --Service Bus Management databases should be in SIMPLE recovery
	 OR	(DatabaseType = 'Workflow' and recovery_model_desc = 'SIMPLE') --Workflow databases should be in FULL recovery
	 OR	(DatabaseType = 'Service Bus' and recovery_model_desc = 'SIMPLE') --Service Bus databases should be in FULL recovery
ORDER BY recovery_model_desc, databasetype;

/*--List of all databases, types, and current recovery models
SELECT	 [Database Name] =				name
		,[Database Type] =				databasetype
		,[State] =						state_desc
		,[Current Recovery Model] =		recovery_model_desc
FROM #SharepointRecovery
ORDER BY databasetype;*/

DROP TABLE #SharepointRecovery;
