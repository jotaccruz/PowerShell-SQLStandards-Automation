 --SETTING SOME IMPORTANT ASPECTS
EXEC sp_configure 'show advanced options',1
GO
RECONFIGURE
GO
EXEC sp_configure 'remote admin connections', 1;
GO
EXEC sp_configure 'backup checksum default', 1;
GO
EXEC sp_configure 'show advanced options',0
GO
RECONFIGURE WITH OVERRIDE;
GO
SELECT * FROM sys.configurations WHERE name LIKE 'remote admin connections';
SELECT * FROM sys.configurations WHERE name LIKE 'backup checksum default';