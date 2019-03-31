SELECT R.session_id,
R.percent_complete,
R.total_elapsed_time/1000 AS elapsed_secs,
R.wait_type,
R.wait_time,
R.last_wait_type,
DATEADD(s,100/((R.percent_complete)/ (R.total_elapsed_time/1000)), R.start_time) estim_completion_time,
ST.text,
SUBSTRING(ST.text, R.statement_start_offset / 2,
(
CASE WHEN R.statement_end_offset = -1 THEN DATALENGTH(ST.text)
ELSE R.statement_end_offset
END - R.statement_start_offset
) / 2
) AS statement_executing
FROM sys.dm_exec_requests R
CROSS APPLY sys.dm_exec_sql_text(R.sql_handle) ST
WHERE R.percent_complete > 0
AND R.session_id <> @@spid