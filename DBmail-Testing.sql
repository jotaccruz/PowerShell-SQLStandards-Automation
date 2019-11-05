--==========================================================
-- Test Database Mail
--==========================================================
DECLARE @sub VARCHAR(100)
DECLARE @body_text NVARCHAR(MAX)
SELECT @sub = 'Test from New SQL install on ' + @@servername
SELECT @body_text = N'This is a test of Database Mail.' + CHAR(13) + CHAR(13) + 'SQL Server Version Info: ' + CAST(@@version AS VARCHAR(500))

EXEC msdb.dbo.[sp_send_dbmail] 
    @profile_name = '<profile_name,varchar,dba_profile>'
  , @recipients = '<MailTest,varchar,juan.cruz2@telusinternational.com>'
  , @subject = @sub
  , @body = @body_text
