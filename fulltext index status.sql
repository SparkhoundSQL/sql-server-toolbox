--Identify if fulltext catalog feature is installed
--Skip this step in Azure SQL DB
IF (SELECT FullText_Indexing_Is_Installed = fulltextserviceproperty('IsFullTextInstalled')) <> 1
BEGIN
	THROW 51000, 'Full text indexing is not installed.',0;
END;
GO

--Identify databases with a fulltext catalog present
--Skip this step in Azure SQL DB
EXEC sp_MSforeachdb 'use[?]; select Database_name = DB_Name(), fc.name from sys.fulltext_catalogs fc'
GO

SELECT	
		Fulltext_Catalog	= c.name
    ,	Table_Name	= o.name
    ,	Key_Index	= i.name
	,   Catalog_Populate_Status = FULLTEXTCATALOGPROPERTY(c.name,'PopulateStatus')
	,	Catalog_Populate_Status_Desc = 
			(SELECT CASE FULLTEXTCATALOGPROPERTY(c.name,'PopulateStatus')
						WHEN 0 THEN 'Idle' --caught up and keeping up
						WHEN 1 THEN 'Full Population In Progress' --initial status upon creation
						WHEN 2 THEN 'Paused'--PROBLEM?
						WHEN 3 THEN 'Throttled'
						WHEN 4 THEN 'Recovering'--PROBLEM
						WHEN 5 THEN 'Shutdown'--PROBLEM
						WHEN 6 THEN 'Incremental Population In Progress'
						WHEN 7 THEN 'Building Index'
						WHEN 8 THEN 'Disk Full.  Paused.' --PROBLEM
						WHEN 9 THEN 'Change Tracking' --expected when it is catching up and not up to date yet
					END) --https://docs.microsoft.com/en-us/sql/t-sql/functions/fulltextcatalogproperty-transact-sql
	,	LastCrawlStart	= fi.crawl_start_date
	,	LastCrawlEnd	= fi.crawl_end_date --null when currently crawling
	,	fi.is_enabled 
	,	c.is_default 
	,	fi.crawl_type_desc
    ,	fi.change_tracking_state_desc
	,	fi.has_crawl_completed
	,	c.is_importing -- Indicates whether the full-text catalog is being imported: 1 = The catalog is being imported. 2 = The catalog is not being imported.
	
FROM	sys.fulltext_catalogs c	
    LEFT OUTER JOIN sys.fulltext_indexes fi ON fi.fulltext_catalog_id = c.fulltext_catalog_id
	LEFT OUTER JOIN sys.objects o			ON o.[object_id] = fi.[object_id] 
    LEFT OUTER JOIN sys.indexes i			ON fi.unique_index_id = i.index_id AND fi.[object_id] = i.[object_id]
/*
WHERE  (fi.crawl_end_date is null --is currently crawling
  or fi.crawl_end_date < dateadd(day, -1, getdate())) --look for any ft index that hasn't updated recently
*/
ORDER	BY c.name, o.name, i.name, fi.crawl_start_date;