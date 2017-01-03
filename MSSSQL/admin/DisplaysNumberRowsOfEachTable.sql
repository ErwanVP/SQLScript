
SELECT OBJECT_NAME(OBJECT_ID) TableName, st.row_count
FROM sys.dm_db_partition_stats st
WHERE index_id < 2
--and OBJECT_NAME (st.object_id)= 'sysdercv'
ORDER BY st.row_count DESC