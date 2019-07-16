USE ssisdb
GO
--default log retention is 180 days. For frequently-running SSIS packagse, this could generate 100Gb+ data in months
--But changing the log retention time frame drastically could cause the built-in sprocs to try and delete 100Gb+ at once
--Instead, step down the retention in small chunks. This could still take HOURS to complete and block other SSIS jobs
--  from logging, so recommended to create a maintainence window and stop SSISDB jobs from executing. 

--FYI: a bug in [internal].[cleanup_server_retention_window] prevents large deletes from succeeding. 
--You'll see error message:  "A cursor with the name 'execution_cursor' does not exist. [SQLSTATE 34000] (Error 16916)."
--More info: https://feedback.azure.com/forums/908035-sql-server/suggestions/37360864-ssis-server-maintenance-job-fails
--Fixed version is in comment block below. Careful!


declare @current int, @desired int 

select @desired = 65, @current = property_value 
from ssisdb.catalog.catalog_properties p where p.property_name = 'RETENTION_WINDOW'

while (@current > @desired)

BEGIN
 set @current = @current - 1
 print 'changing configure_catalog to '+str(@current);
 EXEC [SSISDB].[catalog].[configure_catalog] @property_name=N'RETENTION_WINDOW', @property_value=@current;

 EXEC [SSISDB].[internal].[cleanup_server_retention_window];
 EXEC [SSISDB].[internal].[cleanup_server_project_version];

 print 'completed changing configure_catalog to '+str(@current);
END

