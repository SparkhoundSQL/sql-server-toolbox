
USE [master]
GO
select 
Alter_Autogrowth_Rates = case when mf.type_desc = 'ROWS' 
	then 'ALTER DATABASE ['+d.name+'] MODIFY FILE ( NAME = N'''+ mf.name+ ''', FILEGROWTH = 256MB );
GO' 
	else 'ALTER DATABASE ['+d.name+'] MODIFY FILE ( NAME = N'''+ mf.name+ ''', FILEGROWTH = 256MB );
GO' 
	end
, mf.*
FROM sys.databases d
inner join sys.master_files mf
on d.database_id = mf.database_id
where (d.state_desc = 'ONLINE')
and (d.is_read_only = 0)
and ((mf.is_percent_growth = 0 and growth = 128) or (mf.is_percent_growth = 1))
/*
ALTER DATABASE [model] MODIFY FILE ( NAME = N'modeldev', FILEGROWTH = 512000KB )
*/
