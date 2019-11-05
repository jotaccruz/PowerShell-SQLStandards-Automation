USE [msdb]
GO
EXEC msdb.dbo.sp_add_operator @name=N'DBA', 
		@enabled=1, 
		@pager_days=0, 
		@email_address=N'dba@telusinternational.com'
GO
