http://social.msdn.microsoft.com/Forums/en-US/sqlservicebroker/thread/f6e93024-efac-4df4-a3df-8c03670a1266


select * from sys.transmission_queue

SELECT * FROM sys.dm_broker_activated_tasks with (nolock)


SELECT * FROM sys.dm_broker_forwarded_messages with (nolock)


SELECT * FROM sys.dm_broker_connections with (nolock)

SELECT * FROM  sys.dm_broker_queue_monitors with (nolock)


/* Purge conversation EndPoint */ 
 DECLARE @HANDLE UNIQUEIDENTIFIER
 
 WHILE (1=1)
 --WHILE ((SELECt TOP(1) 1 FROM SYS.CONVERSATION_ENDPOINTS) =1)
 BEGIN 
	
	SELECT Top 1 @HANDLE=CONVERSATION_HANDLE FROM SYS.CONVERSATION_ENDPOINTS
	END CONVERSATION @HANDLE WITH CLEANUP
  
 END

/* Check*/
SELECT OBJECT_NAME(OBJECT_ID) TableName, st.row_count
FROM sys.dm_db_partition_stats st
WHERE index_id < 2
and OBJECT_NAME (st.object_id)= 'sysdercv'
ORDER BY st.row_count DESC