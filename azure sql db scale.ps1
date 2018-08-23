#Install-Module AzureRM.Sql -Force
Login-AzureRmAccount

get-AzureRmSqlDatabase -ResourceGroupName "AppServices-TeamLeads" -DatabaseName "LunchQueue" -ServerName "sparkhound-appservices" | select-object DatabaseName, currentserviceobjectivename 

set-AzureRmSqlDatabase -ResourceGroupName "AppServices-TeamLeads" -DatabaseName "LunchQueue" -ServerName "sparkhound-appservices" -RequestedServiceObjectiveName "S1"

get-AzureRmSqlDatabase -ResourceGroupName "AppServices-TeamLeads" -DatabaseName "LunchQueue" -ServerName "sparkhound-appservices" | select-object DatabaseName, currentserviceobjectivename 

