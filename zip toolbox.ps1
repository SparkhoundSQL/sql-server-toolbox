cd E:\OneDrive\toolbox
Compress-Archive -Path * -DestinationPath toolbox.zip -Force

#There is a Windows Scheduled task on my machine that runs
#PowerShell -File "E:\OneDrive\toolbox\zip toolbox.ps1"