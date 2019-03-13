--http://www.sqlservercentral.com/scripts/Mail+Profile/171566/
USE msdb 
GO 
 
Declare @TheResults varchar(max), 
        @vbCrLf CHAR(2) 
SET @vbCrLf = CHAR(13) + CHAR(10)         
SET @TheResults = ' 
use master 
go 
sp_configure ''show advanced options'',1 
go 
reconfigure with override 
go 
sp_configure ''Database Mail XPs'',1 
--go 
--sp_configure ''SQL Mail XPs'',0 
go 
reconfigure 
go 
' 
SELECT @TheResults = @TheResults  + ' 
-------------------------------------------------------------------------------------------------- 
-- BEGIN Mail Settings ' + p.name + ' 
-------------------------------------------------------------------------------------------------- 
IF NOT EXISTS(SELECT * FROM msdb.dbo.sysmail_profile WHERE  name = ''' + p.name + ''')  
  BEGIN 
    --CREATE Profile [' + p.name + '] 
    EXECUTE msdb.dbo.sysmail_add_profile_sp 
      @profile_name = ''' + p.name + ''', 
      @description  = ''' + ISNULL(p.description,'') + '''; 
  END --IF EXISTS profile 
  ' 
  + 
  ' 
  IF NOT EXISTS(SELECT * FROM msdb.dbo.sysmail_account WHERE  name = ''' + a.name + ''') 
  BEGIN 
    --CREATE Account [' + a.name + '] 
    EXECUTE msdb.dbo.sysmail_add_account_sp 
    @account_name            = ' + CASE WHEN a.name                IS NULL THEN ' NULL ' ELSE + '''' + a.name                  + '''' END + ', 
    @email_address           = ' + CASE WHEN a.email_address       IS NULL THEN ' NULL ' ELSE + '''' + a.email_address         + '''' END + ', 
    @display_name            = ' + CASE WHEN a.display_name        IS NULL THEN ' NULL ' ELSE + '''' + a.display_name          + '''' END + ', 
    @replyto_address         = ' + CASE WHEN a.replyto_address     IS NULL THEN ' NULL ' ELSE + '''' + a.replyto_address       + '''' END + ', 
    @description             = ' + CASE WHEN a.description         IS NULL THEN ' NULL ' ELSE + '''' + a.description           + '''' END + ', 
    @mailserver_name         = ' + CASE WHEN s.servername          IS NULL THEN ' NULL ' ELSE + '''' + s.servername            + '''' END + ', 
    @mailserver_type         = ' + CASE WHEN s.servertype          IS NULL THEN ' NULL ' ELSE + '''' + s.servertype            + '''' END + ', 
    @port                    = ' + CASE WHEN s.port                IS NULL THEN ' NULL ' ELSE + '''' + CONVERT(VARCHAR,s.port) + '''' END + ', 
    @username                = ' + CASE WHEN c.credential_identity IS NULL THEN ' NULL ' ELSE + '''' + c.credential_identity   + '''' END + ', 
    @password                = ' + CASE WHEN c.credential_identity IS NULL THEN ' NULL ' ELSE + '''NotTheRealPassword''' END + ',  
    @use_default_credentials = ' + CASE WHEN s.use_default_credentials = 1 THEN ' 1 ' ELSE ' 0 ' END + ', 
    @enable_ssl              = ' + CASE WHEN s.enable_ssl = 1              THEN ' 1 ' ELSE ' 0 ' END + '; 
  END --IF EXISTS  account 
  ' 
  + ' 
IF NOT EXISTS(SELECT * 
              FROM msdb.dbo.sysmail_profileaccount pa 
                INNER JOIN msdb.dbo.sysmail_profile p ON pa.profile_id = p.profile_id 
                INNER JOIN msdb.dbo.sysmail_account a ON pa.account_id = a.account_id   
              WHERE p.name = ''' + p.name + ''' 
                AND a.name = ''' + a.name + ''')  
  BEGIN 
    -- Associate Account [' + a.name + '] to Profile [' + p.name + '] 
    EXECUTE msdb.dbo.sysmail_add_profileaccount_sp 
      @profile_name = ''' + p.name + ''', 
      @account_name = ''' + a.name + ''', 
      @sequence_number = ' + CONVERT(VARCHAR,pa.sequence_number) + ' ; 
  END  
--IF EXISTS associate accounts to profiles 
--------------------------------------------------------------------------------------------------- 
-- Drop Settings For ' + p.name + ' 
-------------------------------------------------------------------------------------------------- 
/* 
IF EXISTS(SELECT * 
            FROM msdb.dbo.sysmail_profileaccount pa 
              INNER JOIN msdb.dbo.sysmail_profile p ON pa.profile_id = p.profile_id 
              INNER JOIN msdb.dbo.sysmail_account a ON pa.account_id = a.account_id   
            WHERE p.name = ''' + p.name + ''' 
              AND a.name = ''' + a.name + ''') 
  BEGIN 
    EXECUTE msdb.dbo.sysmail_delete_profileaccount_sp @profile_name = ''' + p.name + ''',@account_name = ''' + a.name + ''' 
  END  
IF EXISTS(SELECT * FROM msdb.dbo.sysmail_account WHERE  name = ''' + a.name + ''') 
  BEGIN 
    EXECUTE msdb.dbo.sysmail_delete_account_sp @account_name = ''' + a.name + ''' 
  END 
IF EXISTS(SELECT * FROM msdb.dbo.sysmail_profile WHERE  name = ''' + p.name + ''')  
  BEGIN 
    EXECUTE msdb.dbo.sysmail_delete_profile_sp @profile_name = ''' + p.name + ''' 
  END 
*/ 
  '  
FROM msdb.dbo.sysmail_profile p 
INNER JOIN msdb.dbo.sysmail_profileaccount pa ON  p.profile_id = pa.profile_id 
INNER JOIN msdb.dbo.sysmail_account a         ON pa.account_id = a.account_id  
LEFT OUTER JOIN msdb.dbo.sysmail_server s     ON a.account_id = s.account_id 
LEFT OUTER JOIN sys.credentials c    ON s.credential_id = c.credential_id 
 
   ;WITH E01(N) AS (SELECT 1 UNION ALL SELECT 1 UNION ALL   
                    SELECT 1 UNION ALL SELECT 1 UNION ALL   
                    SELECT 1 UNION ALL SELECT 1 UNION ALL   
                    SELECT 1 UNION ALL SELECT 1 UNION ALL   
                    SELECT 1 UNION ALL SELECT 1), --         10 or 10E01 rows   
         E02(N) AS (SELECT 1 FROM E01 a, E01 b),  --        100 or 10E02 rows   
         E04(N) AS (SELECT 1 FROM E02 a, E02 b),  --     10,000 or 10E04 rows   
         E08(N) AS (SELECT 1 FROM E04 a, E04 b),  --100,000,000 or 10E08 rows   
         --E16(N) AS (SELECT 1 FROM E08 a, E08 b),  --10E16 or more rows than you'll EVER need,   
         Tally(N) AS (SELECT ROW_NUMBER() OVER (ORDER BY N) FROM E08),   
       ItemSplit(   
                 ItemOrder,   
                 Item   
                ) as (   
                      SELECT N,   
                        SUBSTRING(@vbCrLf + @TheResults + @vbCrLf,N + DATALENGTH(@vbCrLf),CHARINDEX(@vbCrLf,@vbCrLf + @TheResults + @vbCrLf,N + DATALENGTH(@vbCrLf)) - N - DATALENGTH(@vbCrLf))   
                      FROM Tally   
                      WHERE N < DATALENGTH(@vbCrLf + @TheResults)   
                      --WHERE N < DATALENGTH(@vbCrLf + @INPUT) -- REMOVED added @vbCrLf   
                        AND SUBSTRING(@vbCrLf + @TheResults + @vbCrLf,N,DATALENGTH(@vbCrLf)) = @vbCrLf --Notice how we find the delimiter   
                     )   
  select   
    row_number() over (order by ItemOrder) as ItemID,   
    Item   
  from ItemSplit 