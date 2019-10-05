EXEC sp_MSforeachdb '
--Table variable to capture the DBCC DBINFO output, look for the field we want in each database output
DECLARE @DBCC_DBINFO TABLE (ParentObject VARCHAR(255) NOT NULL, [Object] VARCHAR(255)  NOT NULL, [Field] VARCHAR(255) NOT NULL INDEX idx_dbinfo_field CLUSTERED, [Value] VARCHAR(255));
INSERT INTO @DBCC_DBINFO EXECUTE ("DBCC DBINFO ([?]) WITH TABLERESULTS");
SELECT ''?'', [Value] FROM @DBCC_DBINFO WHERE Field = ''dbi_dbccLastKnownGood'';';
