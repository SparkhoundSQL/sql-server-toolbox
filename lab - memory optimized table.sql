--Lab - memory optimized table performance

--select * from sys.master_files
--1. first, you must add a filegroup for memory_optimzed_data
use master
go
ALTER DATABASE w ADD FILEGROUP [Optimized_FG] CONTAINS MEMORY_OPTIMIZED_DATA 
GO 
ALTER DATABASE w ADD FILE ( NAME = N'Optimized_Data', FILENAME = N'F:\Data\Optimized_Data.ndf') TO FILEGROUP [Optimized_FG] 
GO 

use w
go

CREATE TABLE dbo.mem_table
	(
	fragid int NOT NULL IDENTITY(1,1) ,
	fragtext varchar(4000) NOT NULL,
	CONSTRAINT [PK_mem_table] PRIMARY KEY NONCLUSTERED HASH (fragid) WITH (BUCKET_COUNT = 131072 ) --bucket_count should be 1-2x the number of unique key values that are expected. 
	)  
	WITH (MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA)
