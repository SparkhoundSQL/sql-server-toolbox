use ReportServer
go
SELECT 
	ReportName = c.[Name]
,	c.Path
,	s.LastStatus
,	el.RequestType
,	s.LastRunTime
,	el.TimeStart
,	el.TimeEnd
,	el.Status
,	s.Description
,	s.ExtensionSettings
,	el.ItemPath
,	[Owner] = u.UserName
--, *
 from dbo.Catalog c
 inner join dbo.ReportSchedule a 
 on c.ItemID = a.ReportID
 inner join dbo.subscriptions s
 on s.Report_OID = c.ItemID
 and a.SubscriptionID = s.SubscriptionID
 INNER JOIN 	dbo.[Users] u on s.[OwnerID] = u.[UserID]
left outer join dbo.ExecutionLog3 el  on el.itempath = c.path
 where el.requesttype = 'subscription'
 --and laststatus not like '%0 errors.'
order by s.LastRunTime desc, el.timestart desc