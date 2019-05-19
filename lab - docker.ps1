#https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-server
#or
#https://docs.microsoft.com/en-us/virtualization/windowscontainers/quick-start/quick-start-windows-10

Install-Module -Name DockerMsftProvider -Repository PSGallery -Force
Install-Package -Name docker -ProviderName DockerMsftProvider

##Update if needed
#Update-Module -Name DockerMsftProvider -Force

##If on Win10, you need to install RSA Tools for Win 10 first  https://www.microsoft.com/en-au/download/confirmation.aspx?id=45520, then: 
#Import-Module ServerManager -Force

Start-Service Docker
docker info

#Download and run a small docker image for fun
docker run -it docker/surprise

#If you ever get an error regarding platform, you have to switch the daemon from Linux (default) to Windows or vice versa.
& $Env:ProgramFiles\Docker\Docker\DockerCli.exe -SwitchDaemon .
Restart-Service Docker

#Download and run SQL Dev for Windows container: https://hub.docker.com/r/microsoft/mssql-server-windows-developer
docker pull microsoft/mssql-server-windows-developer:latest #Latest Windows. Make sure Daemon is for Windows.
#Latest Linux images https://hub.docker.com/_/microsoft-mssql-server
#docker pull mcr.microsoft.com/mssql/server:2019-CTP2.5-ubuntu #Latest Linux. Make sure Daemon is for Windows.

#Show the images currently present
docker images

#sa password must be strong or it won't work!
docker run -d -p 1433:1433 --name w20190515 -e sa_password=abc123@ABC -e ACCEPT_EULA=Y microsoft/mssql-server-windows-developer:latest
#Linux docker run -d -p 1433:1433 --name w20190515 -e sa_password=abc123@ABC -e MSSQL_PID=Developer -e ACCEPT_EULA=Y mcr.microsoft.com/mssql/server:2019-CTP2.5-ubuntu
#Returns a containerid, use the first 12 characters for container id's here on out.

#containers
docker ps -a

##connect to SQL Server in Docker: https://cloudblogs.microsoft.com/sqlserver/2016/10/13/sql-server-2016-express-edition-in-windows-containers/

#To connect with SQLCMD inside the docker container in a Docker Powershell session:
docker exec -it 7abc87e6f900 sqlcmd -S. -Usa

#To connect with SSMS or from outside the container, inspect the container and get the IP address so that you can reach it. https://docs.docker.com/engine/reference/commandline/inspect/
docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' df32fed650f1

#To connect with SSMS, use the IP. We installed using 1433, so no port needed. You must check "trust server certificate".
#To connect with PowerShell
Invoke-Sqlcmd -Query 'select * from sys.dm_os_sys_info' -ServerInstance 172.17.0.2 -Username sa -Password abc123@ABC 
#Linux docker exec -it f1bb1d621033 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P abc123@ABC

#remove container
docker stop f1bb1d621033
docker rm f1bb1d621033

#cleanup of all stopped containers 
docker container prune
#cleanup of all stopped containers and more
docker system prune

#Start an exited container.
docker start 7abc87e6f900

#Review SQL Server logs
docker logs f1bb1d621033
