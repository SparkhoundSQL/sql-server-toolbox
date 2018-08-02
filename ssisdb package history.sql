--Since in SQL 2016 individual packages can be deployed without deploying the entire project, 
--a query more complex than you'd think is necessary to figure out when an individual package actually changed.
--Deploying a single package in a project updates the project's deployment metadata.

select 
	project_name				= pr.name
,	package_name				= pa.name
,	project_version_lsn
,   first_version_created_time = min(ov.created_time)
  
 FROM (	select version_guid, project_id, name, project_version_lsn = min(project_version_lsn) 
			from ssisdb.internal.packages 
			group by project_id, name, version_guid
			) pa
  inner join [SSISDB].[internal].object_versions ov on ov.object_version_lsn = pa.project_version_lsn 
  inner join [SSISDB].[internal].projects pr on pr.project_id = pa.project_id 
  where 
		pr.name = 'DataWarehouse'
	and pa.name = 'DimCurrency.dtsx'
  group by ov.object_version_lsn, pa.name, pa.project_id, project_version_lsn, pr.name
  ORDER BY  pr.name, pa.name, project_version_lsn desc;