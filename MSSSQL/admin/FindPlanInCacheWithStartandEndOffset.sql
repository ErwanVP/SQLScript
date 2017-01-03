SELECT s2.dbid, 
		DB_NAME(s2.dbid),
    s1.sql_handle,  
    (SELECT TOP 1 SUBSTRING(s2.text,statement_start_offset / 2+1 , 
      ( (CASE WHEN statement_end_offset = -1 
         THEN (LEN(CONVERT(nvarchar(max),s2.text)) * 2) 
         ELSE statement_end_offset END)  - statement_start_offset) / 2+1))  AS sql_statement,
    *  
FROM sys.dm_exec_query_stats AS s1 
CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS s2  
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS s3 
WHERE 
s1.sql_handle = 0x03000500d5f11d576f30130179a100000100000000000000
and s1.statement_start_offset =558
and s1.statement_end_offset =1098
ORDER BY s1.sql_handle, s1.statement_start_offset, s1.statement_end_offset;