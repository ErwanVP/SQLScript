SELECT o.name Object_Name,
       SCHEMA_NAME(o.schema_id) Schema_name,
       i.name Index_name,
       i.Type_Desc,
       s.user_seeks,
       s.user_scans,
       s.user_lookups,
       s.user_updates 
 FROM sys.objects AS o
     JOIN sys.indexes AS i
 ON o.object_id = i.object_id
     JOIN
  sys.dm_db_index_usage_stats AS s   
 ON i.object_id = s.object_id  
  AND i.index_id = s.index_id
 WHERE  o.type = 'u'
 --Clustered and Non-Clustered indexes
  AND i.type IN (1, 2)
 --Indexes that have been updated by not used
  AND(s.user_seeks > 0 or s.user_scans > 0 or s.user_lookups > 0 );