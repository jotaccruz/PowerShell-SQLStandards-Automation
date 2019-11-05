use master
CREATE DATABASE [ifitesting]

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