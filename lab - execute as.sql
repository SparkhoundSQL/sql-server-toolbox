USE Master;
CREATE LOGIN [domain\username] FROM WINDOWS;
GO
GRANT CONTROL SERVER TO [domain\username] ;
DENY VIEW SERVER STATE TO [domain\username];
GO
EXECUTE AS LOGIN = 'domain\username';
SELECT * FROM sys.dm_exec_cached_plans; --Fails
GO
REVERT; --Reverts the EXECUTE AS
GO

--CONTROL SERVER is needed to access sys.dm_exec_cached_plans, a server-level DMV for reviewing plans in cache.

SELECT ORIGINAL_LOGIN(), CURRENT_USER; 
/*
ORIGINAL_LOGIN() = The name of the login with which you actually connected. This will not change even after you use EXECUTE AS USER or EXECUTE AS LOGIN. 
CURRENT_USER = The name of the user you have assumed.
*/