--IF Query Store is found to be in an ERROR STATE
--This is uncommon
SELECT actual_state_desc, desired_state_desc, current_storage_size_mb,
    [max_storage_size_mb], readonly_reason, [interval_length_minutes],
    stale_query_threshold_days, size_based_cleanup_mode_desc,
    query_capture_mode_desc
FROM sys.database_query_store_options;


/*
--First, try manually setting Query_Store to Read_Write then waiting for the flush to pass. It may show READ/WRITE again only until it fails again.

ALTER DATABASE [WhateverDB]
SET QUERY_STORE (OPERATION_MODE = READ_WRITE);

SELECT actual_state_desc, desired_state_desc, current_storage_size_mb,
    [max_storage_size_mb], readonly_reason, [interval_length_minutes],
    stale_query_threshold_days, size_based_cleanup_mode_desc,
    query_capture_mode_desc
FROM sys.database_query_store_options;



--If that doesn't cause READ/WRITE mode to stick, then we'll have to wipe the Query Store.

USE WhateverDB
--Unfortunately clearing the Query Store is necessary.
ALTER DATABASE [WhateverDB] SET QUERY_STORE CLEAR;
--Disable the query store
ALTER DATABASE [WhateverDB] SET QUERY_STORE = OFF;


exec dbo.sp_query_store_consistency_check;

ALTER DATABASE [WhateverDB]
SET QUERY_STORE (OPERATION_MODE = READ_WRITE);

SELECT actual_state_desc, desired_state_desc, current_storage_size_mb,
    [max_storage_size_mb], readonly_reason, [interval_length_minutes],
    stale_query_threshold_days, size_based_cleanup_mode_desc,
    query_capture_mode_desc
FROM sys.database_query_store_options;



*/

--FROM https://docs.microsoft.com/en-us/sql/relational-databases/performance/best-practice-with-the-query-store?view=sql-server-ver15

