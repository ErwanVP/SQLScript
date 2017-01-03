
/*Maintenance DBcc checkdb for all databases*/

USE msdb
GO

IF OBJECT_ID ('dbo.user_maintenance_DBCC_CHECKDB_ALL') IS NOT NULL 
	DROP PROCEDURE dbo.user_maintenance_DBCC_CHECKDB_ALL
GO

CREATE PROCEDURE dbo.user_maintenance_DBCC_CHECKDB_ALL (@log bit = 0 )
AS
BEGIN
	DECLARE @DBName sysname , @msg nvarchar(1000), @Subject nvarchar(1000), @DBlist nvarchar(1000) = N''
			,@DBCC_CHECK Datetime = dateadd(dd,-1,GETDATE()); /*Date of the DBCC check */

	CREATE TABLE #tempFinal
	(
		DatabaseName varchar(255),
		Field VARCHAR(255),
		Value datetime
	);
	
	CREATE TABLE #temp
	(
		ParentObject VARCHAR(255),
		Object VARCHAR(255),
		Field VARCHAR(255),
		Value VARCHAR(255)
	);

	/*Disable parallelism */
	DBCC TRACEON (2528);

	DECLARE CurDB CURSOR LOCAL FAST_FORWARD FOR 
	SELECT name FROM sys.databases
	WHERE state = 0 
	AND database_id <> 2; /*Tempdb*/

	OPEN CurDB 
	FETCH NEXT FROM CurDB INTO @DBName;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @log = 1 
		BEGIN
			SET @msg = 'DBCC CHECKDB on '+ @DBName;
			RAISERROR(@msg,0,0) WITH NOWAIT;
		END;

		DBCC CHECKDB(@DBName) WITH ALL_ERRORMSGS, NO_INFOMSGS;
		
		IF @log = 1 
		BEGIN
			SET @msg = 'DBCC CHECKDB on '+ @DBName + ' is finish';
			RAISERROR(@msg,0,0) WITH NOWAIT;
		END;
	
		FETCH NEXT FROM CurDB INTO @DBName;
	END;

	CLOSE CurDB;
	DEALLOCATE CurDB;

	/*Enable parallelism */
	DBCC TRACEOFF (2528);

	DECLARE CurDB CURSOR LOCAL FAST_FORWARD FOR 
	SELECT name FROM sys.databases
	WHERE state = 0 
	AND database_id <> 2; /*Tempdb*/

	OPEN CurDB 
	FETCH NEXT FROM CurDB INTO @DBName;

	/* Check the last good DBCC*/
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @log = 1 
		BEGIN
			SET @msg = 'DBCC DBINFO on '+ @DBName;
			RAISERROR(@msg,0,0) WITH NOWAIT;
		END;
		
		INSERT INTO #temp EXEC('DBCC DBINFO ( '+@DBName+') WITH TABLERESULTS');

		INSERT INTO #tempFinal (Field, Value, DatabaseName)
		SELECT TOP 1 Field, Value, @DBName FROM #temp
		WHERE Field = 'dbi_dbccLastKnownGood';

		TRUNCATE TABLE #temp;

		FETCH NEXT FROM CurDB INTO @DBName;
	END;

	CLOSE CurDB;
	DEALLOCATE CurDB;

	IF EXISTS (SELECT DatabaseName FROM #tempFinal WHERE Value < @DBCC_CHECK)
	BEGIN
		SELECT @DBlist = @DBlist + DatabaseName + ',' FROM #tempFinal WHERE Value < @DBCC_CHECK;
		SET @Subject = @@SERVERNAME + ': DBCC CHECKDB Last run unseccessfull';
		SET @msg = N'Hello Team, <br><br> A unseccessfull DBCC checkdb has been detected on the following database: '+@DBlist +'<br>';
		SET @msg = @msg + N'You will find more information in error log of this server.';
		SET @msg = @msg + N'It is not critical, please check during the ofice hours execpt during the week end<br>';
		SET @msg = @msg + N'Thanks You <br><br>the DBA Team';
		EXEC [msdb].[dbo].[user_Alert_Notify]
			@Subject = @Subject, @Body = @msg, @bySMS = 0, @ToList = 1, @IsHTML = 1;
	END;
END;