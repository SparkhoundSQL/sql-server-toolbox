Invoke-Command -script {Install-WindowsFeature -Name "Failover-Clustering" } -ComputerName SQLDEV11, SQLDEV12, SQLQA11, SQLQA12
Invoke-Command -script {Install-WindowsFeature -Name "RSAT-Clustering-Mgmt" } -ComputerName SQLDEV11, SQLDEV12, SQLQA11, SQLQA12
Invoke-Command -script {Install-WindowsFeature -Name "RSAT-Clustering-PowerShell" } -ComputerName SQLDEV11, SQLDEV12, SQLQA11, SQLQA12