/*
--bugfix
USE [SSISDB]
GO
 

ALTER PROCEDURE [internal].[cleanup_server_retention_window]
WITH EXECUTE AS 'AllSchemaOwner'
AS
    SET NOCOUNT ON
    
    DECLARE @enable_clean_operation bit
    DECLARE @retention_window_length int
    DECLARE @server_operation_encryption_level int
    
    DECLARE @caller_name nvarchar(256)
    DECLARE @caller_sid  varbinary(85)
    DECLARE @operation_id bigint
    
    EXECUTE AS CALLER
        SET @caller_name =  SUSER_NAME()
        SET @caller_sid =   SUSER_SID()
    REVERT
         
    
    BEGIN TRY
        SELECT @enable_clean_operation = CONVERT(bit, property_value) 
            FROM [catalog].[catalog_properties]
            WHERE property_name = 'OPERATION_CLEANUP_ENABLED'
        
        IF @enable_clean_operation = 1
        BEGIN
            SELECT @retention_window_length = CONVERT(int,property_value)  
                FROM [catalog].[catalog_properties]
                WHERE property_name = 'RETENTION_WINDOW'
                

            IF @retention_window_length <= 0 
            BEGIN
                RAISERROR(27163    ,16,1,'RETENTION_WINDOW')
            END
            
            SELECT @server_operation_encryption_level = CONVERT(int,property_value)  
                FROM [catalog].[catalog_properties]
                WHERE property_name = 'SERVER_OPERATION_ENCRYPTION_LEVEL'

            IF @server_operation_encryption_level NOT in (1, 2)       
            BEGIN
                RAISERROR(27163    ,16,1,'SERVER_OPERATION_ENCRYPTION_LEVEL')
            END
            INSERT INTO [internal].[operations] (
                [operation_type],  
                [created_time], 
                [object_type],
                [object_id],
                [object_name],
                [status], 
                [start_time],
                [caller_sid], 
                [caller_name]
                )
            VALUES (
                2,
                SYSDATETIMEOFFSET(),
                NULL,                     
                NULL,                     
                NULL,                     
                1,      
                SYSDATETIMEOFFSET(),
                @caller_sid,            
                @caller_name            
                ) 
            SET @operation_id = SCOPE_IDENTITY() 
            
            DECLARE @temp_date datetimeoffset
            DECLARE @rows_affected bigint
            DECLARE @delete_batch_size int

            
            SET @delete_batch_size = 1000  
            SET @rows_affected = @delete_batch_size
            
            SET @temp_date = DATEADD(day, -@retention_window_length, SYSDATETIMEOFFSET())
            
            CREATE TABLE #deleted_ops (operation_id bigint, operation_type smallint)
            DECLARE execution_cursor CURSOR LOCAL FOR SELECT operation_id FROM #deleted_ops  WHERE operation_type = 200

   DECLARE @sqlString_operation_messages_scaleout   nvarchar(1024)
            DECLARE @sqlString_event_messages_scaleout       nvarchar(1024)
            DECLARE @sqlString_event_message_context_scaleout        nvarchar(1024)

            IF @server_operation_encryption_level = 1
            BEGIN
                DECLARE @execution_id bigint
                DECLARE @sqlString              nvarchar(1024)
                DECLARE @sqlString_cert         nvarchar(1024)
                DECLARE @key_name               [internal].[adt_name]
                DECLARE @certificate_name       [internal].[adt_name]

            WHILE (@rows_affected = @delete_batch_size)
            BEGIN
                DELETE TOP (@delete_batch_size)
                    FROM [internal].[operations] 
                        OUTPUT DELETED.operation_id, DELETED.operation_type INTO #deleted_ops
                    WHERE ( [end_time] <= @temp_date
                    
                    OR ([end_time] IS NULL AND [status] = 1 AND [created_time] <= @temp_date ))
                    
                SET @rows_affected = @@ROWCOUNT
            
            OPEN execution_cursor
            FETCH NEXT FROM execution_cursor INTO @execution_id
            
            WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @key_name = 'MS_Enckey_Exec_'+CONVERT(varchar,@execution_id)
                SET @certificate_name = 'MS_Cert_Exec_'+CONVERT(varchar,@execution_id)
                SET @sqlString_operation_messages_scaleout = 'delete from [internal].[operation_messages_scaleout] where operation_id = '+CONVERT(varchar,@execution_id)
                SET @sqlString_event_messages_scaleout = 'delete from [internal].[event_messages_scaleout] where operation_id = '+CONVERT(varchar,@execution_id)
                SET @sqlString_event_message_context_scaleout  = 'delete from [internal].[event_message_context_scaleout] where operation_id = '+CONVERT(varchar,@execution_id)
                        SET @sqlString = 'DROP SYMMETRIC KEY '+ @key_name
                        SET @sqlString_cert = 'DROP CERTIFICATE '+ @certificate_name
                        
                        BEGIN TRY
                    EXECUTE sp_executesql @sqlString
                            EXECUTE sp_executesql @sqlString_cert
                            EXECUTE sp_executesql @sqlString_operation_messages_scaleout
                            EXECUTE sp_executesql @sqlString_event_messages_scaleout
                            EXECUTE sp_executesql @sqlString_event_message_context_scaleout
                        END TRY

                        BEGIN CATCH
                            
                        END CATCH

                FETCH NEXT FROM execution_cursor INTO @execution_id
            END
            CLOSE execution_cursor
                    TRUNCATE TABLE #deleted_ops
                END
                DROP TABLE #deleted_ops

            DEALLOCATE execution_cursor
            END
            ELSE BEGIN
                WHILE (@rows_affected = @delete_batch_size)
                BEGIN
                    DELETE TOP (@delete_batch_size)
                        FROM [internal].[operations] 
                         OUTPUT DELETED.operation_id, DELETED.operation_type INTO #deleted_ops
                        WHERE ( [end_time] <= @temp_date
                        OR ([end_time] IS NULL AND [status] = 1 AND [created_time] <= @temp_date ))
                    SET @rows_affected = @@ROWCOUNT

                      OPEN execution_cursor
            FETCH NEXT FROM execution_cursor INTO @execution_id
             WHILE @@FETCH_STATUS = 0
            BEGIN
                SET @sqlString_operation_messages_scaleout = 'delete from [internal].[operation_messages_scaleout] where operation_id = '+CONVERT(varchar,@execution_id)
                SET @sqlString_event_messages_scaleout = 'delete from [internal].[event_messages_scaleout] where operation_id = '+CONVERT(varchar,@execution_id)
                SET @sqlString_event_message_context_scaleout  = 'delete from [internal].[event_message_context_scaleout] where operation_id = '+CONVERT(varchar,@execution_id)
                BEGIN TRY
                    EXECUTE sp_executesql @sqlString_operation_messages_scaleout
                    EXECUTE sp_executesql @sqlString_event_messages_scaleout
                    EXECUTE sp_executesql @sqlString_event_message_context_scaleout
                END TRY
                BEGIN CATCH 
                END CATCH
                FETCH NEXT FROM execution_cursor INTO @execution_id
            END
            CLOSE execution_cursor
                    TRUNCATE TABLE #deleted_ops
               END
            DEALLOCATE execution_cursor
                DROP TABLE #deleted_ops
            END
            
            UPDATE [internal].[operations]
                SET [status] = 7,
                [end_time] = SYSDATETIMEOFFSET()
                WHERE [operation_id] = @operation_id                                  
        END
    END TRY
    BEGIN CATCH
        
        
        IF @server_operation_encryption_level = 1
        BEGIN
        IF (CURSOR_STATUS('local', 'execution_cursor') = 1 
            OR CURSOR_STATUS('local', 'execution_cursor') = 0)
        BEGIN
            CLOSE execution_cursor
            DEALLOCATE execution_cursor            
        END
        END
        
        UPDATE [internal].[operations]
            SET [status] = 4,
            [end_time] = SYSDATETIMEOFFSET()
            WHERE [operation_id] = @operation_id;       
        THROW
    END CATCH
    
    RETURN 0
GO


*/

