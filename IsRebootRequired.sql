Create Table #tmp_registry
(
RegKey	VarChar(200)  Null,
Value	NVarChar(Max) Null
);
Insert Into #tmp_registry
EXEC master..xp_regread 
@rootkey	= 'HKEY_LOCAL_MACHINE',
@key	= 'SYSTEM\CurrentControlSet\Control\Session Manager',
@value_name	= 'PendingFileRenameOperations',
@value	= '';
Select Value From #tmp_registry;
Drop Table #tmp_registry;