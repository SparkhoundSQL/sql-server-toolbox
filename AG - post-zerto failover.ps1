#Post-Zerto failover script for handling changes to Availability Groups.
#WORK IN PROGRESS. May need to be adjusted for your environment.

#You may want to change these variables to "_DC1" and "_DC2"
$Server_IP_Prod = "10.0.3.179" 
$Server_IP_DR  = "10.35.135.161"
$Cluster_IP_Prod = "10.0.3.181"
$Cluster_IP_DR = "10.35.135.163"
$Listener_IP_Prod = "10.0.3.182"
$Listener_IP_DR = "10.35.135.164"

#not from Failover Cluster Manager or SQL, but from the Get-ClusterResource cmdlet. Usually "Cluster IP Address"
$cluster_resource_name  =  "Cluster IP Address" 
#Get the listener object name, which changes. Follows this pattern: "AGNAME_ListenerIP", example, SCRSQL_10.0.3.182  
$listener_resource_name  =  Get-ClusterResource -Name "SCRSQL_*" | Where-Object -FilterScript { $_.ResourceType -contains "IP Address" } | Select-Object Name
#Name of the AG, which we'll attempt to start at the end.
$AG_resource_name = "SCRSQL"

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

        #Change Cluster IP.
        #Verify step if running manually. Comment out if automated.
        #Get-ClusterResource $cluster_resource_name | Get-ClusterParameter
        $new_ip = $Cluster_IP_DR
        $Current_IP_Cluster_Resource_Name  = Get-ClusterResource -Name $cluster_resource_name
        #Subnet mask will not change after the Zerto failover
        #$new_subnet_mask = "255.255.255.0" #need to determine this info after Zerto failover
        $parameter1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $Current_IP_Cluster_Resource_Name,Address,$new_ip
        #Subnet mask will not change after the Zerto failover
        #$parameter2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $Current_IP_Cluster_Resource_Name,SubnetMask,$new_subnet_mask 
        $parameters = $parameter1 #,$parameter2 
        #Change the IPs. 
        $parameters | Set-ClusterParameter
    
        #This step would happen once after the changes
    Stop-ClusterResource $cluster_resource_name -ErrorAction SilentlyContinue
    Start-ClusterResource $cluster_resource_name -ErrorAction SilentlyContinue

        #Change AG Listener IP.
        #Verify step if running manually. Comment out if automated.
        #Get-ClusterResource $cluster_resource_name | Get-ClusterParameter
        $new_ip = $Listener_IP_DR
        $Current_IP_Cluster_Resource_Name  = Get-ClusterResource -Name $listener_resource_name
        #Subnet mask will not change after the Zerto failover
        #$new_subnet_mask = "255.255.255.0" #need to determine this info after Zerto failover
        $parameter1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $Current_IP_Cluster_Resource_Name,Address,$new_ip
        #Subnet mask will not change after the Zerto failover
        #$parameter2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $Current_IP_Cluster_Resource_Name,SubnetMask,$new_subnet_mask 
        $parameters = $parameter1 #,$parameter2 
        #Change the IPs. 
        $parameters | Set-ClusterParameter    

    #This step would happen once after the changes
    Stop-ClusterResource $cluster_resource_name -ErrorAction SilentlyContinue
    Start-ClusterResource $cluster_resource_name -ErrorAction SilentlyContinue
    Start-ClusterResource $AG_resource_name
}

ElseIf ($currentIP -match $Server_IP_Prod -and $Current_Cluster_ipaddress -match $Cluster_IP_DR )
{
    #We've failed back to PROD. The Server's IP has been updated, but the Cluster hasn't yet.
    
         #Change Cluster IP.
        #Verify step if running manually. Comment out if automated.
        #Get-ClusterResource $cluster_resource_name | Get-ClusterParameter
        $new_ip = $Cluster_IP_Prod
        $Current_IP_Cluster_Resource_Name  = Get-ClusterResource -Name $cluster_resource_name
        #Subnet mask will not change after the Zerto failover
        #$new_subnet_mask = "255.255.255.0" #need to determine this info after Zerto failover
        $parameter1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $Current_IP_Cluster_Resource_Name,Address,$new_ip
        #Subnet mask will not change after the Zerto failover
        #$parameter2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $Current_IP_Cluster_Resource_Name,SubnetMask,$new_subnet_mask 
        $parameters = $parameter1 #,$parameter2 
        #Change the IPs. 
        $parameters | Set-ClusterParameter
    
    #This step would happen once after the changes
    Stop-ClusterResource $cluster_resource_name -ErrorAction SilentlyContinue
    Start-ClusterResource $cluster_resource_name -ErrorAction SilentlyContinue

        #Change AG Listener IP.
        #Verify step if running manually. Comment out if automated.
        #Get-ClusterResource $cluster_resource_name | Get-ClusterParameter
        $new_ip = $Listener_IP_Prod
        $Current_IP_Cluster_Resource_Name  = Get-ClusterResource -Name $listener_resource_name
        #Subnet mask will not change after the Zerto failover
        #$new_subnet_mask = "255.255.255.0" #need to determine this info after Zerto failover
        $parameter1 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $Current_IP_Cluster_Resource_Name,Address,$new_ip
        #Subnet mask will not change after the Zerto failover
        #$parameter2 = New-Object Microsoft.FailoverClusters.PowerShell.ClusterParameter $Current_IP_Cluster_Resource_Name,SubnetMask,$new_subnet_mask 
        $parameters = $parameter1 #,$parameter2 
        #Change the IPs. 
        $parameters | Set-ClusterParameter    

    #This step would happen once after the changes
    Stop-ClusterResource $cluster_resource_name -ErrorAction SilentlyContinue
    Start-ClusterResource $cluster_resource_name -ErrorAction SilentlyContinue
    Start-ClusterResource $AG_resource_name

}

    #Verify step if running manually. Comment out if automated.
    #Get-ClusterResource $cluster_resource_name | Get-ClusterParameter

#This next block doesn't work if the AG can't come online. Leaving it here for future reference only.
#import-module sqlps
#Add new IP for Zerto destination to AG Listener before the failover
#this next step should only need to be done once.
#Add-SqlAvailabilityGroupListenerStaticIp -Path "SQLSERVER:\SQL\localhost\DEFAULT\AvailabilityGroups\SCRSQL\AvailabilityGroupListeners\scrsqlp01vip" -StaticIp "10.35.135.164/255.255.255.0" -Script
    