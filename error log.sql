--#TODO: review string filters at bottom.
--Can execute in a multiserver query
--Execute in Grid mode
use tempdb
go
select SYSDATETIMEOFFSET()
declare @oldestdate as date, @now as datetime2(0)
select @oldestdate = dateadd(month,-3, sysdatetime()), @now = sysdatetime() --Filter the time frame of the logs.

select 'Getting errors since ' + cast(@oldestdate as varchar(30))

--Get list of logs associated with the SQL Server (by default is 7, probably need more!) 
CREATE TABLE #SQLErrorLogList (
    LogNumber INT NOT NULL,
    LogEndDate datetime2(0) NOT NULL,
    LogSize_b BIGINT NOT NULL);
CREATE NONCLUSTERED INDEX IDX_CL_ell on #SQLErrorLogList (LogNumber) INCLUDE (LogEndDate);

INSERT INTO #SQLErrorLogList
EXEC sys.sp_enumerrorlogs;

--error messages in current log
create table #readerrorlog
( LogDate datetime not null
, LogProcessInfo varchar(255) not null 
, [LogMessageText] varchar(1500) not null 
)

CREATE CLUSTERED INDEX IDX_CL_rel on #readerrorlog (LogDate);

declare @lognumber int = 0, @endoflogfiles bit = 0, @maxlognumber int = 0;

select @maxlognumber =   MAX(LogNumber) from #SQLErrorLogList
WHILE (
		((Select LogEndDate from #SQLErrorLogList where @lognumber = LogNumber) > @oldestdate)
		and @lognumber <= @maxlognumber
		) 
BEGIN

	INSERT INTO #readerrorlog 
	EXEC master.dbo.xp_readerrorlog  
	  @lognumber		--current log file
	, 1					--SQL Error Log
	, N''				--search string 1, must be unicode. Leave empty on purpose, as we do filtering later on.
	, N''				--search string 2, must be unicode. Leave empty on purpose, as we do filtering later on.
	, @oldestdate, @now --time filter. Should be @oldestdate < @now
	, N'desc'			--sort
			
	--print 'including lognumber ' + str(@lognumber)

	set @lognumber = @lognumber + 1	
END
GO

CREATE NONCLUSTERED INDEX IDX_NC_rel on #readerrorlog (Logdate desc, [LogMessageText]) INCLUDE( LogProcessInfo)

GO
--order of servers in a multiserver query is not determinant

--Raw error list
select * from #readerrorlog 
where  1=1
and (	
	LogMessageText like '%error%'
or	LogMessageText like '%failure%'
or	LogMessageText like '%failed%'
or	LogMessageText like '%corrupt%'
)
and LogMessageText not like '%without errors%'
and LogMessageText not like '%returned no errors%'
and LogMessageText not like 'Registry startup parameters:%'
and LogMessageText not like '%informational%'
and LogMessageText not like '%found 0 errors%'
order by LogDate desc;

--Aggregate error counts
select LogMessageText, LogProcessInfo, ErrorCount = count(LogDate), MostRecentOccurrence = max(LogDate) 
from #readerrorlog 
where  1=1
and (	
	LogMessageText like '%error%'
or	LogMessageText like '%failure%'
or	LogMessageText like '%failed%'
or	LogMessageText like '%corrupt%'
)
and LogMessageText not like '%without errors%'
and LogMessageText not like '%returned no errors%'
and LogMessageText not like 'Registry startup parameters:%'
and LogMessageText not like '%informational%'
and LogMessageText not like '%found 0 errors%'
group by LogMessageText, LogProcessInfo
order by count(LogDate) desc, max(LogDate) desc;

SELECT Reboots = LogDate FROM #readerrorlog WHERE LogMessageText like 'Registry startup parameters:%'
ORDER BY LogDate desc;
GO

drop table #readerrorlog
drop table #SQLErrorLogList