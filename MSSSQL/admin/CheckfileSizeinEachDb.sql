	SET NOCOUNT ON
	DECLARE @DBName NVARCHAR(100) = NULL, --Provide DBName if looking for a specific database or leave to get all databases details
	        @Drive NVARCHAR(2) = NULL --Mention drive letter if you are concerned of only a single drive where you are running out of space
 
	DECLARE @cmd NVARCHAR(4000)
	IF (SELECT OBJECT_ID('tempdb.dbo.#DBName')) IS NOT NULL
	DROP TABLE #DBName	CREATE TABLE #DBName (Name NVARCHAR(100))
 
	IF @DBName IS NOT NULL
	INSERT INTO #DBName SELECT @DBName --WHERE state_desc = 'ONLINE'
	ELSE
	INSERT INTO #DBName SELECT Name FROM sys.databases
	 
	IF (SELECT OBJECT_ID('tempdb.dbo.##FileStats')) IS NOT NULL
	DROP TABLE ##FileStats
	CREATE TABLE ##FileStats (ServerName NVARCHAR(100), DBName NVARCHAR(100), FileType NVARCHAR(100),
	FileName NVARCHAR(100), CurrentSizeMB FLOAT, FreeSpaceMB FLOAT, PercentMBFree FLOAT, FileLocation NVARCHAR(1000))
	 
	WHILE (SELECT TOP 1 * FROM #DBName) IS NOT NULL
	BEGIN
 
	    SELECT @DBName = MIN(Name) FROM #DBName
 
	    SET @cmd = 'USE [' + @DBName + ']
	    INSERT INTO ##FileStats
	    SELECT @@ServerName AS ServerName, DB_NAME() AS DbName,
	    CASE WHEN type = 0 THEN ''DATA'' ELSE ''LOG'' END AS FileType,
	    name AS FileName,
	    size/128.0 AS CurrentSizeMB, 
	    size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0 AS FreeSpaceMB,
	    100*(1 - ((CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0)/(size/128.0))) AS PercentMBFree,
	    physical_name AS FileLocation
	    FROM sys.database_files'
	     
	    IF @Drive IS NOT NULL
	    SET @cmd = @cmd + ' WHERE physical_name LIKE ''' + @Drive + ':\%'''
	 
	    EXEC sp_executesql @cmd
	     
	    DELETE FROM #DBName WHERE Name = @DBName
	     
	END
	 
	SELECT * FROM ##FileStats
	DROP TABLE #DBName
	DROP TABLE ##FileStats