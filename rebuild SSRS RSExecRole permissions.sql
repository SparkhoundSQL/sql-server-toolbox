USE [master]
GO
CREATE ROLE [RSExecRole] AUTHORIZATION dbo
GO
--https://docs.microsoft.com/en-us/sql/reporting-services/security/create-the-rsexecrole
GRANT EXECUTE ON master.dbo.xp_sqlagent_notify TO RSExecRole
GRANT EXECUTE ON master.dbo.xp_sqlagent_is_starting TO RSExecRole
GRANT EXECUTE ON master.dbo.xp_sqlagent_enum_jobs TO RSExecRole
GO

use msdb
go
CREATE ROLE [RSExecRole] AUTHORIZATION dbo
GO
GRANT EXECUTE ON msdb.dbo.sp_add_category TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_add_job TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_add_jobschedule TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_add_jobserver TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_add_jobstep TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_delete_job TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_help_category TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_help_job TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_help_jobschedule TO RSExecRole
GRANT EXECUTE ON msdb.dbo.sp_verify_job_identifiers TO RSExecRole

GRANT SELECT ON msdb.dbo.syscategories TO RSExecRole
GRANT SELECT ON msdb.dbo.sysjobs TO RSExecRole
GO