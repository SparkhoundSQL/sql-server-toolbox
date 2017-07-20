	/*

USE [DBAHound]
GO
DROP TABLE [dbo].[ExecRequests_connections]
GO
CREATE TABLE [dbo].[ExecRequests_connections](
	id int not null IDENTITY(1,1),
	[login_name] [nvarchar](128) NOT NULL,
	[client_interface_name] [nvarchar](32) NULL,
	[host_name] [nvarchar](128) NULL,
	[nt_domain] [nvarchar](128) NULL,
	[nt_user_name] [nvarchar](128) NULL,
	[endpoint_name] [sysname] NULL,
	[program_name] [nvarchar](128) NULL,
	[observed_count] bigint NOT NULL CONSTRAINT DF_ExecRequests_connections_observed_count DEFAULT(0),
CONSTRAINT pk_execrequests_connections_id PRIMARY KEY (ID)
) ON [PRIMARY]
CREATE INDEX idx_execrequests_connections ON execrequests_connections (login_name, client_interface_name, [host_name], nt_domain, nt_user_name, endpoint_name, [program_name])
GO


*/
	
	insert into dbo.ExecRequests_connections (
		login_name, client_interface_name, [host_name], nt_domain, nt_user_name, [program_name], endpoint_name
	)
	select  
	LEFT(s.login_name, 128), LEFT(s.client_interface_name, 128), LEFT(s.[host_name], 128), LEFT(s.nt_domain, 128), LEFT(s.nt_user_name, 128), LEFT(s.[program_name], 128), e.name 
	from sys.dm_exec_sessions s 
	left outer join sys.endpoints E ON E.endpoint_id = s.endpoint_id 
	left outer join dbo.ExecRequests_connections erc
	on  
		erc.login_name				=	LEFT(s.login_name, 128)
	and erc.client_interface_name	=	LEFT(s.client_interface_name, 128)
	and erc.[host_name]				=	LEFT(s.[host_name], 128)
	and erc.nt_domain				=	LEFT(s.nt_domain, 128)
	and erc.nt_user_name			=	LEFT(s.nt_user_name, 128)
	and erc.[program_name]			=	LEFT(s.[program_name], 128)
	and erc.endpoint_name			=	e.name
	where 
		s.session_id >= 50 --retrieve only user spids
	and s.session_id <> @@SPID --ignore myself
	and erc.id is null
	GROUP BY LEFT(s.login_name, 128), LEFT(s.client_interface_name, 128), LEFT(s.[host_name], 128), LEFT(s.nt_domain, 128), LEFT(s.nt_user_name, 128), LEFT(s.[program_name], 128), e.name 
	
	
	GO
	
	UPDATE erc
	SET observed_count = observed_count + s.session_id_count
	FROM dbo.ExecRequests_connections erc
	inner join (select s.login_name, s.client_interface_name, s.[host_name], s.nt_domain, s.nt_user_name, s.[program_name], s.endpoint_id, session_id_count = count(session_id) from sys.dm_exec_sessions s
	where 
		s.session_id >= 50 --retrieve only user spids
	and s.session_id <> @@SPID --ignore myself
	GROUP BY s.login_name, s.client_interface_name, s.[host_name], s.nt_domain, s.nt_user_name, s.[program_name], s.endpoint_id
	) s 
	on  
		erc.login_name				=	LEFT(s.login_name, 128)
	and erc.client_interface_name	=	LEFT(s.client_interface_name, 128)
	and erc.[host_name]				=	LEFT(s.[host_name], 128)
	and erc.nt_domain				=	LEFT(s.nt_domain, 128)
	and erc.nt_user_name			=	LEFT(s.nt_user_name, 128)
	and erc.[program_name]			=	LEFT(s.[program_name], 128)
	left outer join sys.endpoints e
	ON E.endpoint_id = s.endpoint_id 
	and erc.endpoint_name			=	e.name
	
--select * from dbo.ExecRequests_connections erc