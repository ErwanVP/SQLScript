SELECT TOP 10
qs.plan_generation_num,
qs.execution_count,
DB_NAME(st.dbid) AS DbName,
st.objectid,
st.TEXT
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS st
ORDER BY plan_generation_num DESC


SELECT DBName,SchemaName,StoredProcedure,execution_count
		,A.texte,qp.query_plan
	FROM
	(SELECT DB_NAME(st.dbid) DBName
      ,OBJECT_SCHEMA_NAME(st.objectid,st.dbid) SchemaName
      ,OBJECT_NAME(st.objectid,st.dbid) StoredProcedure
      ,max(cp.usecounts) execution_count
	  ,qs.plan_handle Phandle
	  ,St.text texte
	FROM sys.dm_exec_query_stats qs 
		CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) ST
		join sys.dm_exec_cached_plans cp on qs.plan_handle = cp.plan_handle
	where  cp.objtype = 'proc'
	 -- and 
	  --st.text like '% catalog%' -- Add this to add filter in query text 
	  AND 
      ISNULL(OBJECT_SCHEMA_NAME(st.objectid,st.dbid),'a') not like 'sys'
	  group by DB_NAME(st.dbid),OBJECT_SCHEMA_NAME(st.objectid,st.dbid), OBJECT_NAME(st.objectid,st.dbid),st.text,qs.plan_handle
  )A
cross apply sys.dm_exec_query_plan(A.Phandle) qp 
 order by StoredProcedure desc , execution_count desc
 OPTION (RECOMPILE)

--with query detail

 SELECT DBName,SchemaName,StoredProcedure,CacheType,CacheObjType,execution_count
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
	,qs.plan_handle Phandle
	,St.text texte
	,statement_start_offset startos
	,statement_end_offset endos
	FROM sys.dm_exec_query_stats qs 
		CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) ST
		join sys.dm_exec_cached_plans cp on qs.plan_handle = cp.plan_handle
	where cp.objtype = 'proc'
	 -- and 
	  --st.text like '% catalog%'-- Add this to add filter in query text 
	  AND ISNULL(OBJECT_SCHEMA_NAME(st.objectid,st.dbid),'a') not like 'sys'
	  group by DB_NAME(st.dbid),OBJECT_SCHEMA_NAME(st.objectid,st.dbid), OBJECT_NAME(st.objectid,st.dbid)
	  ,st.text,qs.plan_handle, cp.objtype, cp.cacheobjtype,statement_start_offset,statement_end_offset
  )A
cross apply sys.dm_exec_query_plan(A.Phandle) qp 
 order by --StoredProcedure desc 
 execution_count desc
