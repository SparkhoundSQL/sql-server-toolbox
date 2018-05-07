--#TODO: review string filters at bottom.
--Can execute in a multiserver query
--Execute in Grid mode

declare @oldestdate as date, @now as datetime2(0)
select @oldestdate = dateadd(year,-7, sysdatetime()), @now = sysdatetime() --must create a variable to be passed later on

select 'Getting errors since ' + cast(@oldestdate as varchar(30))

--Get list of logs associated with the SQL Server (by default is 7, probably need more!) 
DECLARE @SQLErrorLogList TABLE (
    LogNumber INT NOT NULL,
    LogEndDate datetime2(0) NOT NULL,
    LogSize_b BIGINT NOT NULL);

INSERT INTO @SQLErrorLogList
EXEC sys.sp_enumerrorlogs;

--error messages in current log
declare @readerrorlog table 
( LogDate datetime not null 
, LogProcessInfo nvarchar(255) not null 
, [LogMessageText] nvarchar(4000) not null 
)
declare @lognumber int = 0, @endoflogfiles bit = 0
WHILE (
		((Select LogEndDate from @SQLErrorLogList where @lognumber = LogNumber) > @oldestdate)
		and @lognumber <= (SELECT MAX(LogNumber) from @SQLErrorLogList)
		) --Include any logs from the last month
BEGIN

	INSERT INTO @readerrorlog 
	EXEC master.dbo.xp_readerrorlog  
	  @lognumber		--current log file
	, 1					--SQL Error Log
	, N''				--search string 1, must be unicode. Leave empty on purpose, as we do filtering later on.
	, N''				--search string 2, must be unicode. Leave empty on purpose, as we do filtering later on.
	, @oldestdate, @now --time filter. Should be @oldestdate < @now
	, N'desc'			--sort
			
	print 'including lognumber ' + str(@lognumber)

	set @lognumber = @lognumber + 1	
END

--order of servers in a multiserver query is not determinant

--Raw error list
select * from @readerrorlog 
where  1=1
and (	
	LogMessageText like '%error%'
or	LogMessageText like '%failure%'
or	LogMessageText like '%failed%'
)
and LogMessageText not like '%without errors%'
and LogMessageText not like '%informational%'
order by LogDate desc;

--Aggregate error counts
select LogMessageText, LogProcessInfo, ErrorCount = count(LogDate), MostRecentOccurrence = max(LogDate) 
from @readerrorlog 
where  1=1
and (	
	LogMessageText like '%error%'
or	LogMessageText like '%failure%'
or	LogMessageText like '%failed%'
)
and LogMessageText not like '%without errors%'
and LogMessageText not like '%informational%'
group by LogMessageText, LogProcessInfo
order by count(LogDate) desc, max(LogDate) desc;

SELECT Reboots = LogDate FROM @readerrorlog WHERE LogMessageText like 'Registry startup parameters:%'
ORDER BY LogDate;
