

PRINT N'Refreshing views.';

DECLARE @TSQL nvarchar(4000) 
DECLARE RefreshViewMetadata CURSOR FAST_FORWARD 
     FOR 
	select TSQL = 'exec sp_refreshview  N''' +s.name + '.' + o.name + ''''
	from  sys.views o 
	inner join sys.schemas s on o.schema_id = s.schema_id 
	inner join sys.sql_modules m on m.object_id = o.object_id 
	where o.type_desc = 'view'
	and o.is_ms_shipped = 0
	and m.definition not like '%schemabinding%'
	order by s.name, o.name
OPEN RefreshViewMetadata
FETCH NEXT FROM RefreshViewMetadata INTO @TSQL
WHILE @@FETCH_STATUS = 0
BEGIN
	--print @TSQL;
	BEGIN TRY
	BEGIN TRAN vwRefresh
	exec sp_executesql @TSQL;
	COMMIT TRAN vwRefresh
	END TRY
	BEGIN CATCH
		print @TSQL
		print ERROR_MESSAGE()
		ROLLBACK TRAN vwRefresh
	END CATCH
	FETCH NEXT FROM RefreshViewMetadata INTO @TSQL
END
CLOSE RefreshViewMetadata;
DEALLOCATE RefreshViewMetadata;
