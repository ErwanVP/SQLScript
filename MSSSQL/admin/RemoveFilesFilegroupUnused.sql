
/*remove file in unused filegroup */

SELECT --s.name, f.name, f.physical_name, f.size * 8 / 1024 as 'SizeMB' ,
'DBCC SHRINKFILE (N''' + f.name + ''',EMPTYFILE); ALTER DATABASE [' + DB_NAME() + ']  REMOVE FILE [' + f.name + ']' + CHAR(13) + 'GO' + Char(13)
	,Fileproperty(f.name,'SpaceUsed')* 8 /1024 as SpaceUsed
FROM sys.data_spaces s INNER JOIN sys.database_files f
	ON s.data_space_id = f.data_space_id
where f.data_space_id in (SELECT data_space_id FROM sys.data_spaces a
WHERE NOT EXISTS (
SELECT ds.data_space_id
FROM sys.data_spaces AS DS 
     INNER JOIN sys.allocation_units AS AU 
         ON DS.data_space_id = AU.data_space_id 
     INNER JOIN sys.partitions AS PA 
         ON (AU.type IN (1, 3)  
             AND AU.container_id = PA.hobt_id) 
            OR 
            (AU.type = 2 
             AND AU.container_id = PA.partition_id) 
     INNER JOIN sys.objects AS OBJ 
         ON PA.object_id = OBJ.object_id 
     INNER JOIN sys.schemas AS SCH 
         ON OBJ.schema_id = SCH.schema_id 
     LEFT JOIN sys.indexes AS IDX 
         ON PA.object_id = IDX.object_id 
            AND PA.index_id = IDX.index_id 
      WHERE a.data_space_id = ds.data_space_id )
and  a.type ='FG')

/*removeunused filegroup*/
SELECT * , 'ALTER DATABASE '+db_name()+' REMOVE FILEGROUP '+ name as 'remove_filegroup_withoutfile' FROM sys.filegroups a
where data_space_id not in 
(SELECT data_space_id FROM sys.database_files b
where a.data_space_id = b.data_space_id)

