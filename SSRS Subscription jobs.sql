select 'exec sp_start_job @job_name = ''' + cast(j.name as varchar(40)) + '''' , s.Description, s.LastRunTime, s.LastStatus, s.EventType, j.description
from msdb.dbo.sysjobs j  
inner join  msdb.dbo.sysjobsteps js on js.job_id = j.job_id 
inner join  [ReportServer].[dbo].[Subscriptions] s  on js.command like '%' + cast(s.subscriptionid as varchar(40)) + '%' 
where j.description = 'This job is owned by a report server process. Modifying this job could result in database incompatibilities. Use Report Manager or Management Studio to update this job.'
