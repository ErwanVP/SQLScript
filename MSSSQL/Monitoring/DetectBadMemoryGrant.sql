/* Need minimum sql server 2012 Sp3 or sql server 2014 sp2*/

/* see the query requested the most of toltal memory*/
SELECT (SUM(s.max_ideal_grant_kb)*MAX(s.execution_count))Ratio, SUM(s.max_ideal_grant_kb)max_ideal_grant_kb, SUM (s.max_grant_kb)max_grant_kb, SUM(s.max_used_grant_kb)max_used_grant_kb
,MAX(s.execution_count)execution_count,t.text
FROM SYS.DM_EXEC_QUERY_STATS as s WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(s.sql_handle) as t
cross apply sys.dm_exec_query_plan(plan_handle) as p
GROUP BY s.sql_handle, t.text
ORDER BY  (SUM(s.max_grant_kb)*MAX(s.execution_count)) desc
OPTION (RECOMPILE)

SELECT (SUM(s.max_ideal_grant_kb)*MAX(s.execution_count))Ratio, SUM(s.max_ideal_grant_kb)max_ideal_grant_kb, SUM (s.max_grant_kb)max_grant_kb, SUM(s.max_used_grant_kb)max_used_grant_kb
,MAX(s.execution_count)execution_count,t.text
FROM SYS.DM_EXEC_QUERY_STATS as s WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(s.sql_handle) as t
cross apply sys.dm_exec_query_plan(plan_handle) as p
GROUP BY s.sql_handle, t.text
ORDER BY  SUM(s.max_grant_kb) desc
OPTION (RECOMPILE)


/* query request the most of memory*/
SELECT TOP 100 s.max_ideal_grant_kb, s.max_grant_kb, s.max_used_grant_kb,t.text,execution_count, p.*
FROM SYS.DM_EXEC_QUERY_STATS as s WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(s.sql_handle) as t
cross apply sys.dm_exec_query_plan(plan_handle) as p
--where max_ideal_grant_kb < s.max_grant_kb
ORDER BY s.max_ideal_grant_kb desc
(OPTION RECOMPILE)

--uniquement les sp + statement

SELECT TOP 100  ((max_used_grant_kb*1.0)/s.max_grant_kb)*100.00,s.max_ideal_grant_kb, s.max_grant_kb, s.max_used_grant_kb
,s.execution_count,statement_start_offset,statement_end_offset,t.text,
 SUBSTRING(t.text,statement_start_offset / 2+1 , 
      ((CASE WHEN statement_end_offset = -1 
         THEN (LEN(CONVERT(nvarchar(max),t.text)) * 2) 
         ELSE statement_end_offset END)  - statement_start_offset) / 2+1)AS sql_statement
, P. *
FROM SYS.DM_EXEC_QUERY_STATS as s WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(s.sql_handle) as t
cross apply sys.dm_exec_query_plan(plan_handle) as p
where  s.max_grant_kb > 1024
and max_used_grant_kb > 0
and p.objectid is not null
ORDER BY (((max_used_grant_kb*1.0)/s.max_grant_kb)*100.00) asc
OPTION (RECOMPILE)


-- difference memoire grant memoire used
SELECT TOP 100  ((s.max_grant_kb-max_used_grant_kb)*s.execution_count),s.max_ideal_grant_kb, s.max_grant_kb, s.max_used_grant_kb
,s.execution_count,statement_start_offset,statement_end_offset,t.text,
 SUBSTRING(t.text,statement_start_offset / 2+1 , 
      ((CASE WHEN statement_end_offset = -1 
         THEN (LEN(CONVERT(nvarchar(max),t.text)) * 2) 
         ELSE statement_end_offset END)  - statement_start_offset) / 2+1)AS sql_statement
, P. *
FROM SYS.DM_EXEC_QUERY_STATS as s WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(s.sql_handle) as t
cross apply sys.dm_exec_query_plan(plan_handle) as p
where  s.max_grant_kb > 1024
and max_used_grant_kb > 0
and p.objectid is not null
ORDER BY ((s.max_grant_kb-max_used_grant_kb)*s.execution_count)desc
OPTION (RECOMPILE)


-- toute les requetes


SELECT TOP 100  ((max_used_grant_kb*1.0)/s.max_grant_kb)*100.00,s.max_ideal_grant_kb, s.max_grant_kb, s.max_used_grant_kb
,s.execution_count,statement_start_offset,statement_end_offset,t.text,
 SUBSTRING(t.text,statement_start_offset / 2+1 , 
      ((CASE WHEN statement_end_offset = -1 
         THEN (LEN(CONVERT(nvarchar(max),t.text)) * 2) 
         ELSE statement_end_offset END)  - statement_start_offset) / 2+1)AS sql_statement
, P. *
FROM SYS.DM_EXEC_QUERY_STATS as s WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(s.sql_handle) as t
cross apply sys.dm_exec_query_plan(plan_handle) as p
where  s.max_grant_kb > 1024
and max_used_grant_kb > 0
ORDER BY (((max_used_grant_kb*1.0)/s.max_grant_kb)*100.00) asc
OPTION (RECOMPILE)

