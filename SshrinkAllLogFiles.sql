
EXEC sp_msforeachdb ' Declare @logname varchar(500) = '''';

IF ''?'' not in (''tempdb'',''master'',''msdb'',''model'',''Reportserver'',''ReportserverTempDB'') 
begin 
	set @logname = (Select name From [?].Sys.database_files where  type=1) 

	EXEC(''Use [?];
		DBCC SHRINKFILE (['' + @logname + ''] ,100)'')  
end 
' 