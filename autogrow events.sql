
--The trace automatically finds _n files, strip off the _nnn. For example, will read all data from log_14.trc, log_15.trc, log_16.trc, log_17.trc, etc. 
--Default trace files are limited to 20mb, and there are at most five of them, so we have 100mb of history. Depends on activity to determine how far back that goes.


	SELECT 
		DBName				=	g.DatabaseName
	,	DBFileName			=	mf.physical_name
	,	FileType			=	CASE mf.type WHEN 0 THEN 'Row' WHEN 1 THEN 'Log' WHEN 2 THEN 'FILESTREAM' WHEN 4 THEN 'Full-text' END
	,	EventName			=	te.name
	,	EventGrowthMB		=	convert(decimal(19,2),g.IntegerData*8/1024.) -- Number of 8-kilobyte (KB) pages by which the file increased.
	,	EventTime			=	g.StartTime
	,	EventDurationSec	=	convert(decimal(19,2),g.Duration/1000./1000.) -- Length of time (in milliseconds) necessary to extend the file.
	,	CurrentAutoGrowthSet=	CASE
									WHEN mf.is_percent_growth = 1
									THEN CONVERT(char(2), mf.growth) + '%' 
									ELSE CONVERT(varchar(30), convert(decimal(19,2), mf.growth*8./1024.)) + 'MB'
								END
	,	CurrentFileSizeMB	=	convert(decimal(19,2),mf.size*	8./1024.)
	,	d.Recovery_model_Desc
	--,	@tracepath	
	--,	MaxFileSizeMB		=	CASE WHEN mf.max_size = -1 THEN 'Unlimited' ELSE convert(varchar(30), convert(decimal(19,2),mf.max_size*8./1024.)) END
	--select count(1)
	FROM fn_trace_gettable((select substring((select path from sys.traces where is_default =1), 0, charindex('\log_', (select path from sys.traces where is_default =1),0)+4)	+ '.trc'), default) g
	cross apply sys.trace_events te 
	inner join sys.master_files mf
	on mf.database_id = g.DatabaseID
	and g.FileName = mf.name
	inner join sys.databases d
	on d.database_id = g.DatabaseID
	WHERE g.eventclass = te.trace_event_id
	and		te.name in ('Data File Auto Grow','Log File Auto Grow')
	and		g.StartTime > dateadd(d, -7, sysdatetime()) 
	--GROUP BY StartTime,Databaseid, Filename, IntegerData, Duration
	order by StartTime desc



