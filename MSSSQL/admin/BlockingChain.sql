WITH blockchain (session_id,blocking_session_id,status,level,chain)
AS
(
-- Anchor member definition
    SELECT sp_root.session_id, sp_root.blocking_session_id, sp_root.status, 0 as level, convert(varchar(max),ltrim(str(session_id))) as chain
    FROM sys.dm_exec_requests AS sp_root
    WHERE sp_root.blocking_session_id = 0 and exists (select * from sys.dm_exec_requests sp_root2 where sp_root2.blocking_session_id = sp_root.session_id)
    UNION ALL
    SELECT sp_root.session_id, cast(0 as smallint), sp_root.status, 0 as level, convert(varchar(max),ltrim(str(session_id))) as chain
    FROM sys.dm_exec_sessions AS sp_root
    WHERE sp_root.status = 'sleeping' and exists (select * from sys.dm_exec_requests sp_root2 where sp_root2.blocking_session_id = sp_root.session_id)
    
    UNION ALL
-- Recursive member definition
    SELECT sysproc.session_id, sysproc.blocking_session_id, sysproc.status, level + 1, chain + ' - ' + ltrim(str(sysproc.session_id)) 
    FROM blockchain 
    INNER JOIN sys.dm_exec_requests AS sysproc
    ON blockchain.session_id = sysproc.blocking_session_id
)
select * from blockchain order by chain
 
 
/* other version with current statement*/ 
 
WITH blockchain (session_id,text, blocking_session_id,status,level,chain)
AS
(
-- Anchor member definition
    SELECT sp_root.session_id, sqltext.text, sp_root.blocking_session_id, sp_root.status, 0 as level, convert(varchar(max),ltrim(str(session_id))) as chain
    FROM sys.dm_exec_requests AS sp_root
    CROSS APPLY sys.dm_exec_sql_text(sql_handle) as sqltext
    WHERE sp_root.blocking_session_id = 0 and exists (select * from sys.dm_exec_requests sp_root2 where sp_root2.blocking_session_id = sp_root.session_id)
    
    UNION ALL
    
    SELECT sp_root.session_id, cast('unknown - completed' as nvarchar(max)), cast(0 as smallint), sp_root.status, 0 as level, convert(varchar(max),ltrim(str(session_id))) as chain
    FROM sys.dm_exec_sessions AS sp_root
    WHERE sp_root.status = 'sleeping' and exists (select * from sys.dm_exec_requests sp_root2 where sp_root2.blocking_session_id = sp_root.session_id)
    
    UNION ALL
-- Recursive member definition
    
    SELECT sysproc.session_id, sqltext.text, sysproc.blocking_session_id, sysproc.status, level + 1, chain + ' - ' + ltrim(str(sysproc.session_id)) 
    FROM blockchain 
    INNER JOIN sys.dm_exec_requests AS sysproc
    CROSS APPLY sys.dm_exec_sql_text(sql_handle) as sqltext
    ON blockchain.session_id = sysproc.blocking_session_id
)
select * from blockchain order by chain
