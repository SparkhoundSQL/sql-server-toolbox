SELECT is_broker_enabled FROM sys.databases WHERE name = 'msdb' ;

EXECUTE msdb.dbo.sysmail_help_status_sp ;
--EXECUTE msdb.dbo.sysmail_start_sp --start the database mail queues;

GO

--Find recent unsent emails
SELECT m.send_request_date, m.recipients, m.copy_recipients, m.blind_copy_recipients
, m.[subject],  a.name AS sent_account, m.send_request_user, m.sent_status
FROM msdb.dbo.sysmail_allitems m
LEFT JOIN msdb.dbo.sysmail_account a
	ON m.sent_account_id = a.account_id
WHERE	1=1
--AND m.send_request_date > dateadd(day, -3, sysdatetime()) -- Only show recent day(s), comment out if wanting to look at all mail sent
--AND m.sent_status<>'sent' -- Possible values are sent (successful), unsent (in process), retrying (failed but retrying), failed (no longer retrying)
ORDER BY m.send_request_date DESC;
GO

--Send mail test
--exec msdb.dbo.sp_send_dbmail @profile_name ='hotmail', @recipients ='williamdassaf@hotmail.com', @subject ='test', @body = 'test'

--ALTER DATABASE msdb SET ENABLE_BROKER;