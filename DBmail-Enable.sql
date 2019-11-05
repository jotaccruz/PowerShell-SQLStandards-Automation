--==========================================================
-- Enable Database Mail
--==========================================================

SELECT * FROM  sys.configurations WHERE name = 'Database Mail XPs'
GO
/* Check for pending configurations. */
/* You may not want to proceed if anything odd is outstanding! */
SELECT * 
FROM sys.configurations where value <> value_in_use;
GO
EXEC sp_configure 'show advanced options', '1';
RECONFIGURE
GO
EXEC sp_configure 'Database Mail XPs', 1;
RECONFIGURE
GO
EXEC sp_configure 'show advanced options', '0';
RECONFIGURE
GO