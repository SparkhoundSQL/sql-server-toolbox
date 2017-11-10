use reportserver
go
SELECT Catalog.Name AS ReportName
,'http://neillsqlssrs/Reports/Pages/Report.aspx?ItemPath=' + Catalog.Path + '&SelectedTabId=PropertiesTab&SelectedSubTabId=SubscriptionsTab' AS ReportSubscriptionMgrUrl
,Subscriptions.Description AS SubscriptionDescription
,Subscriptions.LastStatus
,Subscriptions.LastRunTime
,'Next Run Date' = CASE next_run_date
WHEN 0 THEN null
ELSE
substring(convert(varchar(15),next_run_date),1,4) + '/' +
substring(convert(varchar(15),next_run_date),5,2) + '/' +
substring(convert(varchar(15),next_run_date),7,2)
END
,	'Next Run Time' = isnull(CASE len(next_run_time)
WHEN 3 THEN cast('00:0'
+ Left(right(next_run_time,3),1)
+':' + right(next_run_time,2) as char (8))
WHEN 4 THEN cast('00:'
+ Left(right(next_run_time,4),2)
+':' + right(next_run_time,2) as char (8))
WHEN 5 THEN cast('0' + Left(right(next_run_time,5),1)
+':' + Left(right(next_run_time,4),2)
+':' + right(next_run_time,2) as char (8))
WHEN 6 THEN cast(Left(right(next_run_time,6),2)
+':' + Left(right(next_run_time,4),2)
+':' + right(next_run_time,2) as char (8))
END,'NA')
,Subscriptions.Parameters
,[ExtensionSettings]
,ISNULL(
Convert(XML,[ExtensionSettings]).value('(//ParameterValue/Value[../Name="TO"])[1]','nvarchar(50)')
,Convert(XML,[ExtensionSettings]).value('(//ParameterValue/Value[../Name="PATH"])[1]','nvarchar(150)')
) as [To]
,
ISNULL(
	Convert(XML,[ExtensionSettings]).value('(//ParameterValue/Value[../Name="RenderFormat"])[1]','nvarchar(50)') 
,	Convert(XML,[ExtensionSettings]).value('(//ParameterValue/Value[../Name="RENDER_FORMAT"])[1]','nvarchar(50)')
) as [Render Format]
,Convert(XML,[ExtensionSettings]).value('(//ParameterValue/Value[../Name="Subject"])[1]','nvarchar(150)') as [Subject]



,*
FROM [dbo].[ReportSchedule]
INNER JOIN [dbo].[Schedule]
ON ReportSchedule.ScheduleID = Schedule.ScheduleID
INNER JOIN [dbo].[Catalog]
ON ReportSchedule.ReportID = Catalog.ItemID
INNER JOIN [dbo].[Subscriptions]
ON ReportSchedule.SubscriptionID = Subscriptions.SubscriptionID
INNER JOIN [dbo].[Users]
ON Subscriptions.OwnerID = Users.UserID
INNER JOIN msdb.dbo.sysjobs J ON Convert(nvarchar(128),[ReportSchedule].ScheduleID) = J.name
INNER JOIN msdb.dbo.sysjobschedules JS ON J.job_id = JS.job_id


