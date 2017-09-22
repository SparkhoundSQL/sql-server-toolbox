#Import-Module SQLPS

#0-- Test AG
    #Setup
    $PrimaryReplicaName = "SQLSERVER-0"
    $PrimaryReplicaInstanceName = "DEFAULT"
    $SecondaryReplicaName1 = "SQLSERVER-1"
    $SecondaryReplicaInstanceName1 = "DEFAULT"
    $AvailabilityGroupName = "WWI2017-AG"

    Set-Location "SQLSERVER:\Sql\$($PrimaryReplicaName)\$($PrimaryReplicaInstanceName)\AvailabilityGroups\$($AvailabilityGroupName)\"

    #In the following line, the %5C character replaces the \ between the SQL Server name and instance name. Passing in \ is invalid, as the \ is in the string, but is confused for a folder path.
    Get-ChildItem "SQLSERVER:\Sql\$($PrimaryReplicaName)\$($PrimaryReplicaInstanceName)\AvailabilityGroups\$($AvailabilityGroupName)\AvailabilityReplicas\$($PrimaryReplicaName+$('%5C')+$PrimaryReplicaInstanceName)" `
    | Test-SqlAvailabilityReplica 

#1-- Planned failover.

    
    #Setup
    $PrimaryReplicaName = "SQLSERVER-0"
    $PrimaryReplicaInstanceName = "DEFAULT"
    $SecondaryReplicaName1 = "SQLSERVER-1"
    $SecondaryReplicaInstanceName1 = "DEFAULT"
    $PrimaryReplica = Get-Item "AvailabilityReplicas\$($PrimaryReplicaName)"
    $SecondaryReplica1 = Get-Item "AvailabilityReplicas\$($SecondaryReplicaName1)"
    Set-Location "SQLSERVER:\Sql\$($PrimaryReplicaName)\$($PrimaryReplicaInstanceName)\AvailabilityGroups\$($AvailabilityGroupName)\"

    Get-ChildItem "SQLSERVER:\Sql\$($PrimaryReplicaName)\$($PrimaryReplicaInstanceName)\AvailabilityGroups\$($AvailabilityGroupName)\AvailabilityReplicas\"  | Test-SqlAvailabilityReplica

    #1-1-- Make the intended failover target temporarily Synchronous in an attempt to prevent data loss. 
    Set-SqlAvailabilityReplica `
        -Path "SQLSERVER:\Sql\$($PrimaryReplicaName)\$($PrimaryReplicaInstanceName)\AvailabilityGroups\$($AvailabilityGroupName)\AvailabilityReplicas\$($SecondaryReplicaName1)" `
        -AvailabilityMode "SynchronousCommit" `
        -FailoverMode "Manual" `
        -ErrorAction Stop
    
    Set-SqlAvailabilityReplica `
        -Path "SQLSERVER:\Sql\$($PrimaryReplicaName)\$($PrimaryReplicaInstanceName)\AvailabilityGroups\$($AvailabilityGroupName)\AvailabilityReplicas\$($PrimaryReplicaName)" `
        -AvailabilityMode "SynchronousCommit" `
        -FailoverMode "Manual" `
        -ErrorAction Stop

    write-host "Waiting"
    Start-Sleep -s 10


    #1-2-- Peform the Planned Failover to SecondaryReplicaName1.
    # Path of the new primary server. DEFAULT for the DEFAULT instance, replace with named instance if need be.
        
    Switch-SqlAvailabilityGroup `
        -Path "SQLSERVER:\Sql\$($SecondaryReplicaName1)\$($SecondaryReplicaInstanceName1)\AvailabilityGroups\$($AvailabilityGroupName)\" `
         -ErrorAction Stop
        #Only include the next line if it is a forced failover
        #-AllowDataLoss -Force
     
     write-host "Switch Made"
     Get-ChildItem "SQLSERVER:\Sql\$($SecondaryReplicaName1)\$($SecondaryReplicaInstanceName1)\AvailabilityGroups\$($AvailabilityGroupName)\AvailabilityReplicas\"  | Test-SqlAvailabilityReplica

    #1-3-- Return secondary replica to Asynchronous
    #Note that the values here of Primary and Secondary1 are flipped, because the variables predate the failover.
       Set-SqlAvailabilityReplica `
        -Path "SQLSERVER:\Sql\$($SecondaryReplicaName1)\$($SecondaryReplicaInstanceName1)\AvailabilityGroups\$($AvailabilityGroupName)\AvailabilityReplicas\$($PrimaryReplicaName)" `
        -AvailabilityMode AsynchronousCommit `
        -ErrorAction Stop
       Set-SqlAvailabilityReplica `
        -Path "SQLSERVER:\Sql\$($SecondaryReplicaName1)\$($SecondaryReplicaInstanceName1)\AvailabilityGroups\$($AvailabilityGroupName)\AvailabilityReplicas\$($SecondaryReplicaName1)" `
        -AvailabilityMode AsynchronousCommit `
        -ErrorAction Stop


    #1-4 Set routing list. 
    #MUST RUN ON NEW PRIMARY NODE
    #You must have a URL to be part of the read-only routing. If URL's have not been specified, they must be before setting Routing List or you will get the error:
    #An availability replica 'SQLSERVER-1' that is specified in the READ_ONLY_ROUTING_LIST for availability replica 'SQLSERVER-0' does not have a value set for READ_ONLY_ROUTING_URL.
    #Run the below only if necessary, but they must be run from the new primary replica. Examples:
    #Set-SqlAvailabilityReplica -ReadOnlyRoutingConnectionUrl "TCP://$($PrimaryReplicaName).contoso.com:1433" -InputObject $PrimaryReplica
    #Set-SqlAvailabilityReplica -ReadOnlyRoutingConnectionUrl "TCP://$($SecondaryReplicaName1).contoso.com:1433" -InputObject $SecondaryReplica1
    
    Set-SqlAvailabilityReplica `
        -ReadOnlyRoutingList $PrimaryReplicaName,$SecondaryReplicaName1 `
        -InputObject $SecondaryReplica1 `
        -ErrorAction Stop




#2- Forced failover
# To be run on the new primary


    #Setup
    $PrimaryReplicaName = "SQLSERVER-1"
    $PrimaryReplicaInstanceName = "DEFAULT"
    $SecondaryReplicaName1 = "SQLSERVER-0"
    $SecondaryReplicaInstanceName1 = "DEFAULT"
    $PrimaryReplica = Get-Item "AvailabilityReplicas\$($PrimaryReplicaName)"
    $SecondaryReplica1 = Get-Item "AvailabilityReplicas\$($SecondaryReplicaName1)"
    Set-Location "SQLSERVER:\Sql\$($PrimaryReplicaName)\$($PrimaryReplicaInstanceName)\AvailabilityGroups\$($AvailabilityGroupName)\"

    Get-ChildItem "SQLSERVER:\Sql\$($PrimaryReplicaName)\$($PrimaryReplicaInstanceName)\AvailabilityGroups\$($AvailabilityGroupName)\AvailabilityReplicas\"  | Test-SqlAvailabilityReplica

    #1-1-- Peform the Planned Failover to SecondaryReplicaName1.
    # Path of the new primary server. DEFAULT for the DEFAULT instance, replace with named instance if need be.
        
    Switch-SqlAvailabilityGroup `
        -Path "SQLSERVER:\Sql\$($SecondaryReplicaName1)\$($SecondaryReplicaInstanceName1)\AvailabilityGroups\$($AvailabilityGroupName)\" `
         -ErrorAction Stop
        #Only include the next line if it is a forced failover
        -AllowDataLoss -Force
     
     write-host "Switch Made"
     Get-ChildItem "SQLSERVER:\Sql\$($SecondaryReplicaName1)\$($SecondaryReplicaInstanceName1)\AvailabilityGroups\$($AvailabilityGroupName)\AvailabilityReplicas\"  | Test-SqlAvailabilityReplica

    #1-2-- Return secondary replica to Asynchronous
    #Note that the values here of Primary and Secondary1 are flipped, because the variables predate the failover.
    #   Set-SqlAvailabilityReplica `
    #    -Path "SQLSERVER:\Sql\$($SecondaryReplicaName1)\$($SecondaryReplicaInstanceName1)\AvailabilityGroups\$($AvailabilityGroupName)\AvailabilityReplicas\$($PrimaryReplicaName)" `
    #    -AvailabilityMode AsynchronousCommit `
    #    -ErrorAction Stop
       Set-SqlAvailabilityReplica `
        -Path "SQLSERVER:\Sql\$($SecondaryReplicaName1)\$($SecondaryReplicaInstanceName1)\AvailabilityGroups\$($AvailabilityGroupName)\AvailabilityReplicas\$($SecondaryReplicaName1)" `
        -AvailabilityMode AsynchronousCommit `
        -ErrorAction Stop


    #1-3 Set routing list. 
    #MUST RUN ON NEW PRIMARY NODE

    #Note that the values here of Primary and Secondary1 are flipped, because the variables predate the failover.
    Set-SqlAvailabilityReplica `
        -ReadOnlyRoutingList $PrimaryReplicaName,$SecondaryReplicaName1 `
        -InputObject $SecondaryReplicaName1 `
        -ErrorAction Stop

    #Must change WSFC Cluster quorum now to force Quorum
