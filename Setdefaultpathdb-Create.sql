Use DbAdmin;
-- =============================================
-- Create basic stored procedure template
-- =============================================

-- Drop stored procedure if it already exists
--Parameter @what
--D - Data
--L - Log
--B - Backup
IF EXISTS (
  SELECT * 
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_SCHEMA = N'dbo'
     AND SPECIFIC_NAME = N'set_defaultpathdb' 
)
   DROP PROCEDURE dbo.set_defaultpathdb
GO

CREATE PROCEDURE dbo.set_defaultpathdb
	@what nvarchar(1) = 'D', 
	@dir nvarchar(500) = 'D:\Data'
AS
	SELECT @what, @dir

	if @what='D'
		Begin
		--— Change default location for data files
			EXEC   xp_instance_regwrite
			   N'HKEY_LOCAL_MACHINE',
			   N'Software\Microsoft\MSSQLServer\MSSQLServer',
			   N'DefaultData',
			   REG_SZ,
			   N'C:\MSSQL\Data'
		end
	else
		Begin
			if @what='L'
				Begin
				--— Change default location for log files
					EXEC   xp_instance_regwrite
					   N'HKEY_LOCAL_MACHINE',
					   N'Software\Microsoft\MSSQLServer\MSSQLServer',
					   N'DefaultLog',
					   REG_SZ,
					   N'C:\MSSQL\Logs'
				end
			else
				Begin
					--— Change default location for backups
					EXEC   xp_instance_regwrite
					   N'HKEY_LOCAL_MACHINE',
					   N'Software\Microsoft\MSSQLServer\MSSQLServer',
					   N'BackupDirectory',
					   REG_SZ,
					   N'C:\MSSQL\Backups'
				End
		End

-- =============================================
-- Example to execute the stored procedure
-- =============================================
--EXECUTE dbo.set_defaultpathdb 'D', 'D:\Data'
--GO
