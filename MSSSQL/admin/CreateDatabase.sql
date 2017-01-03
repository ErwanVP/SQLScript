
DECLARE @DatabaseName nvarchar(50) = 'TestDB'
DECLARE @FileFolder nvarchar(100) = 'c:\test\ '
DECLARE @SQL nvarchar(max) 


SET @SQL = N'CREATE DATABASE '+@DatabaseName+'
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N''PRIMARY'', FILENAME = N'''+@FileFolder+@DatabaseName+'\'+@DatabaseName+'_primary.mdf'', SIZE = 8MB , MAXSIZE = UNLIMITED, FILEGROWTH = 4MB ), 
FILEGROUP [Data]  DEFAULT 
( NAME = N''Data01'', FILENAME = N'''+@FileFolder+@DatabaseName+'\'+@DatabaseName+'_Data01.mdf'' , SIZE = 64MB , MAXSIZE = UNLIMITED, FILEGROWTH = 8MB ), 
( NAME = N''Data02'', FILENAME = N'''+@FileFolder+@DatabaseName+'\'+@DatabaseName+'_Data02.ndf'' , SIZE = 64MB , MAXSIZE = UNLIMITED, FILEGROWTH = 8MB ), 
( NAME = N''Data03'', FILENAME = N'''+@FileFolder+@DatabaseName+'\'+@DatabaseName+'_Data03.ndf'' , SIZE = 64MB , MAXSIZE = UNLIMITED, FILEGROWTH = 8MB ), 
( NAME = N''Data04'', FILENAME = N'''+@FileFolder+@DatabaseName+'\'+@DatabaseName+'_Data04.ndf'' , SIZE = 64MB , MAXSIZE = UNLIMITED, FILEGROWTH = 8MB ),
 FILEGROUP [INDEX]
( NAME = N''Index01'', FILENAME = N'''+@FileFolder+@DatabaseName+'\'+@DatabaseName+'_Index01.mdf'' , SIZE = 16MB , MAXSIZE = UNLIMITED, FILEGROWTH = 4MB ), 
( NAME = N''Index02'', FILENAME = N'''+@FileFolder+@DatabaseName+'\'+@DatabaseName+'_Index02.ndf'' , SIZE = 16MB , MAXSIZE = UNLIMITED, FILEGROWTH = 4MB ), 
( NAME = N''Index03'', FILENAME = N'''+@FileFolder+@DatabaseName+'\'+@DatabaseName+'_Index03.ndf'' , SIZE = 16MB , MAXSIZE = UNLIMITED, FILEGROWTH = 4MB ), 
( NAME = N''Index04'', FILENAME = N'''+@FileFolder+@DatabaseName+'\'+@DatabaseName+'_Index04.ndf'' , SIZE = 16MB , MAXSIZE = UNLIMITED, FILEGROWTH = 4MB )
 LOG ON 
( NAME = N''TLogs'', FILENAME = N'''+@FileFolder+@DatabaseName+'\'+@DatabaseName+'_TLogs.ldf'' , SIZE = 64MB , MAXSIZE = UNLIMITED , FILEGROWTH = 16MB )'

SELECT @SQL


/* for in memory table */ 
add this statement

SET @SQL ='
ALTER DATABASE '+@DatabaseName+'ADD FILEGROUP InMemory_mod CONTAINS MEMORY_OPTIMIZED_DATA   
ALTER DATABASE '+@DatabaseName+'ADD FILE (name='InMemory_mod01', filename=N'''+@FileFolder+@DatabaseName+'\'+@DatabaseName+') TO FILEGROUP InMemory_mod   
ALTER DATABASE '+@DatabaseName+' SET MEMORY_OPTIMIZED_ELEVATE_TO_SNAPSHOT=ON '
SELECT @SQL

/* Create Filegroup*/

USE master
GO

ALTER DATABASE AdventureWorks2012
ADD FILEGROUP Test1FG1;
GO
ALTER DATABASE AdventureWorks2012 
ADD FILE 
(
    NAME = test1dat3,
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\t1dat3.ndf',
    SIZE = 5MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 5MB
),
(
    NAME = test1dat4,
    FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\DATA\t1dat4.ndf',
    SIZE = 5MB,
    MAXSIZE = 100MB,
    FILEGROWTH = 5MB
)
TO FILEGROUP Test1FG1;
GO