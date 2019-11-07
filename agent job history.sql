--Determines the retention of SQL Agent job history, stored in msdb

--Look for jobhistory_Max_Rows and jobhistory_max_rows_per_job. 
--By default, 1000 and 100.
exec msdb.dbo.sp_get_sqlagent_properties 
GO

--If Autostart = 0, check if SQL Server Agent service is set to Automatic startup.
select servicename, startup_type_desc from sys.dm_server_services


/*
--Sample script to increase job history retention by an order of magnitude each. 
--For a job that executes every 15 minutes, how much history do you want for that job?
--	672 records per week, 2880 records per month! Consider increasing to 50000/10000
EXEC msdb.dbo.sp_set_sqlagent_properties @jobhistory_max_rows=10000, 
		@jobhistory_max_rows_per_job=1000
*/