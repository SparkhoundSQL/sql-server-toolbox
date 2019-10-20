##See also lab - docker.ps1

#Show the images currently present
docker ps -a

docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 0d17d7d4f704
docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 6071cb88ef16



Write-Host "Enable the AG feature"
docker ps -a
docker exec -it 0d17d7d4f704 powershell Enable-SQLAlwaysOn -InputObject 0d17d7d4f704 -Force -NoServiceRestart
docker exec -it 6071cb88ef16 powershell Enable-SQLAlwaysOn -InputObject 6071cb88ef16 -Force -NoServiceRestart
docker stop 0d17d7d4f704 6071cb88ef16
docker start 0d17d7d4f704 6071cb88ef16

Write-Host "Starting all container services"
docker start 0d17d7d4f704 6071cb88ef16
docker exec -it 0d17d7d4f704 sqlcmd -Q "SET NOCOUNT ON; EXEC sp_configure 'show advanced options', 1; RECONFIGURE; exec sp_configure N'Agent XPs' , 1; RECONFIGURE WITH OVERRIDE; exec xp_servicecontrol N'Start', N'SqlServerAGENT';"
docker exec -it 6071cb88ef16 sqlcmd -Q "SET NOCOUNT ON; EXEC sp_configure 'show advanced options', 1; RECONFIGURE; exec sp_configure N'Agent XPs' , 1; RECONFIGURE WITH OVERRIDE; exec xp_servicecontrol N'Start', N'SqlServerAGENT';"
docker exec -it 0d17d7d4f704 sqlcmd -Q "SET NOCOUNT ON; USE MASTER; create master key encryption by password=N'myP@$$word'; create certificate [mysql10_cert] with subject=N'mysql10_cert'; create login [mysql11_login] with password = 'myP@$$w0rd'; create user [mysql11_user] for login [mysql11_login]; backup certificate [mysql10_cert] to file=N'C:\sqldata\mysql10_cert.cer';"
docker exec -it 6071cb88ef16 sqlcmd -Q "SET NOCOUNT ON; USE MASTER; create master key encryption by password=N'myP@$$word'; create certificate [mysql11_cert] with subject=N'mysql11_cert'; create login [mysql10_login] with password=N'myP@$$w0rd'; create user [mysql10_user] for login [mysql10_login]; backup certificate [mysql11_cert] to file=N'C:\sqldata\mysql11_cert.cer';"
docker stop 0d17d7d4f704 6071cb88ef16
Copy-Item "C:\gitrepo\mssql-docker\windows\examples\Read-Scale-AG\msql1\cvols\mysql10_cert.cer" -Destination "C:\gitrepo\mssql-docker\windows\examples\Read-Scale-AG\msql2\cvols\mysql10_cert.cer"
Copy-Item "C:\gitrepo\mssql-docker\windows\examples\Read-Scale-AG\msql2\cvols\mysql11_cert.cer" -Destination "C:\gitrepo\mssql-docker\windows\examples\Read-Scale-AG\msql1\cvols\mysql11_cert.cer"
docker start 0d17d7d4f704 6071cb88ef16

Write-Host "Creating the certificates"
docker exec -it 0d17d7d4f704 sqlcmd -Q "create login local1 with password = 'abc123@ABC'; alter server role sysadmin add member local1;"
docker exec -it 6071cb88ef16 sqlcmd -Q "create login local1 with password = 'abc123@ABC'; alter server role sysadmin add member local1;"

docker exec -it 0d17d7d4f704 sqlcmd -Q "SET NOCOUNT ON; USE MASTER; create certificate [mysql11_cert] authorization [local1] from file=N'C:\\sqldata\\mysql11_cert.cer';"
docker exec -it 6071cb88ef16 sqlcmd -Q "SET NOCOUNT ON; USE MASTER; create certificate [mysql10_cert] authorization [local1] from file=N'C:\\sqldata\\mysql10_cert.cer';"

Write-Host "Creating the endpoints"
docker exec -it 0d17d7d4f704 sqlcmd -Q "SET NOCOUNT ON; USE MASTER; CREATE ENDPOINT WGAG_Endpoint STATE=STARTED AS TCP (LISTENER_PORT=5022, LISTENER_IP=ALL) FOR DATABASE_MIRRORING (AUTHENTICATION=CERTIFICATE [mysql10_cert], ROLE=ALL); GRANT CONNECT ON ENDPOINT::WGAG_Endpoint TO [mysql11_login]; IF (SELECT state FROM sys.endpoints WHERE name = N'WGAG_Endpoint') <> 0 BEGIN ALTER ENDPOINT [WGAG_Endpoint] STATE=STARTED; END; IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AlwaysOn_health') BEGIN ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON); END; IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE name='AlwaysOn_health') BEGIN ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=START; END;"
docker exec -it 6071cb88ef16 sqlcmd -Q "SET NOCOUNT ON; USE MASTER; CREATE ENDPOINT WGAG_Endpoint STATE=STARTED AS TCP (LISTENER_PORT=5022, LISTENER_IP=ALL) FOR DATABASE_MIRRORING (AUTHENTICATION=CERTIFICATE [mysql11_cert], ROLE=ALL); GRANT CONNECT ON ENDPOINT::WGAG_Endpoint TO [mysql10_login]; IF (SELECT state FROM sys.endpoints WHERE name=N'WGAG_Endpoint') <> 0  BEGIN ALTER ENDPOINT [WGAG_Endpoint] STATE = STARTED; END; IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AlwaysOn_health') BEGIN ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON); END; IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE name='AlwaysOn_health') BEGIN ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=START; END;"
