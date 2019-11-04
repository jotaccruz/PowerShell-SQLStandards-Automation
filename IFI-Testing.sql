declare @InstanceDefaultDataPath varchar(250)
declare @InstanceDefaultLogPath varchar(250)

SELECT @InstanceDefaultDataPath = CONCAT(CONVERT (VARCHAR(250),serverproperty('InstanceDefaultDataPath')),'ifitesting.mdf')
SELECT @InstanceDefaultLogPath = CONCAT(CONVERT (VARCHAR(250),serverproperty('InstanceDefaultLogPath')),'ifitesting.ldf')

declare @statement nvarchar(500) = concat ('CREATE DATABASE [ifitesting]
ON  PRIMARY 
( NAME = N''ifitesting'', FILENAME = ''',@InstanceDefaultDataPath,''', SIZE = 262144KB , FILEGROWTH = 1048576KB )
 LOG ON 
( NAME = N''ifitesting_log'', FILENAME = ''',@InstanceDefaultLogPath ,''', SIZE = 131072KB , FILEGROWTH = 262144KB )')

exec sp_executesql @statement

DECLARE @startdate datetime
DECLARE @enddate datetime
SELECT @startdate=getdate()
ALTER DATABASE [ifitesting] MODIFY FILE ( NAME = N'ifitesting', SIZE = 5242880KB )
SELECT @enddate=getdate()

IF DATEDIFF(SECOND,@startdate,@enddate)>50
SELECT 'IFI TURNED OFF, REVIEW IT WITHIN secpol.msc'
ELSE
SELECT 'IFI TURNED ON'
AS [IFI STATUS]

drop database [ifitesting]