SELECT is_broker_enabled FROM sys.databases WHERE name = 'msdb' ; -- should be 1
EXECUTE msdb.dbo.sysmail_help_status_sp ; --should say STARTED
--EXECUTE msdb.dbo.sysmail_start_sp --start the database mail queues;
GO

--Find recent unsent emails, hopefully there are none
SELECT m.send_request_date, m.recipients, m.copy_recipients, m.blind_copy_recipients
, m.[subject], sent_account = a.name, m.send_request_user, m.sent_status
, Error_Description = l.description 
FROM msdb.dbo.sysmail_allitems m
LEFT OUTER JOIN msdb.dbo.sysmail_account a
	ON m.sent_account_id = a.account_id
INNER JOIN msdb.dbo.sysmail_event_log AS l  
    ON m.mailitem_id = l.mailitem_id  
WHERE	1=1
AND     m.send_request_date > dateadd(day, -45, sysdatetime()) -- Only show recent day(s)
AND		m.sent_status <> 'sent' -- Possible values are sent (successful), unsent (in process), retrying (failed but retrying), failed (no longer retrying)
ORDER BY m.send_request_date DESC;
GO

--Send mail test
--exec msdb.dbo.sp_send_dbmail @profile_name ='hotmail', @recipients ='williamdassaf@hotmail.com', @subject ='test', @body = 'test'

--ALTER DATABASE msdb SET ENABLE_BROKER;