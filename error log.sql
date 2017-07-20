--#TODO: review string filters at bottom.

--error messages in current log
declare @readerrorlog table 
( LogDate datetime not null 
, LogProcessInfo nvarchar(255) not null 
, [LogMessageText] nvarchar(4000) not null 
)
declare @lognumber int = 0
WHILE (((select min(logdate) from @readerrorlog) 
			> (select dateadd(month,-1, getdate()))) or @lognumber = 0) --Include any logs from the last month
BEGIN

	INSERT INTO @readerrorlog 
	EXEC master.dbo.xp_readerrorlog  
	  @lognumber --current log file
	, 1--SQL Error Log
	, null --search string 1, must be unicode. Leave NULL, we do filtering later on.
	, NULL --search string 2, must be unicode. Leave NULL, we do filtering later on.
	, NULL, NULL, N'desc' 
	print 'including lognumber ' + str(@lognumber)

	set @lognumber = @lognumber + 1
	
END

--order of servers in a multiserver query is not determinant
select * from @readerrorlog 
where  1=1
--and (	
--	LogMessageText like '%error%'
--or	LogMessageText like '%failure%'
--or	LogMessageText like '%failed%'
--)
--and LogMessageText not like '%without errors%'
--and LogMessageText not like '%informational%'
order by logdate desc