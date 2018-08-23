#Forced failover

import-module failoverclusters
Stop-ClusterNode -Name "servername" #Intended server to failover to
Start-ClusterNode -Name "servername" -FixQuorum

(Get-ClusterNode -Name "servername").NodeWeight=1

$Nodes = Get-ClusterNode -Cluster "servername"
$Nodes
