EXEC sp_MSforeachdb
@command1='use ?; exec sp_changedbowner ''sa''' -- Change all DBs to "sa" owner

EXEC sp_MSforeachdb
@command1='ALTER DATABASE ? SET PAGE_VERIFY CHECKSUM' -- SQL 2005 Best Practice

EXEC sp_MSforeachdb
@command1='?.dbo.sp_change_users_login ''Report''' -- Check for Orphans

USE [master]
GO
EXEC sp_MSforeachdb
@command1='ALTER DATABASE [?] SET COMPATIBILITY_LEVEL = 120' -- change level de comptabilité

/* size of each db*/
exec sys.sp_MSforeachdb
'
USE ? select @@servername, '' ?'' ''DBname'', [FileID],convert(decimal(12,2),(100*[Space_Used_MB]/ [File_Size_MB])) ''% Used''
, [File_Size_MB],[Space_Used_MB],[Free_Space_MB],[Name], [FileName],DateInserted
FROM(SELECT [FileID], [File_Size_MB] = convert(decimal(12,2),round([size]/128.000,2)),
[Space_Used_MB] = convert(decimal(12,2),fileproperty([name],''SpaceUsed'')/128.000),
[Free_Space_MB] = convert(decimal(12,2),([size]-fileproperty([name],''SpaceUsed''))/128.000) ,
[Name], [FileName], convert(datetime,Getdate(),112) as DateInserted
from ?.dbo.sysfiles)A'