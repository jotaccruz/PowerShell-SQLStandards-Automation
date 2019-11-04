IF  NOT EXISTS (
	SELECT name 
		FROM sys.databases 
		WHERE name = N'DBAdmin'
)
BEGIN
	CREATE DATABASE DBAdmin;
	ALTER DATABASE DBAdmin SET RECOVERY SIMPLE;
END
GO
use DBAdmin;
exec sp_changedbowner sa