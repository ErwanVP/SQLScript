SELECT *
FROM sys.dm_exec_requests r 
WHERE r.command in ('BACKUP DATABASE','RESTORE DATABASE') 