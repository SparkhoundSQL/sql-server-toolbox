----SSRS logs for subscription failures
--1. Check Windows Application Event Log

--2. Check ReportServer.dbo.ExecutionLog3
select top 1000 * from ReportServer.dbo.ExecutionLog3 where status <> 'rsSuccess' order by timestart desc

--3. Check SSRS trace Log Files on the server
--https://docs.microsoft.com/en-us/sql/reporting-services/troubleshooting/troubleshoot-reporting-services-subscriptions-and-delivery?view=sql-server-2017
--C:\Program Files\Microsoft SQL Server\instance.mssqlserver\Reporting Services\LogFiles\ReportServerService_<timestamp>.log
--C:\Program Files\Microsoft SQL Server\instance.mssqlserver\Reporting Services\LogFiles\Microsoft.ReportingServices.Portal.WebHost_<timestamp>.log
--or
--C:\Program Files\Microsoft SQL Server Reporting Services\SSRS\LogFiles

--5. Query below for subscription statuses:
use ReportServer
go
select 
  ReportName = c.[Name]
, c.Path
, s.LastStatus
, el.RequestType
, s.LastRunTime
, el.TimeStart
, el.TimeEnd
, el.Status
, s.Description
, s.ExtensionSettings
, el.ItemPath
, [Owner] = u.UserName
--, *
FROM dbo.Catalog c
INNER JOIN dbo.ReportSchedule a 
 on c.ItemID = a.ReportID
INNER JOIN dbo.subscriptions s
on s.Report_OID = c.ItemID
and a.SubscriptionID = s.SubscriptionID
INNER JOIN dbo.[Users] u on s.[OwnerID] = u.[UserID]
LEFT OUTER JOIN dbo.ExecutionLog3 el  on el.itempath = c.path
WHERE el.requesttype = 'subscription'
AND laststatus not like '%0 errors.'
ORDER BY s.LastRunTime desc, el.timestart desc
