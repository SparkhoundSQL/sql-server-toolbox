/*
This script will take all environment variables in an existing environment and make "insert" scripts 
out of them so you can easily deploy them to a new server or a new environment on the same server.
 
Script first created by Henning Frettem, www.thefirstsql.com, 2013-05-28, adapted by William Assaf 2015-07-20

Integration Services Catalogs / SSISDB / Folder_Name / Projects / ETLName
									
										
*/
use ssisdb 
go
SET NOCOUNT ON
 
DECLARE
    @folder_name nvarchar(200)              = 'Folder_Name',
    @environment_name_current nvarchar(200) = 'TEST',
    @environment_name_new nvarchar(200)     = 'TEST',
    @name sysname, 
    @sensitive bit, 
    @description nvarchar(1024), 
    @value sql_variant, 
    @type nvarchar(128)
 
PRINT 'DECLARE 
    @folder_id bigint,
    @environment_id bigint'
 
PRINT ''
 
--> Create folder if it doesn't exist and get folder_id
PRINT 'IF NOT EXISTS (SELECT 1 FROM [SSISDB].[catalog].[folders] WHERE name = N''' + @folder_name + ''')
    EXEC [SSISDB].[catalog].[create_folder] @folder_name=N''' + @folder_name + ''', @folder_id=@folder_id OUTPUT
ELSE
    SET @folder_id = (SELECT folder_id FROM [SSISDB].[catalog].[folders] WHERE name = N''' + @folder_name + ''')'
 
PRINT ''
 
--> Create environment if it doesn't exist
PRINT 'IF NOT EXISTS (SELECT 1 FROM [SSISDB].[catalog].[environments] WHERE folder_id = @folder_id AND name = N''' + @environment_name_new + ''')
    EXEC [SSISDB].[catalog].[create_environment] @environment_name=N''' + @environment_name_new + ''', @folder_name=N''' + @folder_name + ''''
 
PRINT ''
 
--> Get the environment_id
PRINT 'SET @environment_id = (SELECT environment_id FROM [SSISDB].[catalog].[environments] WHERE folder_id = @folder_id and name = N''' + @environment_name_new + ''')'
 
PRINT ''
 
--> Making cursor because mapping of sql_variant datatype is different than the normal datatypes
DECLARE cur CURSOR FOR
    SELECT c.name, c.sensitive, c.description, c.value, c.type
    FROM [SSISDB].[catalog].[folders] a
        INNER JOIN [SSISDB].[catalog].[environments] b
            ON a.folder_id =  b.folder_id
        INNER JOIN [SSISDB].[catalog].[environment_variables] c
            ON b.environment_id = c.environment_id
    WHERE a.name = @folder_name
        AND b.name = @environment_name_current
 
OPEN cur
FETCH NEXT FROM cur INTO @name, @sensitive, @description, @value, @type
 
PRINT 'DECLARE @var sql_variant'
PRINT ''
 
WHILE (@@FETCH_STATUS = 0)
    BEGIN
        PRINT 'SET @var = N''' + CONVERT(nvarchar(max), @value) + ''''
 
        PRINT 'IF NOT EXISTS (SELECT 1 FROM [SSISDB].[catalog].[environment_variables] WHERE environment_id = @environment_id AND name = N''' 
		PRINT + @name + ''')'
        PRINT  ' EXEC [SSISDB].[catalog].[create_environment_variable] @variable_name=N''' + @name + ''', @sensitive=' + CONVERT(varchar(2), @sensitive) + ', @description=N''' + @description + ''', @environment_name=N''' + @environment_name_new + ''', @folder_name=N''' + @folder_name + ''', @value=@var, @data_type=N''' + @type + ''''
 
        PRINT ''
 
    FETCH NEXT FROM cur INTO @name, @sensitive, @description, @value, @type
    END
 
CLOSE cur
DEALLOCATE cur