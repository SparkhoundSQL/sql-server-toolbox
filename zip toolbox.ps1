#There is a Windows Scheduled task on my machine that runs
#PowerShell -File "E:\OneDrive\toolbox\zip toolbox.ps1"

#Full toolbox
cd E:\OneDrive\toolbox
get-childitem .\* -Recurse | Where-Object {$_.FullName -notlike '*\.git*' }  | Where-Object {$_.FullName -notlike "*.zip" } | Compress-Archive -DestinationPath .\toolbox.zip -Force 

#Stable state checklist files only
$stablestate  = (
    '*Add Agent Failure Notifications job*',
    '*Autogrowth*',
    'Backup History*', 
    '*Configuration Changes History*', 
    '*Database Owner*', 
    '*Database Settings*', 
    '*Error Log.sql*', 
    '*find memory mini dumps*', 
    '*Fix Orphaned SID*', 
    '*Gather Log Events*', 
    '*Index Usage*', 
    '*Job Owners*', 
    '*Missing Indexes*', 
    '*Public Permissions*', 
    '*Sharepoint databases*', 
    'Space in files*', 
    '*Space in Log Files*', 
    '*Stats out of Date*', 
    '*TempDB*', 
    '*VLFs*');

get-childitem .\* -Recurse -include $stablestate | Compress-Archive -DestinationPath .\toolbox-stablestate.zip -Force 
