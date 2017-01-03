--- State of cache 

SELECT objtype AS [CacheType]
,cacheobjtype
        , count_big(*) AS [Total Plans]
        , sum(cast(size_in_bytes as decimal(18,2)))/1024/1024 AS [Total MBs]
        , avg(usecounts) AS [Avg Use Count]
        , sum(cast((CASE WHEN usecounts = 1 THEN size_in_bytes ELSE 0 END) as decimal(18,2)))/1024/1024 AS [Total MBs - USE Count 1]
        , sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) AS [Total Plans - USE Count 1]
        , sum(CASE WHEN usecounts = 1 THEN 1 ELSE 0 END) * 100 / count_big(*) as [Percent of plan used 1 time] 
FROM sys.dm_exec_cached_plans
GROUP BY objtype,cacheobjtype
ORDER BY [Total MBs - USE Count 1] DESC

-- Find the most cached object

select TOP 10 LEFT(sql, 50),  COUNT(*)
from sys.syscacheobjects s
group by LEFT(sql, 50)
ORDER BY 2 DESC

-- find query with the plan is used one time 

SELECT TOP 10 LEFT(Text,50), COUNT(*), dbid
FROM sys.dm_Exec_cached_plans
CROSS APPLY sys.dm_exec_sql_text(plan_handle)
WHERE cacheobjtype = 'Compiled Plan'
AND objtype = 'Adhoc' AND usecounts = 1
AND size_in_bytes < 5242880 
GROUP BY LEFT(text,50), dbid
ORDER BY 2 DESC 


-- find 

SELECT TOP 100 s.max_ideal_grant_kb, s.max_grant_kb, s.max_used_grant_kb,t.text, *
FROM SYS.DM_EXEC_QUERY_STATS as s WITH (NOLOCK)
CROSS APPLY sys.dm_exec_sql_text(s.sql_handle) as t
where max_ideal_grant_kb < s.max_grant_kb
ORDER BY s.max_ideal_grant_kb desc