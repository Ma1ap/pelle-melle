
-- REPLACE [DATABASE_NAME]
USE [DATABASE_NAME]
GO

DECLARE @SQL NVARCHAR(4000)

SET NOCOUNT ON;
 
DECLARE @tableName    VARCHAR(256) 
    , @schemaName   VARCHAR(100) 
    , @sqlStatement NVARCHAR(1000) 
    , @tableCount   INT
    , @statusMsg    VARCHAR(1000) ;
 
DECLARE @tables TABLE  
(
      database_name     sysname COLLATE database_default
    , schemaName        sysname COLLATE database_default NULL 
    , tableName         sysname COLLATE database_default NULL
    , processed         bit
);
 
 
DECLARE @compressionResults TABLE  
 
    (
          objectName                    varchar(100) COLLATE database_default
        , schemaName                    varchar(50) COLLATE database_default
        , index_id                      int
        , partition_number              int
        , size_current_compression      bigint
        , size_requested_compression    bigint
        , sample_current_compression    bigint
        , sample_requested_compression  bigint
    );
 
 
INSERT INTO @tables
SELECT DB_NAME()
    , SCHEMA_NAME([schema_id])
    , name
    , 0 -- unprocessed
FROM sys.tables;
 
SELECT @tableCount = COUNT(*) FROM @tables;
 
WHILE EXISTS(SELECT * FROM @tables WHERE processed = 0)
BEGIN
 
    SELECT TOP 1 @tableName = tableName
        , @schemaName = schemaName
    FROM @tables WHERE processed = 0;
 
    SELECT @statusMsg = 'Working on ' + CAST(((@tableCount - COUNT(*)) + 1) AS VARCHAR(10)) 
        + ' of ' + CAST(@tableCount AS VARCHAR(10))
    FROM @tables
    WHERE processed = 0;
 
    RAISERROR(@statusMsg, 0, 42) WITH NOWAIT;
 
    SET @sqlStatement = 'EXECUTE sp_estimate_data_compression_savings ''' 
                        + @schemaName + ''', ''' + @tableName + ''', NULL, NULL, ''PAGE'';' -- ROW, PAGE, or NONE
  
    INSERT INTO @compressionResults
    EXECUTE sp_executesql @sqlStatement;
 
    UPDATE @tables
    SET processed = 1
    WHERE tableName = @tableName
        AND schemaName = @schemaName;
 
END;

SELECT * FROM @compressionResults
ORDER BY CAST(size_current_compression AS BIGINT) asc

DECLARE curIndexes CURSOR FOR

            SELECT      CASE WHEN i.name COLLATE database_default IS NULL THEN 'ALTER TABLE ['
                        + c.SchemaName COLLATE database_default+ '].[' + c.ObjectName COLLATE database_default
                        + '] REBUILD WITH (DATA_COMPRESSION = PAGE)'
                        + ' --' + CAST(size_current_compression AS VARCHAR(20))
                        ELSE 'ALTER INDEX [' + i.Name COLLATE database_default--IndexName
                        + '] ON '
                        + c.SchemaName COLLATE database_default+ '.' + c.ObjectName COLLATE database_default--TableName
                        + ' REBUILD PARTITION = ALL WITH (FILLFACTOR = 100, DATA_COMPRESSION = PAGE)'
                        + ' --' + CAST(size_current_compression AS VARCHAR(20)) END
FROM @compressionResults c 
LEFT JOIN sys.indexes i ON i.index_id = c.index_id
LEFT JOIN sys.dm_db_partition_stats  AS s 
ON s.[object_id] = i.[object_id] AND s.index_id = i.index_id
WHERE OBJECT_NAME(s.object_id) = c.objectName
AND OBJECT_SCHEMA_NAME(s.object_id) = c.schemaName
AND size_current_compression / (size_requested_compression+0.1) > 2  -- Limite aux tables qui r�duiront de moiti� ou plus
and size_current_compression > 1024 -- Limite aux tables de plus de 1 Mb
ORDER BY size_current_compression asc

OPEN    curIndexes
 
FETCH   NEXT
FROM    curIndexes
INTO    @SQL
DECLARE @cnt int
SET @cnt = 0 
WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @SQL IS NOT NULL BEGIN
			--PRINT @SQL
            RAISERROR(@SQL, 10, 1) WITH NOWAIT
			EXEC sp_executesql @SQL
            
		SET @cnt = @cnt + 1
		IF @cnt % 50 = 0 BEGIN
			PRINT 'Print ''' + CAST(@cnt AS varchar(10)) +' Done'''
			PRINT 'GO'
		END
		END
        FETCH   NEXT
        FROM    curIndexes
        INTO    @SQL
    END
PRINT 'Print ''' + CAST(@cnt AS varchar(10)) +' Done'''
 
CLOSE       curIndexes
DEALLOCATE  curIndexes

GO

PRINT ' '
PRINT 'You need to Shrink your database'
--  EXEC sp_MSForEachDB 'DBCC SHRINKDATABASE (''?'' , 0)' '
PRINT ' '
