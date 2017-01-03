--http://blogs.msdn.com/b/turgays/archive/2013/05/08/how-to-find-unused-statistics.aspx


select TableName, StatsName, auto_created, UpdatedRowCount, TableRowCount

      , case TableRowCount when 0 then 0 else UpdatedRowCount*1./TableRowCount end as UpdatedPercentage

      , StatsLastUpdatedTime

from(

select OBJECT_NAME(id) as TableName

      ,s.name as StatsName

      ,s.auto_created

      ,rowmodctr as UpdatedRowCount

      ,(select SUM(row_count) from sys.dm_db_partition_stats where object_id=i.id and (index_id=0 or index_id=1)) as TableRowCount

      ,STATS_DATE(i.id,i.indid) as StatsLastUpdatedTime

from sysindexes i

left join sys.stats s on s.object_id=i.id and s.stats_id=i.indid

)xx

order by (case TableRowCount when 0 then 0 else UpdatedRowCount*1./TableRowCount end) desc 

/*******
Remove Ms table
********/


	select TableName, StatsName, auto_created, UpdatedRowCount, TableRowCount
      , case TableRowCount when 0 then 0 else (UpdatedRowCount*1./TableRowCount)*100 end as UpdatedPercentage
      , StatsLastUpdatedTime
      ,user_created
	,statement
from(

select distinct OBJECT_NAME(id) as TableName

      ,s.name as StatsName

      ,s.auto_created

      ,rowmodctr as UpdatedRowCount

      ,(select SUM(row_count) from sys.dm_db_partition_stats where object_id=i.id and (index_id=0 or index_id=1)) as TableRowCount

      ,STATS_DATE(i.id,i.indid) as StatsLastUpdatedTime

      ,user_created as user_created

	  , 'DROP STATISTICS [' + OBJECT_SCHEMA_NAME(s.object_id) + '].[' + OBJECT_NAME(s.object_id) + '].[' + s.name + ']' as statement 

from sysindexes i

left join sys.stats s on s.object_id=i.id and s.stats_id=i.indid

inner join sys.objects o on i.id = o.object_id 

where o.is_ms_shipped = 0 
and o.type = 'U'

)xx
order by StatsLastUpdatedTime asc
--order by (case TableRowCount when 0 then 0 else UpdatedRowCount*1./TableRowCount end) desc 



--https://www.pythian.com/blog/sql-server-statistics-maintenance-and-best-practices/
/* Find and delete overlapped statitics*/


WITH    autostats ( object_id, stats_id, name, column_id )
 
AS ( SELECT   sys.stats.object_id ,
 
sys.stats.stats_id ,
 
sys.stats.name ,
 
sys.stats_columns.column_id
 
FROM     sys.stats
 
INNER JOIN sys.stats_columns ON sys.stats.object_id = sys.stats_columns.object_id
 
AND sys.stats.stats_id = sys.stats_columns.stats_id
 
WHERE    sys.stats.auto_created = 1
 
AND sys.stats_columns.stats_column_id = 1
 
)
 
SELECT  OBJECT_NAME(sys.stats.object_id) AS [Table] ,
 
sys.columns.name AS [Column] ,
 
sys.stats.name AS [Overlapped] ,
 
autostats.name AS [Overlapping] ,
 
'DROP STATISTICS [' + OBJECT_SCHEMA_NAME(sys.stats.object_id)
 
+ '].[' + OBJECT_NAME(sys.stats.object_id) + '].['
 
+ autostats.name + ']'
 
FROM    sys.stats
 
INNER JOIN sys.stats_columns ON sys.stats.object_id = sys.stats_columns.object_id
 
AND sys.stats.stats_id = sys.stats_columns.stats_id
 
INNER JOIN autostats ON sys.stats_columns.object_id = autostats.object_id
 
AND sys.stats_columns.column_id = autostats.column_id
 
INNER JOIN sys.columns ON sys.stats.object_id = sys.columns.object_id
 
AND sys.stats_columns.column_id = sys.columns.column_id
 
WHERE   sys.stats.auto_created = 0
 
AND sys.stats_columns.stats_column_id = 1
 
AND sys.stats_columns.stats_id != autostats.stats_id
 
AND OBJECTPROPERTY(sys.stats.object_id, 'IsMsShipped') = 0
