#Must run this via RDP into the App or Web SharePoint server in the farm, maybe not the same as the SQL Server
#Launch the "SharePoint 201x Management Shell" as Administrator
#This script overwrites C:\Content_Inventory.csv 

Get-SPDatabase | Sort-Object Name | Select-Object Name, Type, @{Label ="Size in MB"; Expression = {$_.disksizerequired/1024/1024}} | Export-CSV -Path C:\Content_Inventory.csv -NoTypeInformation

#Below only works with PS Remoting is enabled.
$SharePoint_App_or_WFE_servername = "sh-sp2013-app1.sparkhound.com"
Invoke-Command -script { 
    Get-SPDatabase | Sort-Object Name | Select-Object Name, Type, @{Label ="Size in MB"; Expression = {$_.disksizerequired/1024/1024}} | Export-CSV -Path C:\Content_Inventory.csv -NoTypeInformation
  } -ComputerName $SharePoint_App_or_WFE_servername  


<#
#Use new sharepoint modules
#This section just a stub

#Get latest gallery
Install-Module -Name PowerShellGet -Force
#Get get SharePoint modules 
Install-Module -Name SharePointDSC -Force -AllowClobber
Import-Module -Name SharePointDSC -Force 
Get-DscResource -Module SharePointDsc
#>


