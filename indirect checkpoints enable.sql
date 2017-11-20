--For SQL 2016+ and above, where 60 (indirect checkpoints) is now the default
use master
go
select 'ALTER DATABASE ['+d.name+'] SET TARGET_RECOVERY_TIME = 60 SECONDS WITH NO_WAIT' from sys.databases d where target_recovery_time_in_seconds = 0

