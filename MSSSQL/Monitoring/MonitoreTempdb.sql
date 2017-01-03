--Show the waiting task with the blocked statement.
--If you have a  on tempdb Pagelatch _up _sh _ex maybe cntention on tempdb.

SELECT r.session_id,login_name, r.status, r.command, r.database_id, r.blocking_session_id, r.wait_type, r.wait_time, r.wait_resource, t.text
, stmt = SUBSTRING(t.text, (r.statement_start_offset/2) + 1, CASE r.statement_end_offset WHEN -1 THEN DATALENGTH(t.text) ELSE (r.statement_end_offset - r.statement_start_offset)/2 end) 
FROM sys.dm_exec_requests r join sys.dm_exec_sessions s on r.session_id = s.session_id 
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t 
WHERE wait_type IS NOT NULL and s.is_user_process = 1

-- Verify the access of each files in tempdb. if the time of write ond read is over 20msthere problem on access in tempdbfile 

SELECT files.physical_name, files.name,
    stats.num_of_writes, (1.0 * stats.io_stall_write_ms / stats.num_of_writes) AS avg_write_stall_ms,
    stats.num_of_reads, (1.0 * stats.io_stall_read_ms / stats.num_of_reads) AS avg_read_stall_ms
FROM sys.dm_io_virtual_file_stats(2, NULL) as stats
INNER JOIN master.sys.master_files AS files
    ON stats.database_id = files.database_id
    AND stats.file_id = files.file_id
WHERE files.type_desc = 'ROWS'


-- Information about waitype tempdb where the process wait.
SELECT session_id,wait_type,wait_duration_ms,blocking_session_id,resource_description,
ResourceType = CASE
                WHEN Cast(RIGHT(resource_description, Len(resource_description) - Charindex(':', resource_description, LEN(resource_description)-CHARINDEX(':', REVERSE(resource_description), 1))) AS NVARCHAR) - 1 % 8088 = 0 THEN 'Is PFS Page'
                WHEN Cast(RIGHT(resource_description, Len(resource_description) - Charindex(':', resource_description, LEN(resource_description)-CHARINDEX(':', REVERSE(resource_description), 1))) AS NVARCHAR) - 2 % 511232 = 0 THEN 'Is GAM Page'
                WHEN Cast(RIGHT(resource_description, Len(resource_description) - Charindex(':', resource_description, LEN(resource_description)-CHARINDEX(':', REVERSE(resource_description), 1))) AS NVARCHAR) - 3 % 511232 = 0 THEN 'Is SGAM Page'
                ELSE 'Is Not PFS, GAM, or SGAM page'
              END
FROM sys.dm_os_waiting_tasks
WHERE wait_type LIKE 'PAGE%LATCH_%'

Select session_id,wait_type,wait_duration_ms,
blocking_session_id,resource_Description,Descr.*
From sys.dm_os_waiting_tasks as waits inner join sys.dm_os_buffer_Descriptors as Descr
on LEFT(waits.resource_description, Charindex(':', waits.resource_description,0)-1) = Descr.database_id
and SUBSTRING(waits.resource_description, Charindex(':', waits.resource_description)+1,Charindex(':', waits.resource_description,Charindex(':', resource_description)+1)- (Charindex(':', resource_description)+1)) = Descr.[file_id]
and Right(waits.resource_description, Len(waits.resource_description) - Charindex(':', waits.resource_description, 3)) = Descr.[page_id]
Where wait_type Like 'PAGE%LATCH_%'



/* Current query with tempdb allocation */
;WITH task_space_usage AS (
    -- SUM alloc/delloc pages
    SELECT session_id,
           request_id,
           SUM(internal_objects_alloc_page_count) AS alloc_pages,
           SUM(internal_objects_dealloc_page_count) AS dealloc_pages
    FROM sys.dm_db_task_space_usage WITH (NOLOCK)
    WHERE session_id <> @@SPID
    GROUP BY session_id, request_id
)
SELECT TSU.session_id,
       TSU.alloc_pages * 1.0 / 128 AS [internal object MB space],
       TSU.dealloc_pages * 1.0 / 128 AS [internal object dealloc MB space],
       EST.text,
       -- Extract statement from sql text
       ISNULL(
           NULLIF(
               SUBSTRING(
                 EST.text, 
                 ERQ.statement_start_offset / 2, 
                 CASE WHEN ERQ.statement_end_offset < ERQ.statement_start_offset 
                  THEN 0 
                 ELSE( ERQ.statement_end_offset - ERQ.statement_start_offset ) / 2 END
               ), ''
           ), EST.text
       ) AS [statement text],
       EQP.query_plan
FROM task_space_usage AS TSU
INNER JOIN sys.dm_exec_requests ERQ WITH (NOLOCK)
    ON  TSU.session_id = ERQ.session_id
    AND TSU.request_id = ERQ.request_id
OUTER APPLY sys.dm_exec_sql_text(ERQ.sql_handle) AS EST
OUTER APPLY sys.dm_exec_query_plan(ERQ.plan_handle) AS EQP
WHERE EST.text IS NOT NULL OR EQP.query_plan IS NOT NULL
ORDER BY 3 DESC;

 /* Allowed and cosumed space :  General */

SELECT
SUM (user_object_reserved_page_count)*8 as user_obj_kb,
SUM (internal_object_reserved_page_count)*8 as internal_obj_kb,
SUM (version_store_reserved_page_count)*8  as version_store_kb,
SUM (unallocated_extent_page_count)*8 as freespace_kb,
SUM (mixed_extent_page_count)*8 as mixedextent_kb
FROM sys.dm_db_file_space_usage

/* Allowed and cosumed space : Per user */ 

select

reserved_MB= convert(numeric(10,2),round((unallocated_extent_page_count+version_store_reserved_page_count+user_object_reserved_page_count+internal_object_reserved_page_count+mixed_extent_page_count)*8/1024.,2)) ,

unallocated_extent_MB =convert(numeric(10,2),round(unallocated_extent_page_count*8/1024.,2)),

user_object_reserved_page_count,

user_object_reserved_MB =convert(numeric(10,2),round(user_object_reserved_page_count*8/1024.,2))

from sys.dm_db_file_space_usage

/*Allowed and cosumed space : system*/

select

reserved_MB=(unallocated_extent_page_count+version_store_reserved_page_count+user_object_reserved_page_count+internal_object_reserved_page_count+mixed_extent_page_count)*8/1024. ,

unallocated_extent_MB =unallocated_extent_page_count*8/1024.,

internal_object_reserved_page_count,

internal_object_reserved_MB =internal_object_reserved_page_count*8/1024.

from sys.dm_db_file_space_usage
