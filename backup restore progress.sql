SELECT command,
            s.text,
            start_time,
            percent_complete,
            CAST(((DATEDIFF(s,start_time,GetDate()))/3600) as varchar) + ' hour(s), '
                  + CAST((DATEDIFF(s,start_time,GetDate())%3600)/60 as varchar) + 'min, '
                  + CAST((DATEDIFF(s,start_time,GetDate())%60) as varchar) + ' sec' as running_time,
            CAST((estimated_completion_time/3600000) as varchar) + ' hour(s), '
                  + CAST((estimated_completion_time %3600000)/60000 as varchar) + 'min, '
                  + CAST((estimated_completion_time %60000)/1000 as varchar) + ' sec' as est_time_to_go,
            dateadd(second,estimated_completion_time/1000, getdate()) as est_completion_time
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) s
WHERE r.command like 'RESTORE%' or r.command like 'BACKUP%'