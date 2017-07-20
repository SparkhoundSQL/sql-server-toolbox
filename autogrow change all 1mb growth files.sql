

USE [master]
GO
select 'ALTER DATABASE ['+d.name+'] MODIFY FILE ( NAME = N'''+ mf.name+ ''', FILEGROWTH = 512000KB )'
, mf.*
FROM sys.databases d
inner join sys.master_files mf
on d.database_id = mf.database_id
where mf.is_percent_growth = 0 and growth = 128

/*
ALTER DATABASE [model] MODIFY FILE ( NAME = N'modeldev', FILEGROWTH = 512000KB )

*/