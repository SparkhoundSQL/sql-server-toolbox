--SQL 2017+
--Must perform RESUMABLE = ON with ONLINE ON
--See example build of this large, fragmented table in toolbox\lab - fragmented table.sql

use w
GO
ALTER INDEX PK_fragmented_table on dbo.fragmented_table REBUILD WITH (ONLINE = ON, RESUMABLE = ON )

--FROM A DIFFERENT CONNECTION, run the below.
/*
use w
go
alter index PK_fragmented_table on dbo.fragmented_table PAUSE
*/

--To resume the index maintenance operation, two options:

--1.Reissue the same index maintenance operation, which will warn you it'll just resume instead.
ALTER INDEX PK_fragmented_table on dbo.fragmented_table REBUILD WITH (ONLINE = ON, RESUMABLE = ON )
--Warning: An existing resumable operation with the same options was identified for the same index on 'fragmented_table'. The existing operation will be resumed instead.

--2.Issue a RESUME to the same index.
alter index PK_fragmented_table on dbo.fragmented_table RESUME
