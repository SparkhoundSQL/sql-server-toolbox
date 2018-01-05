#There is a Windows Scheduled task on my machine that runs
#PowerShell -File "E:\OneDrive\toolbox\zip toolbox.ps1"

cd E:\OneDrive\toolbox
get-childitem .\* -Recurse | Where-Object {$_.FullName -notlike '*\.git*' }  | Where-Object {$_.FullName -notlike "*toolbox.zip" } | Compress-Archive -DestinationPath .\toolbox.zip -Force 
