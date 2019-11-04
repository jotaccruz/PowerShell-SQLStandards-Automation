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

	if @what=N'D'
		Begin
			SELECT 'aqui 1'
		--— Change default location for data files
			EXEC   xp_instance_regwrite
			   N'HKEY_LOCAL_MACHINE',
			   N'Software\Microsoft\MSSQLServer\MSSQLServer',
			   N'DefaultData',
			   REG_SZ,
			   @dir
		end
	else
		Begin
			if @what=N'L'
				Begin
				SELECT 'aqui 2'
				--— Change default location for log files
					EXEC   xp_instance_regwrite
					   N'HKEY_LOCAL_MACHINE',
					   N'Software\Microsoft\MSSQLServer\MSSQLServer',
					   N'DefaultLog',
					   REG_SZ,
					   @dir
				end
			else
				Begin
					SELECT 'aqui 3'
					--— Change default location for backups
					EXEC   xp_instance_regwrite
					   N'HKEY_LOCAL_MACHINE',
					   N'Software\Microsoft\MSSQLServer\MSSQLServer',
					   N'BackupDirectory',
					   REG_SZ,
					   @dir
				End
		End

-- =============================================
-- Example to execute the stored procedure
-- =============================================
--EXECUTE dbo.set_defaultpathdb 'D', 'D:\Data'
--GO
