CREATE PROCEDURE sp_GetAGInformation

AS
--http://sirsql.net/blog/2014/10/26/gathering-ag-information-spgetaginformation
/******************************************************************************************************************
*																												  *
* Proc will gather relevant AG information on the currently selected node. 										  *
* It will only return information for AGs for which this is the primary as certain information is only kept there *
*																												  *
******************************************************************************************************************/

/* Declare a whole bunch of table variables. It may seem ugly, but it is far more efficient than constantly
	joining back to the TVFs and DMVs which hold the AG information
*/
DECLARE @RoutingOrder TABLE (
	Replica_ID UNIQUEIDENTIFIER
	, routing_priority INT
	, read_only_replica_id UNIQUEIDENTIFIER
	, PrimaryServer nvarchar(512)
	, ReadReplica NVARCHAR(512)
	)

DECLARE @ReadRoutingFinal TABLE (
	name SYSNAME
	, availability_mode TINYINT
	, failover_mode TINYINT
	, ReadRoutingOrder NVARCHAR(1000)
	)

DECLARE @AvailabilityGroups TABLE ( 
	Name SYSNAME
	, group_id UNIQUEIDENTIFIER
	)

DECLARE @AvailabilityReplicas TABLE ( 
	group_id UNIQUEIDENTIFIER
	, replica_id UNIQUEIDENTIFIER
	, replica_server_name NVARCHAR(256)
	, availability_mode TINYINT
	, failover_mode TINYINT
	)

DECLARE @AvailabilityReplicaStates TABLE ( 
	group_id UNIQUEIDENTIFIER
	, replica_id UNIQUEIDENTIFIER
	, role_desc NVARCHAR(60)
	, role TINYINT
	)

DECLARE @AvailabilityDatabases TABLE (
	name SYSNAME
	, database_name NVARCHAR(256)
	)

DECLARE @AGDatabasesFinal TABLE (
	name SYSNAME
	, DatabaseList NVARCHAR(1000)
	)

/* Load up the table vars with the relevant data from each DMV */
INSERT INTO @AvailabilityReplicaStates
	SELECT group_id
			, replica_id
			, role_desc
			, role
	FROM sys.dm_hadr_availability_replica_states


INSERT INTO @AvailabilityReplicas
	SELECT group_id	
			, replica_id
			, replica_server_name
			, availability_mode
			, failover_mode
	FROM sys.availability_replicas


INSERT INTO @AvailabilityGroups
	SELECT name
			, group_id
	FROM sys.availability_groups


INSERT INTO @RoutingOrder
	SELECT l.replica_id
			, l.routing_priority
			, l.read_only_replica_id
			, r.replica_server_name as PrimaryServer
			, r2.replica_server_name as ReadReplica
	FROM sys.availability_read_only_routing_lists l
			join @AvailabilityReplicas r on l.replica_id = r.replica_id
			join @AvailabilityReplicas r2 on l.read_only_replica_id = r2.replica_id


	--Aggregate Read Routing for report
;with cteReadReplicas AS (
		select replica_id
		 ,PrimaryServer
		, STUFF((SELECT N', ' + ReadReplica FROM @RoutingOrder cr2 WHERE cr2.PrimaryServer = cr.PrimaryServer and cr2.replica_id = cr.replica_id order by cr2.routing_priority
				for xml path(N''), type).value(N'.[1]', N'nvarchar(1000)'),1,2,N'') as ReadRoutingOrder
		from @RoutingOrder cr		
		group by Replica_ID, PrimaryServer	
		)


	--Final details for read routing
INSERT INTO @ReadRoutingFinal
		select 
				ag.name
				, ar.availability_mode --1 sync, 2 async
				, ar.failover_mode --0 auto, 1 manual
				, c.ReadRoutingOrder
		 From @AvailabilityGroups ag
				join @AvailabilityReplicas ar on ag.group_id = ar.group_id
				join @AvailabilityReplicaStates hars on ar.group_id = hars.group_id and ar.replica_id = hars.replica_id
				left join cteReadReplicas c on hars.replica_id = c.replica_id and hars.role = 1
		where hars.role = 1


	--Details for Databases in an AG
INSERT INTO @AvailabilityDatabases
	SELECT a.name
			, adc.database_name
	FROM sys.availability_databases_cluster adc
			JOIN @AvailabilityGroups a ON a.group_id = adc.group_id

INSERT INTO @AGDatabasesFinal
	SELECT name
		, STUFF((SELECT N', ' + database_name FROM @AvailabilityDatabases ad2 WHERE ad2.name = ad.name order by ad2.database_name
				for xml path(N''), type).value(N'.[1]', N'nvarchar(1000)'),1,2,N'') as DatabaseList
	FROM @AvailabilityDatabases ad
	GROUP BY name


	--The primary for the AG
;with ctePrimary AS 
	(
		select 
				ag.name
				, ar.availability_mode --1 sync, 2 async
				, ar.replica_server_name as PrimaryReplica
				, ar.replica_id as PrimaryReplicaId
				, ar.failover_mode --0 auto, 1 manual
		 From @AvailabilityGroups ag
				join @AvailabilityReplicas ar on ag.group_id = ar.group_id
				join @AvailabilityReplicas ar2 on ag.group_id = ar2.group_id
				join @AvailabilityReplicaStates hars on ar.group_id = hars.group_id and ar.replica_id = hars.replica_id 
		where hars.role_desc = 'PRIMARY'
		group by ag.name, ar.availability_mode, ar.replica_server_name, ar.replica_id, ar.failover_mode, hars.role_desc
	)

	--Any auto failover partners
