/*advanced*/

DECLARE @rowsThreshold INT=500; -- minimum amount of rows the table has to have
DECLARE @modificationThreshold INT=100; -- minimum amount of modifications the column has to have
DECLARE @sampleThreshold INT=8; -- sample size below this number
DECLARE @daysOldThreshold INT=1; -- how many days since the stat was updated
 
WITH bigTables([object_id],[tableName],[sizeRows])
as
(select TOP 20 object_id,name=object_schema_name(object_id) + '.' + object_name(object_id)
, rows=sum(case when index_id < 2 then row_count else 0 end) from sys.dm_db_partition_stats where object_id> 1024
group by object_id
HAVING sum(case when index_id < 2 then row_count else 0 end) >= @rowsThreshold
order by
rows DESC)
SELECT bt.tableName,st.name,bt.sizeRows,dsp.rows_sampled,dsp.rows Total_rows,dsp.last_updated,dsp.modification_counter,rows_sampled/(bt.sizeRows*1.0)*100 sample_pct,
(dsp.modification_counter*1./(bt.sizeRows*1.0))*100 as UpdatedPercentage,
'UPDATE STATISTICS '+bt.tableName+' '+st.name+' WITH SAMPLE '+ CONVERT(VARCHAR(3),@sampleThreshold) +' PERCENT;' AS [TSQL]
FROM bigTables bt INNER JOIN sys.stats st
ON bt.[object_id]=st.object_id
CROSS APPLY sys.dm_db_stats_properties(bt.[object_id],st.stats_id) dsp
--where dsp.rows <> dsp.rows_sampled
WHERE --rows_sampled/(bt.sizeRows*1.0)*100<=@sampleThreshold --AND datediff(DAY,last_updated,GETDATE())>=@daysOldThreshold
--AND 
dsp.modification_counter>= @modificationThreshold
