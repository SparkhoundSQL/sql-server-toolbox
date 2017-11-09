<#
Invoke-Command -script {Install-WindowsFeature -Name "Failover-Clustering" } `
-ComputerName SQLDEV11, SQLDEV12, SQLDEV14, SQLDEV15
Invoke-Command -script {Install-WindowsFeature -Name "RSAT-Clustering-Mgmt" } `
-ComputerName SQLDEV11, SQLDEV12, SQLDEV14, SQLDEV15
Invoke-Command -script {Install-WindowsFeature -Name "RSAT-Clustering-PowerShell" } `
-ComputerName SQLDEV11, SQLDEV12, SQLDEV14, SQLDEV15
#>
#Install-Module SQLSERVER -Force -AllowCLobber 
#Import-Module SQLSERVER

#Must run on the primary node
#TODO: configure initial variable values.

Write-Output "Begin $(Get-Date)"
#Setup: TODO Configure these
$PrimaryReplicaName = "SQLSERVER-0"
$PrimaryReplicaInstanceName = "SQL2K17" #Named instance or DEFAULT for the default instance
$SecondaryReplicaName1 = "SQLSERVER-1"
$SecondaryReplicaInstanceName1 = "SQL2K17" #Named instance or DEFAULT for the default instance
$AvailabilityGroupName = "WWI2017-clusterless"

#Inventory and test
Get-ChildItem "SQLSERVER:\Sql\$($PrimaryReplicaName)\$($PrimaryReplicaInstanceName)\AvailabilityGroups\$($AvailabilityGroupName)\AvailabilityReplicas\" | Test-SqlAvailabilityReplica | Format-Table

   $AGPrimaryObjPath = "SQLSERVER:\Sql\$($PrimaryReplicaName)\$($PrimaryReplicaInstanceName)\AvailabilityGroups\$($AvailabilityGroupName)\AvailabilityReplicas\$($PrimaryReplicaName+$(IF($PrimaryReplicaInstanceName -ne "DEFAULT"){$("%5C")+$PrimaryReplicaInstanceName} ))"
   $AGPrimaryObj = Get-Item $AGPrimaryObjPath 
   $AGSecondaryObjPath = "SQLSERVER:\Sql\$($PrimaryReplicaName)\$($PrimaryReplicaInstanceName)\AvailabilityGroups\$($AvailabilityGroupName)\AvailabilityReplicas\$($SecondaryReplicaName1+$(IF($SecondaryReplicaInstanceName1 -ne "DEFAULT"){$("%5C")+$SecondaryReplicaInstanceName1} ))"
   $AGSecondaryObj = Get-Item $AGSecondaryObjPath


   
#Set replicas to synchronous before planned failover
        
    Set-SqlAvailabilityReplica `
    -Path $AGPrimaryObjPath `
    -AvailabilityMode SynchronousCommit `
    -FailoverMode "Manual" `
    -ErrorAction Stop
    Set-SqlAvailabilityReplica `
    -Path $AGSecondaryObjPath `
    -AvailabilityMode SynchronousCommit `
    -FailoverMode "Manual" `
    -ErrorAction Stop

#Check for when replicas are synchronized.
Do {
$AGSecondaryObj.Refresh()
$CurrentSync = ($AGSecondaryObj | Select RollupSynchronizationState | Format-Wide | Out-String).Trim()
IF ($CurrentSync -ne "Synchronized") { 
        Write-Output "Waiting for Synchronized state before failover, still $($CurrentSync)"
        Start-Sleep -s 2 
        }
} Until ($CurrentSync -eq 'Synchronized')

#Perform failover
Write-Output "Beginning Failover $(Get-Date)"
Switch-SqlAvailabilityGroup `
    -Path "SQLSERVER:\Sql\$($SecondaryReplicaName1)\$($SecondaryReplicaInstanceName1)\AvailabilityGroups\$($AvailabilityGroupName)\" `
     -ErrorAction Stop `
    #Only include the next line if it is a forced failover
    #-AllowDataLoss -Force
Write-Output "Failover Complete $(Get-Date)"
Start-Sleep -s 10 #Allow failover to resolve

#Return secondary replica to Asynchronous sync
#Note that the values here of Primary and Secondary1 are flipped, because the variables predate the failover.
Invoke-Command -script { `
param($SecondaryReplicaName1, $SecondaryReplicaInstanceName1, $AvailabilityGroupName, $PrimaryReplicaName, $PrimaryReplicaInstanceName)

 Set-SqlAvailabilityReplica `
-Path "SQLSERVER:\Sql\$(($SecondaryReplicaName1))\$(($SecondaryReplicaInstanceName1))\AvailabilityGroups\$(($AvailabilityGroupName))\AvailabilityReplicas\$(($SecondaryReplicaName1)+$(IF(($SecondaryReplicaInstanceName1) -ne "DEFAULT"){$("%5C")+(($SecondaryReplicaInstanceName1))} ))"  `
-AvailabilityMode asynchronousCommit `
-ErrorAction Stop
    Set-SqlAvailabilityReplica `
-Path "SQLSERVER:\Sql\$(($SecondaryReplicaName1))\$(($SecondaryReplicaInstanceName1))\AvailabilityGroups\$(($AvailabilityGroupName))\AvailabilityReplicas\$(($PrimaryReplicaName)+$(IF(($PrimaryReplicaInstanceName) -ne "DEFAULT"){$("%5C")+(($PrimaryReplicaInstanceName))} ))"  `
-AvailabilityMode asynchronousCommit `
-ErrorAction Stop

Get-ChildItem "SQLSERVER:\Sql\$($SecondaryReplicaName1)\$($SecondaryReplicaInstanceName1)\AvailabilityGroups\$($AvailabilityGroupName)\AvailabilityReplicas\" | Test-SqlAvailabilityReplica | Format-Table
} -ComputerName $SecondaryReplicaName1  -Args $SecondaryReplicaName1, $SecondaryReplicaInstanceName1, $AvailabilityGroupName, $PrimaryReplicaName, $PrimaryReplicaInstanceName

Write-Output "End $(Get-Date)"



    #1-3 Set routing list. 
    #MUST RUN ON NEW PRIMARY NODE

    #Note that the values here of Primary and Secondary1 are flipped, because the variables predate the failover.
    Set-SqlAvailabilityReplica `
        -ReadOnlyRoutingList $PrimaryReplicaName,$SecondaryReplicaName1 `
        -InputObject $SecondaryReplicaName1 `
        -ErrorAction Stop

    #Must change WSFC Cluster quorum now to force Quorum
