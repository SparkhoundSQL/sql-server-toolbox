--select distinct object_name, counter_name from sys.dm_os_performance_counters 

--Buffer Cache Hit Ratio, as an example
SELECT [BufferCacheHitRatio] = (bchr * 1.0 / bchrb) * 100.0
FROM
(SELECT bchr = cntr_value FROM
sys.dm_os_performance_counters
WHERE counter_name = 'Buffer cache hit ratio'
AND object_name like '%Buffer Manager%') AS r
CROSS APPLY
(SELECT bchrb= cntr_value FROM
sys.dm_os_performance_counters
WHERE counter_name = 'Buffer cache hit ratio base'
and object_name like '%Buffer Manager%') AS rb

--Target, Total memory
select counter_name, [cntr_value (MB)] = cntr_value/1024.
 from sys.dm_os_performance_counters
where OBJECT_NAME like '%Memory Manager%'
and counter_name in ('Target Server Memory (KB)','Total Server Memory (KB)')

--Page Lookups/Batch Requests Ratio
SELECT
	[Page Lookups/s]		=	a.cntr_value			
,	[Batch Requests/s]		=	b.cntr_value		
,	[Ratio (ideally <100)]	= (a.cntr_value * 1. / b.cntr_value) --should be <100
FROM (
select * FROM sys.dm_os_performance_counters
where OBJECT_NAME like '%Buffer Manager%'
and counter_name = 'Page lookups/sec') a
CROSS APPLY 
(select * FROM sys.dm_os_performance_counters
where OBJECT_NAME like '%SQL Statistics%'
and counter_name = 'Batch Requests/sec') b



