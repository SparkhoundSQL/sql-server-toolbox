
#https://docs.microsoft.com/en-us/sql/sql-server/failover-clusters/windows/change-the-ip-address-of-a-failover-cluster-instance?view=sql-server-2017
#https://docs.microsoft.com/en-us/powershell/module/failoverclusters/set-clusterparameter?view=win10-ps

#TODO: Uncomment Set-ClusterParameter commands for safety. 

#This is for N01
#For N02, change the first two variable names below, $Server_IP_Prod and $Server_IP_DR

#You may want to change these variables to "_DC1" and "_DC2"
$Server_IP_Prod = "10.0.3.179" 
$Server_IP_DR  = "10.35.135.161"
$Cluster_IP_Prod = "10.0.3.181"
$Cluster_IP_DR = "10.35.135.163"

$cluster_resource_name  =  "Cluster IP Address" #not from Failover Cluster Manager or SQL, but from the Get-ClusterResource cmdlet. Usually "Cluster IP Address"
#$listener_name = "GSFSQASCS_172.20.63.21" #not from Failover Cluster Manager or SQL, but from the Get-ClusterResource cmdlet. USually it's "AGname_IPAddress"

#Figure out where we are right now.
$Current_Cluster_ipaddress = get-clusterresource -Name "Cluster IP Address" | Get-ClusterParameter -Name "Address" | Select-Object Value 
$CurrentIP = get-netipaddress | Where-Object -FilterScript { $_.IPAddress -contains $Server_IP_Prod -or $_.IPAddress -contains $Server_IP_DR} | Select-Object IPAddress

If ($currentIP -match $Server_IP_Prod -and $Current_Cluster_ipaddress -match $Cluster_IP_Prod )
{ 
    #We're in PROD and Cluster agrees, nothing to do
}
ElseIf ($currentIP -match $Server_IP_DR -and $Current_Cluster_ipaddress -match $Cluster_IP_DR )
{ 
    #We're in DR and Cluster agrees, nothing to do
}
ElseIf ($currentIP -match $Server_IP_DR -and $Current_Cluster_ipaddress -match $Cluster_IP_Prod )
{
    #We've failed over to DR. The Server's IP has been updated, but the Cluster hasn't yet.

    import-module sqlps
    #Add new IP for xerto destination to AG Listener before the failover
    #this next step should only need to be done once.
    Add-SqlAvailabilityGroupListenerStaticIp -Path "SQLSERVER:\SQL\localhost\DEFAULT\AvailabilityGroups\SCRSQL\AvailabilityGroupListeners\scrsqlp01vip" -StaticIp "10.35.135.164/255.255.255.0" -Script
  

        #Verify
        Get-ClusterResource $cluster_resource_name | Get-ClusterParameter

        $new_ip = $Cluster_IP_DR
        $Current_IP_Cluster_Resource_Name  = Get-ClusterResource -Name $cluster_resource_name

        #Subnet mask will not change after the Xerto failover
        #$new_subnet_mask = "255.255.255.0" #need to determine this info after xerto failover
            
        $parameter1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $Current_IP_Cluster_Resource_Name,Address,$new_ip
        #Subnet mask will not change after the Xerto failover
        #$parameter2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $Current_IP_Cluster_Resource_Name,SubnetMask,$new_subnet_mask 
        $parameters = $parameter1 #,$parameter2 
         
        #Change the IPs
        #Uncomment the below line to actually have an impact! Commented for safety.
        $parameters #| Set-ClusterParameter
            

    #This step would happen once after the changes
    #Make the change happen
    Stop-ClusterResource $cluster_resource_name
    Start-ClusterResource $cluster_resource_name
}

ElseIf ($currentIP -match $Server_IP_Prod -and $Current_Cluster_ipaddress -match $Cluster_IP_DR )
{
    #We've failed back to PROD. The Server's IP has been updated, but the Cluster hasn't yet.
    
        #Verify
        Get-ClusterResource $cluster_resource_name | Get-ClusterParameter

        $new_ip = $Cluster_IP_DR
        $Current_IP_Cluster_Resource_Name  = Get-ClusterResource -Name $cluster_resource_name

        #Subnet mask will not change after the Xerto failover
        #$new_subnet_mask = "255.255.255.0" #need to determine this info after xerto failover
            
        $parameter1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $Current_IP_Cluster_Resource_Name,Address,$new_ip
        #Subnet mask will not change after the Xerto failover
        #$parameter2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $Current_IP_Cluster_Resource_Name,SubnetMask,$new_subnet_mask 
        $parameters = $parameter1 #,$parameter2 
         
        #Change the IPs
        #Uncomment the below line to actually have an impact! Commented for safety.
        $parameters #| Set-ClusterParameter
            

    #This step would happen once after the changes
    #Make the change happen
    Stop-ClusterResource $cluster_resource_name
    Start-ClusterResource $cluster_resource_name
     

}

    #Verify
    Get-ClusterResource $cluster_resource_name | Get-ClusterParameter