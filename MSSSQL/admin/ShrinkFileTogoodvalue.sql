/* replace dbname by your database name*/
/* This script shrink all file with spaceused in filegroup + 5 mb*/

USE [dbname]
GO 

select  [FileID],convert(decimal(12,2),(100*[Space_Used_MB]/ [File_Size_MB])) '% Used'
, [File_Size_MB],[Space_Used_MB],[Free_Space_MB],[Name], [FileName],DateInserted
,'DBCC SHRINKFILE ('''+[Name]+''','+LEFT(convert(nvarchar(12),([Space_Used_MB]+5)),CHARINDEX ('.',convert(nvarchar(12),([Space_Used_MB]+5)))-1) +')'
,CHARINDEX ('.',convert(nvarchar(12),([Space_Used_MB]+5)))
FROM(SELECT [FileID], [File_Size_MB] = convert(decimal(12,2),round([size]/128.000,2)),
[Space_Used_MB] = convert(decimal(12,2),fileproperty([name],'SpaceUsed')/128.000),
[Free_Space_MB] = convert(decimal(12,2),([size]-fileproperty([name],'SpaceUsed'))/128.000) ,
[Name], [FileName], convert(datetime,Getdate(),112) as DateInserted
from [dbname].dbo.sysfiles)A
where convert(decimal(12,2),(100*[Space_Used_MB]/ [File_Size_MB])) < 90