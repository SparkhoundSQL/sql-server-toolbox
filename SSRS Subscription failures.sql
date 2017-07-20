use reportserver
go
SELECT Catalog.Name AS ReportName
,'http://neillsqlssrs/Reports/Pages/Report.aspx?ItemPath=' + Catalog.Path + '&SelectedTabId=PropertiesTab&SelectedSubTabId=SubscriptionsTab' AS ReportSubscriptionMgrUrl
,Users.UserName AS SubscriptionOwner
,Subscriptions.Description AS SubscriptionDescription
,Subscriptions.LastStatus
,Subscriptions.LastRunTime
FROM [dbo].[ReportSchedule]
INNER JOIN [dbo].[Schedule]
ON ReportSchedule.ScheduleID = Schedule.ScheduleID
INNER JOIN [dbo].[Catalog]
ON ReportSchedule.ReportID = Catalog.ItemID
INNER JOIN [dbo].[Subscriptions]
ON ReportSchedule.SubscriptionID = Subscriptions.SubscriptionID
INNER JOIN [dbo].[Users]
ON Subscriptions.OwnerID = Users.UserID
WHERE (Subscriptions.DataSettings IS NULL AND Subscriptions.LastStatus LIKE 'Failure%') -- handle standard subscription errors
OR (Subscriptions.DataSettings IS NOT NULL AND RIGHT(Subscriptions.LastStatus, 11) <> '; 0 errors.')