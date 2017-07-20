
IF EXISTS (
select 
	InstanceName 
,	ReportPath
,	ReportName					=	c.Name
,	RequestType
,	TimeStart
,	TimeEnd
,	Status
,	LastStatus
,	SubscriptionDescription		=	s.Description
--, *
 from ReportServer_GP2k8r2.dbo.executionlog2 el
 inner join ReportServer_GP2k8r2.dbo.Catalog c
 on el.ReportPath = c.Path
 inner join ReportServer_GP2k8r2.dbo.ReportSchedule a 
 on c.ItemID = a.ReportID
 inner join ReportServer_GP2k8r2.dbo.subscriptions s
 on s.Report_OID = c.ItemID
 and a.SubscriptionID = s.SubscriptionID
where requesttype = 'subscription'
and status <> 'rsSuccess'
and (LastRunTime > dateadd(d, -1, getdate()) and TimeEnd > dateadd(d, -1, getdate()))

)
BEGIN

declare @tsql nvarchar(4000) = '
select 
	''<table border=1><tr><td>'' + InstanceName + ''</td>'' 
,	''<td>'' + ReportPath+ ''</td>''
,	''<td>'' + convert(varchar(100), TimeStart) + ''</td>''
,	''<td>'' + Status+ ''</td>''
,	''<td>'' + LastStatus + ''</td>''
,	SubscriptionDescription		=	''<td>'' + s.Description + ''</td></tr></table>''
--, *
 from ReportServer_GP2k8r2.dbo.executionlog2 el
 inner join ReportServer_GP2k8r2.dbo.Catalog c
 on el.ReportPath = c.Path
 inner join ReportServer_GP2k8r2.dbo.ReportSchedule a 
 on c.ItemID = a.ReportID
 inner join ReportServer_GP2k8r2.dbo.subscriptions s
 on s.Report_OID = c.ItemID
 and a.SubscriptionID = s.SubscriptionID
where requesttype = ''subscription''
and status <> ''rsSuccess''
and (LastRunTime > dateadd(d, -1, getdate()) and TimeEnd > dateadd(d, -1, getdate()))
order by el.timestart desc'

exec msdb.dbo.sp_send_dbmail @profile_name = 'sparkhound', @recipients = 'dbadministrators@sparkhound.com', @from_address = 'ReportServer_GP2k8R2@sparkhound.com', @reply_to = 'dbadministrators@sparkhound.com', @subject = 'Failed SSRS subscriptions Report', @query = @tsql, @query_result_header = 0, @body_format ='html', @execute_query_database = 'msdb'

END