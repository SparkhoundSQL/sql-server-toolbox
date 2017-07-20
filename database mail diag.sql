SELECT is_broker_enabled FROM sys.databases WHERE name = 'msdb' ;

EXECUTE msdb.dbo.sysmail_help_status_sp ;
--EXECUTE msdb.dbo.sysmail_start_sp --start the database mail queues;


GO

SELECT m.recipients, m.subject, m.body, 
    m.send_request_date, m.send_request_user, m.sent_status
FROM msdb.dbo.sysmail_allitems m
WHERE m.sent_status<>'sent'
--WHERE m.send_request_date > CURRENT_TIMESTAMP - 3
--AND m.sent_status <> 'sent'
ORDER BY m.send_request_date DESC
GO

