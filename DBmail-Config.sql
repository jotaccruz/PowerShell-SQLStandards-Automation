--================================================================
-- DATABASE MAIL CONFIGURATION
--================================================================
--==========================================================
-- Create a Database Mail account
--==========================================================
EXECUTE msdb.dbo.sysmail_add_account_sp
    @account_name = 'DBA',
    @description = 'Email account for sending alerts and errors',
    @email_address = 'no-reply@telusinternational.com',
    @replyto_address = 'no-reply@telusinternational.com',
    @display_name = 'Database Notification',
    @mailserver_name = '172.17.64.124',
	@port = 25;

--==========================================================
-- Create a Database Mail Profile
--==========================================================
DECLARE @profile_id INT, @profile_description sysname;
SELECT @profile_id = COALESCE(MAX(profile_id),1) FROM msdb.dbo.sysmail_profile
SELECT @profile_description = 'Database Mail Profile for ' + @@servername 


EXECUTE msdb.dbo.sysmail_add_profile_sp
    @profile_name = 'dba_profile',
    @description = @profile_description;

-- Add the account to the profile
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'dba_profile',
    @account_name = 'DBA',
    @sequence_number = @profile_id;

-- Grant access to the profile to the DBMailUsers role
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = 'dba_profile',
    @principal_id = 0,
    @is_default = 1 ;


--==========================================================
-- Enable Database Mail
--==========================================================
USE master;
GO

sp_CONFIGURE 'show advanced', 1
GO
RECONFIGURE
GO
sp_CONFIGURE 'Database Mail XPs', 1
GO
RECONFIGURE
GO 


--EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'DatabaseMailProfile', N'REG_SZ', N''
--EXEC master.dbo.xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\SQLServerAgent', N'UseDatabaseMail', N'REG_DWORD', 1
--GO

EXEC msdb.dbo.sp_set_sqlagent_properties @email_save_in_sent_folder = 0
GO


--==========================================================
-- Review Outcomes
--==========================================================
--SELECT * FROM msdb.dbo.sysmail_profile;
--SELECT * FROM msdb.dbo.sysmail_account;
--GO


--==========================================================
-- Test Database Mail
--==========================================================
--DECLARE @sub VARCHAR(100)
--DECLARE @body_text NVARCHAR(MAX)
--SELECT @sub = 'Test from New SQL install on ' + @@servername
--SELECT @body_text = N'This is a test of Database Mail.' + CHAR(13) + CHAR(13) + 'SQL Server Version Info: ' + CAST(@@version AS VARCHAR(500))

--EXEC msdb.dbo.[sp_send_dbmail] 
--    @profile_name = 'dba_profile'
--  , @recipients = 'juan.cruz2@telusinternational.com'
--  , @subject = @sub
--  , @body = @body_text

--================================================================
-- SQL Agent Properties Configuration
--================================================================
EXEC msdb.dbo.sp_set_sqlagent_properties 
	@email_profile = 'dba_profile'
	, @use_databasemail=1
GO
