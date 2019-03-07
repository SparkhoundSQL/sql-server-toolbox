<#

    - MIGRATION OF LOGINS UTILIZING DBATOOLS.IO
    - https://docs.dbatools.io/#Copy-DbaLogin
    - This is a PS script to migrate logins including:
        1. SIDs
        2. Passwords
        3. Defaultdb
        4. Server roles & securables
        5. Database permissions & securables
        6. Login attributes
    - Permissions to run the script:
        - Requires PowerShell Remoting enabled on host
        - Requires being a sysadmin on both Source and Destination SQL Servers
    
    NOTE: Preferably run after databases are migrated; No backwards compatability; DO NOT run the whole script at once, follow the steps.

 #>


#1. Installs DBAtools.io gallery
Install-Modul dbatools


#2. Change SQLSourceInstance to Source SQL Server name that logins will be migrated from and SQLDestinationInstance to Destination SQL Server name that logins will be migrated to.
$Source = SQLSourceInstance
$Destination = SQLDestinationInstance


#3. Copies Source logins to Destination.
<# 
See the syntax below if applicable.
    1. -Force = If login found on Destination that matches Source, drops and recreate. If active connections are found (also being an owner of a job), copy of the login will fail.
    2. -KillActiveConnection = If any active connections are found for the login, it will be killed.
    3. -SyncOnly = Syncs SQL Server login permissions, roles, etc.
    4. -ExcludeSystemLogins = excludes system logins

    An Example with the syntax is:
    Copy-DbaLogin -Source SQLA -Destination SQLB -ExcludeSystemLogins -Force -KillActiveConnection
#>
Copy-DbaLogin -Source $Source -Destination $Target -ExcludeSystemLogins