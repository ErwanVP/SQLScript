SELECT cp.objtype AS ObjectType,
OBJECT_NAME(st.objectid,st.dbid) AS ObjectName,
cp.usecounts AS ExecutionCount,
st.TEXT AS QueryText,
qp.query_plan AS QueryPlan
FROM sys.dm_exec_cached_plans AS cp with (nolock) 
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
WHERE OBJECT_NAME(st.objectid,st.dbid) = 'Stored procedure name'


/* Find all stat of stored procedure for all plan*/
SELECT DBName,SchemaName,StoredProcedure,CacheType,CacheObjType,execution_count,total_IO,avg_total_IO,total_physical_reads
		,avg_physical_read,total_logical_reads,total_logical_writes,avg_logical_writes
		,Avg_CPU_Time,avg_elapsed_time,last_elapsed_time,max_elapsed_time,min_elapsed_time
		, SUBSTRING ( A.texte , ( startos / 2 )+ 1 ,(( CASE endos
													WHEN - 1 THEN DATALENGTH ( A.texte)
													ELSE endos
													END - startos )/ 2 )+ 1 ) as Query
		,qp.query_plan-- ,A.texte 
	FROM
	(SELECT DB_NAME(st.dbid) DBName
	,OBJECT_SCHEMA_NAME(st.objectid,st.dbid) SchemaName
	,OBJECT_NAME(st.objectid,st.dbid) StoredProcedure
	,cp.objtype as CacheType
	,cp.cacheobjtype as CacheObjType
	,max(cp.usecounts) execution_count
	,sum(qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes) total_IO
	,sum(qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes) / (max(cp.usecounts)) avg_total_IO
	,sum(qs.total_physical_reads) total_physical_reads
	,sum(qs.total_physical_reads) / (max(cp.usecounts) * 1.0) avg_physical_read    
	,sum(qs.total_logical_reads) total_logical_reads
	,sum(qs.total_logical_reads) / (max(cp.usecounts) * 1.0) avg_logical_read  
	,sum(qs.total_logical_writes) total_logical_writes
	,sum(qs.total_logical_writes) / (max(cp.usecounts) * 1.0) avg_logical_writes
	,SUM(qs.total_worker_time) / max(cp.usecounts) Avg_CPU_Time
	,sum(qs.total_elapsed_time) /max(cp.usecounts) avg_elapsed_time
	,sum(qs.last_elapsed_time) last_elapsed_time
	,sum(qs.max_elapsed_time) max_elapsed_time
	,sum(qs.min_elapsed_time) min_elapsed_time
	,qs.plan_handle Phandle
	,St.text texte
	,statement_start_offset startos
	,statement_end_offset endos
	FROM sys.dm_exec_query_stats qs 
		CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) ST
		join sys.dm_exec_cached_plans cp on qs.plan_handle = cp.plan_handle
	where  --and cp.objtype = 'proc'
	 -- and 
	  st.text like '% catalog%'
	  AND ISNULL(OBJECT_SCHEMA_NAME(st.objectid,st.dbid),'a') not like 'sys'
	  group by DB_NAME(st.dbid),OBJECT_SCHEMA_NAME(st.objectid,st.dbid), OBJECT_NAME(st.objectid,st.dbid)
	  ,st.text,qs.plan_handle, cp.objtype, cp.cacheobjtype,statement_start_offset,statement_end_offset
  )A
cross apply sys.dm_exec_query_plan(A.Phandle) qp 
 order by --StoredProcedure desc 
 --, execution_count desc, 
 avg_total_IO desc
 OPTION (RECOMPILE)


 /*Stat general of SP per plan*/
SELECT DBName,SchemaName,StoredProcedure,execution_count,total_IO,avg_total_IO,total_physical_reads
		,avg_physical_read,total_logical_reads,total_logical_writes,avg_logical_writes
		,Avg_CPU_Time,avg_elapsed_time,last_elapsed_time,max_elapsed_time,min_elapsed_time
		,A.texte,qp.query_plan
	FROM
	(SELECT DB_NAME(st.dbid) DBName
      ,OBJECT_SCHEMA_NAME(st.objectid,st.dbid) SchemaName
      ,OBJECT_NAME(st.objectid,st.dbid) StoredProcedure
      ,max(cp.usecounts) execution_count
      ,sum(qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes) total_IO
      ,sum(qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes) / (max(cp.usecounts)) avg_total_IO
      ,sum(qs.total_physical_reads) total_physical_reads
      ,sum(qs.total_physical_reads) / (max(cp.usecounts) * 1.0) avg_physical_read    
      ,sum(qs.total_logical_reads) total_logical_reads
      ,sum(qs.total_logical_reads) / (max(cp.usecounts) * 1.0) avg_logical_read  
      ,sum(qs.total_logical_writes) total_logical_writes
      ,sum(qs.total_logical_writes) / (max(cp.usecounts) * 1.0) avg_logical_writes
	,SUM(qs.total_worker_time) / max(cp.usecounts) Avg_CPU_Time
	,sum(qs.total_elapsed_time) /max(cp.usecounts) avg_elapsed_time
	,sum(qs.last_elapsed_time) last_elapsed_time
	,sum(qs.max_elapsed_time) max_elapsed_time
	,sum(qs.min_elapsed_time) min_elapsed_time
	  ,qs.plan_handle Phandle
	  ,St.text texte
	FROM sys.dm_exec_query_stats qs 
		CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) ST
		join sys.dm_exec_cached_plans cp on qs.plan_handle = cp.plan_handle
	where  --and cp.objtype = 'proc'
	 -- and 
	  st.text like '% catalog%'
	  AND ISNULL(OBJECT_SCHEMA_NAME(st.objectid,st.dbid),'a') not like 'sys'
	  group by DB_NAME(st.dbid),OBJECT_SCHEMA_NAME(st.objectid,st.dbid), OBJECT_NAME(st.objectid,st.dbid),st.text,qs.plan_handle
  )A
cross apply sys.dm_exec_query_plan(A.Phandle) qp 
 order by StoredProcedure desc , execution_count desc, total_IO desc
 OPTION (RECOMPILE)
