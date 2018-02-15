
--Concatenate WITH SEPARATOR!
--Place a comma between values (but not at the end)
SELECT csv = CONCAT_WS(',', name, current_utc_offset, is_currently_dst)
FROM sys.time_zone_info

--Wrap in " for text qualification on csv import
SELECT csv = CONCAT_WS('","', '"'+name, current_utc_offset, is_currently_dst)+'"'
FROM sys.time_zone_info

--Aggregate concatenation 
SELECT STRING_AGG(name, ', ') FROM sys.time_zone_info WHERE NAME LIKE '%central%';

SELECT STRING_AGG(
		cast(
			CONCAT_WS('","', '"'+name, current_utc_offset, is_currently_dst)+'"' 
		as NVARCHAR(MAX))
					 , ',') FROM sys.time_zone_info
