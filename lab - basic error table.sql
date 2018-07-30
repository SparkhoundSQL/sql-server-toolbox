USE DBALogging
GO
begin try
select 1/0
end try
begin catch
	INSERT INTO DBALogging.dbo.errortable ([ErrorNumber], [ErrorSeverity], [ErrorState], [ErrorProcedure], [ErrorLine], [ErrorMessage], [Process])
	SELECT ERROR_NUMBER() AS ErrorNumber, ERROR_SEVERITY() AS ErrorSeverity, ERROR_STATE() as ErrorState, ERROR_PROCEDURE() as ErrorProcedure, ERROR_LINE() as ErrorLine, ERROR_MESSAGE() as ErrorMessage
		, Process = 'Testing'; --need the semicolon

	THROW --optional, to actually cause a failure.
end catch
GO
select * from DBALogging.dbo.errortable 
GOa
/*
DROP TABLE [dbo].[errortable]
GO
CREATE TABLE [dbo].[errortable](
	id bigint not null IDENTITY(1,1) CONSTRAINT PK_errortable PRIMARY KEY,
	[ErrorNumber] [int] NULL,
	[ErrorSeverity] [int] NULL,
	[ErrorState] [int] NULL,
	[ErrorProcedure] [nvarchar](128) NULL,
	[ErrorLine] [int] NULL,
	[ErrorMessage] [nvarchar](4000) NULL,
	[Process] varchar(8000) NOT NULL,
	[WhenObserved] datetimeoffset(0) NOT NULL CONSTRAINT DF_ErrorTable_WhenObserved DEFAULT (sysdatetimeoffset())	
) ON [PRIMARY]
GO
*/