SELECT m.recipients, m.subject, m.body, 
    m.send_request_date, m.send_request_user, m.sent_status
FROM msdb.dbo.sysmail_allitems m
WHERE m.sent_status<>'sent'
--WHERE m.send_request_date > CURRENT_TIMESTAMP - 3
--AND m.sent_status <> 'sent'
ORDER BY m.send_request_date DESC
GO