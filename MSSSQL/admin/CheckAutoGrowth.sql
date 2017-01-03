/* in Mb*/

IF OBJECT_ID('tempdb..#info') IS NOT NULL
       DROP TABLE #info;

-- Create table with all file information per DB
CREATE TABLE #info (
     databasename VARCHAR(128)
     --,name VARCHAR(128)
    ,Filegroup VARCHAR(128)
    ,FileNumber INT
    ,SizeMax VARCHAR(25)
    ,SizeMin VARCHAR(25)
    ,AvgFileUse VARCHAR(25)
    ,GrowthPerFile VARCHAR(25)
    ,TotalGrowth VARCHAR(25)
    ,Usage VARCHAR(25));
    
-- Get database file information for each database  
SET NOCOUNT ON;
INSERT INTO #info
EXEC sp_MSforeachdb 'use ?
select  DB_NAME(),
filegroup = filegroup_name(groupid),
''FileNumber'' = count (*),
''SizeMax'' = convert(nvarchar(15), convert (bigint, MAX(size)) * 8/1024) + N'' MB'',
''SizeMax'' = convert(nvarchar(15), convert (bigint, MAX(size)) * 8/1024) + N'' MB'',
''AvgFileUse'' = convert(nvarchar(20),convert (Decimal(15,2),AVG(Fileproperty(name,''SpaceUsed'')))* 8/1024)+ N'' MB'' ,
''growth'' = (case status & 0x100000 when 0x100000 then
convert(nvarchar(15), growth) + N''%''
else
convert(nvarchar(15), convert (bigint, growth) * 8/1024) + N'' MB'' end),
''TotalGrowth'' = (case status & 0x100000 when 0x100000 then
convert(nvarchar(15), growth * count(*)) + N''%''
else
convert(nvarchar(15), (convert (bigint, growth) * 8/1024) * count (*)) + N'' MB'' end),
''usage'' = (case status & 0x40 when 0x40 then ''log only'' else ''data only'' end)
from sysfiles
Group By groupid,growth,status
';

-- Identify database files that use default auto-grow properties
SELECT *FROM #info
ORDER BY databasename, Filegroup
--WHERE (usage = 'data only' AND growth = '1024 KB')
 --  OR (usage = 'log only' AND growth = '10%')