, cteFailoverPartner AS (
		select 
				ag.name
				, ar.replica_server_name as FailoverPartner
		From @AvailabilityGroups ag
				join @AvailabilityReplicas ar on ag.group_id = ar.group_id
				join @AvailabilityReplicas ar2 on ag.group_id = ar2.group_id
				join @AvailabilityReplicaStates hars on ar.group_id = hars.group_id and ar.replica_id = hars.replica_id 
		where hars.role_desc = 'SECONDARY' and ar.availability_mode = 1 and ar.failover_mode = 0
		group by ag.name, ar.availability_mode, ar.replica_server_name, ar.replica_id, ar.failover_mode
	)



	--Any sync secondary replicas
, cteSyncSecondary AS (
		select 
				ag.name
				, ar.replica_server_name as SyncSecondary
				, ROW_NUMBER() OVER (PARTITION BY ag.name ORDER BY CASE WHEN ar.failover_mode = 0 THEN 1 ELSE 2 END) as SyncRowNum
		 From @AvailabilityGroups ag
				join @AvailabilityReplicas ar on ag.group_id = ar.group_id
				join @AvailabilityReplicas ar2 on ag.group_id = ar2.group_id
				join @AvailabilityReplicaStates hars on ar.group_id = hars.group_id and ar.replica_id = hars.replica_id 
		where hars.role_desc = 'SECONDARY' and ar.availability_mode = 1 --and ar.failover_mode = 0
		group by ag.name, ar.availability_mode, ar.replica_server_name, ar.replica_id, ar.failover_mode
	)

	--Any async secondary replicas
, cteAsyncSecondary AS (
		select 
				ag.name
				, ar.replica_server_name as AsyncSecondary
				, ROW_NUMBER() OVER (PARTITION BY ag.name ORDER BY ar.replica_server_name) as ASyncRowNum
		 From @AvailabilityGroups ag
				join @AvailabilityReplicas ar on ag.group_id = ar.group_id
				join @AvailabilityReplicas ar2 on ag.group_id = ar2.group_id
				join @AvailabilityReplicaStates hars on ar.group_id = hars.group_id and ar.replica_id = hars.replica_id 
		where hars.role_desc = 'SECONDARY' and ar.availability_mode = 0 --and ar.failover_mode = 0
		group by ag.name, ar.availability_mode, ar.replica_server_name, ar.replica_id, ar.failover_mode
	)

	--Build Sync replica basic information
, ctePartnerResults AS (
		select c1.*, c2.FailoverPartner, c3.SyncSecondary, c3.SyncRowNum
		From ctePrimary c1 
				left join cteFailoverPartner c2 on c1.name = c2.name
				left join cteSyncSecondary c3 on c1.name = c3.name
		group by c1.name, c1.availability_mode, c1.PrimaryReplica, c1.PrimaryReplicaId, c1.failover_mode
				, c2.FailoverPartner
				, c3.SyncSecondary, c3.SyncRowNum
	)

	--Build comma delimited sync secondary list
, cteSyncList AS (
		select
			name
			, PrimaryReplica
			, FailoverPartner
			, STUFF((SELECT N', ' + cpr2.SyncSecondary FROM ctePartnerResults cpr2 WHERE cpr2.name = cpr.name order by cpr2.SyncRowNum
							for xml path(N''), type).value(N'.[1]', N'nvarchar(1000)'),1,2,N'') as SyncSecondaries
		from ctePartnerResults cpr
		group by name, FailoverPartner, PrimaryReplica
	)

	--Build async replica basic information
, cteASyncPartnerResults AS (
		select c1.*, c2.FailoverPartner, c4.AsyncSecondary, c4.ASyncRowNum
		From ctePrimary c1 
				left join cteFailoverPartner c2 on c1.name = c2.name
				left join cteAsyncSecondary c4 on c1.name = c4.name
		group by c1.name, c1.availability_mode, c1.PrimaryReplica, c1.PrimaryReplicaId, c1.failover_mode
				, c2.FailoverPartner
				, c4.AsyncSecondary, c4.ASyncRowNum
	)

	--Build comma delimited sync secondary list
, cteASyncList AS (
		select
				name
				, FailoverPartner
				, STUFF((SELECT N', ' + cpr2.ASyncSecondary FROM cteASyncPartnerResults cpr2 WHERE cpr2.name = cpr.name order by cpr2.ASyncRowNum
								for xml path(N''), type).value(N'.[1]', N'nvarchar(1000)'),1,2,N'') as ASyncSecondaries
		from cteASyncPartnerResults cpr
		group by name, FailoverPartner
	)

	--Merge all the data and give the complete AG reference
select 
	 csl.name as AGName
	 , ISNULL(agl.dns_name,'') as ListenerName
	 , csl.PrimaryReplica
	 , ISNULL(csl.FailoverPartner,'') as AutoFailoverPartner
	 , ISNULL(csl.SyncSecondaries, '') as SyncSecondaries
	 , ISNULL(casl.ASyncSecondaries, '') as ASyncSecondaries
	 , ISNULL(crr.ReadRoutingOrder, '') as ReadRoutingOrder
	 , DatabaseList
from cteSyncList csl
		join @AvailabilityGroups ag on csl.name = ag.name
		join @AGDatabasesFinal adf on ag.name = adf.name
		left join sys.availability_group_listeners agl on ag.group_id = agl.group_id
		left join cteASyncList casl on csl.name = casl.name
		left join @ReadRoutingFinal crr on csl.name = crr.name
where PrimaryReplica = @@servername
OPTION (MAXDOP 1, RECOMPILE)


