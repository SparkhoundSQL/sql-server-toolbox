--Inventory Baseline
select
    c.cluster_name
    ,c.quorum_state_desc
    ,c.quorum_type_desc
from sys.dm_hadr_cluster c

select
    cm.member_name
    ,cm.member_state_desc
    ,cm.member_type_desc
    ,cm.number_of_quorum_votes
from sys.dm_hadr_cluster_members cm

select
    cn.member_name
    ,cn.is_ipv4
    ,cn.is_public
    ,cn.network_subnet_ip
    ,cn.network_subnet_ipv4_mask
    ,cn.network_subnet_prefix_length
from sys.dm_hadr_cluster_networks cn

SELECT
	gs.primary_replica
	,gs.primary_recovery_health_desc
	,gs.secondary_recovery_health
	,gs.synchronization_health_desc
	,rcs.replica_server_name
	,rcs.join_state_desc
	,rs.role_desc
	,rs.operational_state_desc
	,rs.connected_state_desc
	,rs.synchronization_health_desc
from sys.dm_hadr_availability_group_states gs
inner join sys.dm_hadr_availability_replica_cluster_states rcs
	on gs.group_id=rcs.group_id
inner join sys.dm_hadr_availability_replica_states rs
	on rcs.group_id=rs.group_id
	and rcs.replica_id=rs.replica_id



select
	rcs.replica_server_name
	,rs.role_desc
	,rs.operational_state_desc
	,rs.connected_state_desc
	,drcs.database_name
	,drs.database_state_desc
	,drs.filestream_send_rate
	,drs.is_primary_replica
	,case when drcs.is_database_joined = 1 then 'True' else 'False' end as [is_database_joined]
	,case when drcs.is_failover_ready =1 then 'True' else 'False' end as [is_failover_read]
	,case when drcs.is_pending_secondary_suspend=1 then 'True' else 'False' end as [is_pending_secondary_suspend]
from sys.dm_hadr_database_replica_cluster_states drcs
inner join sys.dm_hadr_database_replica_states drs
	on drs.group_database_id=drcs.group_database_id
	and drs.replica_id=drcs.replica_id
inner join sys.dm_hadr_availability_replica_cluster_states rcs
	on drs.group_id= rcs.group_id
	and drs.replica_id=rcs.replica_id
inner join sys.dm_hadr_availability_replica_states rs
	on rcs.group_id=rs.group_id
	and rcs.replica_id=rs.replica_id