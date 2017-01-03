
-- Missing Indexes current database by Index Advantage
SELECT user_seeks * avg_total_user_cost * (avg_user_impact * 0.01) AS [index_advantage], 
migs.last_user_seek, mid.[statement] AS [Database.Schema.Table],
mid.equality_columns, mid.inequality_columns, mid.included_columns,
migs.unique_compiles, migs.user_seeks, migs.avg_total_user_cost, migs.avg_user_impact
FROM sys.dm_db_missing_index_group_stats AS migs WITH (NOLOCK)
INNER JOIN sys.dm_db_missing_index_groups AS mig WITH (NOLOCK)
ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details AS mid WITH (NOLOCK)
ON mig.index_handle = mid.index_handle
WHERE mid.database_id = DB_ID() -- Remove this to see for entire instance
ORDER BY index_advantage DESC OPTION (RECOMPILE);


SELECT
statement AS [database.scheme.table],
column_id , column_name, column_usage,
migs.user_seeks, migs.user_scans,
migs.last_user_seek, migs.avg_total_user_cost,
migs.avg_user_impact
FROM sys.dm_db_missing_index_details AS mid
CROSS APPLY sys.dm_db_missing_index_columns (mid.index_handle)
INNER JOIN sys.dm_db_missing_index_groups AS mig
ON mig.index_handle = mid.index_handle
INNER JOIN sys.dm_db_missing_index_group_stats  AS migs
ON mig.index_group_handle=migs.group_handle
Where database_id=5
ORDER BY mig.index_group_handle, mig.index_handle, column_id

 
SELECT * FROM sys.dm_db_missing_index_details a(nolock)
inner join sys.dm_db_missing_index_groups b (nolock) on a.index_handle=b.index_handle
inner join sys.dm_db_missing_index_group_stats  c (nolock) on b.index_group_handle = c.group_handle
where database_id =5 
