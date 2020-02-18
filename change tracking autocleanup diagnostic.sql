--In an AG, run on primary replica.
--Run in the user database with Change Tracking enabled.

SELECT 
  number_commits	= count(1) 
, min_commit_time	= MIN(commit_time) 
, max_commit_time	= MAX(commit_time) 
, now				= getdate()
FROM sys.dm_tran_commit_table;

--The minimum_commit_time should progress forward periodically.  
--As default configured with 7 days retention, the minimum_commit_time should be slightly more than 7 days ago if CT is keeping up.

--CT may get behind in the autocleanup. This is not a severe problem but will surface with:
--Error: 22123, Severity: 16, State: 1.
--Change Tracking autocleanup is blocked on side table of "tablename". If the failure persists, check whether the table "tablename is blocked by any process.