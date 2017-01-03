-- SQL CMD

/* This script move the data (clustered index or heap table) in filegroup DATA
and move the index the file group index. 
This script remove and recreate the foreign key.
*/

:setvar Database DBNEW
/* If you have a partition, the partition will be dropped in each object.
If you want to integrated the partitionning colum on index set the variable PCinIndex at 1 */
:setvar PCinIndex 0
USE master
GO
-- Move Data
GO
USE $(Database)
GO
-- Tous les indexs clustered et non clustered, non PK
IF $(PCinIndex) = 1
BEGIN
	SELECT 'CREATE ' + CASE Is_unique WHEN 0 THEN '' ELSE 'UNIQUE ' END  + CASE s.type WHEN 1 THEN 'CLUSTERED ' ELSE '' END + 'INDEX ['+ s.NAME + '] ON [' + OBJECT_SCHEMA_NAME(s.object_id) + '].[' + OBJECT_NAME(s.object_id) + '] ' +
		-- columns to be in the index
		'(' + (SELECT 
	REPLACE(
	REPLACE( -- Replacing XML Tag by ,
	REPLACE(
		CAST(
		(SELECT a.name + CASE is_descending_key WHEN 0 THEN ' ASC' ELSE ' DESC' END as 'Column'
		FROM sys.index_columns i INNER JOIN sys.all_columns a 
		ON i.object_id = a.object_id AND i.column_id = a.column_id 
		WHERE i.is_included_column = 0 AND i.object_id = s.object_id AND i.index_id = s.index_id
		ORDER BY key_ordinal
		FOR XML PATH('')) as nvarchar(max))
		, '</Column><Column>', ','), '</Column>',''), '<Column>','')
	) + ')'
		-- included columns
		+ ISNULL(CASE (SELECT TOP (1) 1 FROM sys.index_columns i WHERE i.is_included_column = 1 AND i.object_id = s.object_id)  
			WHEN 1 THEN ' INCLUDE (' + (SELECT 
					REPLACE(
					REPLACE( -- Replacing XML Tag by ,
					REPLACE(
						CAST(
						(SELECT a.name as 'Column'
						FROM sys.index_columns i INNER JOIN sys.all_columns a 
						ON i.object_id = a.object_id AND i.column_id = a.column_id
						WHERE i.is_included_column = 1 AND i.object_id = s.object_id AND i.index_id = s.index_id
						ORDER BY index_column_id
						FOR XML PATH('')) as nvarchar(max))
						, '</Column><Column>', ','), '</Column>',''), '<Column>','')) + ')'
			ELSE ' '
			END,'')
			-- WITH Section
			+ ' WITH (SORT_IN_TEMPDB = ON, DROP_EXISTING = ON) ' + 
			-- FILEGROUP Section
			CASE s.type WHEN 1 THEN 'ON [Data]' ELSE 'ON [INDEX]' END as 'idx clustered and no clustered, none PK'
	FROM sys.indexes s INNER JOIN sys.all_objects o
		ON o.object_id = s.object_id and is_unique_constraint = 0
	WHERE s.is_primary_key =0 and o.object_id >= 100 AND o.is_ms_shipped = 0 AND s.type > 0 /* Not Heap */
END
ELSE
BEGIN
		SELECT 'CREATE ' + CASE Is_unique WHEN 0 THEN '' ELSE 'UNIQUE ' END  + CASE s.type WHEN 1 THEN 'CLUSTERED ' ELSE '' END + 'INDEX ['+ s.NAME + '] ON [' + OBJECT_SCHEMA_NAME(s.object_id) + '].[' + OBJECT_NAME(s.object_id) + '] ' +
		-- columns to be in the index
		'(' + (SELECT 
	REPLACE(
	REPLACE( -- Replacing XML Tag by ,
	REPLACE(
		CAST(
		(SELECT a.name + CASE is_descending_key WHEN 0 THEN ' ASC' ELSE ' DESC' END as 'Column'
		FROM sys.index_columns i INNER JOIN sys.all_columns a 
		ON i.object_id = a.object_id AND i.column_id = a.column_id 
		WHERE i.is_included_column = 0 and is_unique_constraint = 0
			AND i.object_id = s.object_id AND i.index_id = s.index_id AND partition_ordinal = 0
		ORDER BY key_ordinal
		FOR XML PATH('')) as nvarchar(max))
		, '</Column><Column>', ','), '</Column>',''), '<Column>','')
	) + ')'
		-- included columns
		+ ISNULL(CASE (SELECT TOP (1) 1 FROM sys.index_columns i WHERE i.is_included_column = 1 AND i.object_id = s.object_id)  
			WHEN 1 THEN ' INCLUDE (' + (SELECT 
					REPLACE(
					REPLACE( -- Replacing XML Tag by ,
					REPLACE(
						CAST(
						(SELECT a.name as 'Column'
						FROM sys.index_columns i INNER JOIN sys.all_columns a 
						ON i.object_id = a.object_id AND i.column_id = a.column_id
						WHERE i.is_included_column = 1 AND i.object_id = s.object_id AND i.index_id = s.index_id
						ORDER BY index_column_id
						FOR XML PATH('')) as nvarchar(max))
						, '</Column><Column>', ','), '</Column>',''), '<Column>','')) + ')'
			ELSE ' '
			END,'')
			-- WITH Section
			+ ' WITH (SORT_IN_TEMPDB = ON, DROP_EXISTING = ON) ' + 
			-- FILEGROUP Section
			CASE s.type WHEN 1 THEN 'ON [Data]' ELSE 'ON [INDEX]' END as 'idx clustered and no clustered, none PK'
	FROM sys.indexes s INNER JOIN sys.all_objects o
		ON o.object_id = s.object_id	
	WHERE s.is_primary_key =0 and is_unique_constraint = 0
		and o.object_id >= 100 AND o.is_ms_shipped = 0 AND s.type > 0 /* Not Heap */
	order by s.NAME
END

GO
/* Unique constraint */
SELECT 
		   'ALTER TABLE [' + OBJECT_SCHEMA_NAME(s.object_id) + '].[' + OBJECT_NAME(s.object_id) + '] DROP CONSTRAINT [' + s.NAME + '];' + 
		   'ALTER TABLE [' + OBJECT_SCHEMA_NAME(s.object_id) + '].[' + OBJECT_NAME(s.object_id) + '] ADD CONSTRAINT [' + s.NAME + '] ' + 
		   'UNIQUE ' + CASE s.type WHEN 1 THEN 'CLUSTERED ' ELSE 'NONCLUSTERED ' END +
			-- columns to be in the PK
		'(' + (SELECT 
	REPLACE(
	REPLACE( -- Replacing XML Tag by ,
	REPLACE(
		CAST(
		(SELECT a.name + CASE is_descending_key WHEN 0 THEN ' ASC' ELSE ' DESC' END as 'Column'
		FROM sys.index_columns i INNER JOIN sys.all_columns a 
		ON i.object_id = a.object_id AND i.column_id = a.column_id 
		WHERE i.is_included_column = 0 AND i.object_id = s.object_id AND i.index_id = s.index_id 
		ORDER BY key_ordinal
		FOR XML PATH('')) as nvarchar(max))
		, '</Column><Column>', ','), '</Column>',''), '<Column>','')
	) + ')'
			-- WITH Section
			+ ' WITH (SORT_IN_TEMPDB = ON) ' + 
			-- FILEGROUP Section
			CASE s.type WHEN 1 THEN 'ON [Data]' ELSE 'ON [INDEX]' END + ';'	as 'MOVE UNIQUE CONSTRAINT "DROP AND CREATE"'	
	FROM sys.indexes s INNER JOIN sys.all_objects o
		ON o.object_id = s.object_id	
	WHERE is_unique_constraint = 1 and o.object_id >= 100 AND o.is_ms_shipped = 0 AND s.type > 0 /* Not Heap */

GO
/* Drop des FK */

SELECT 'ALTER TABLE [' + OBJECT_SCHEMA_NAME(f.parent_object_id) + '].[' + OBJECT_NAME(f.parent_object_id) + '] DROP CONSTRAINT [' + 
	OBJECT_NAME(f.object_id) + '];' as 'DROP FK'
FROM sys.foreign_keys f

GO
/* Move PK */

IF $(PCinIndex) = 1
BEGIN
	SELECT 
			-- PK
		   'ALTER TABLE [' + OBJECT_SCHEMA_NAME(s.object_id) + '].[' + OBJECT_NAME(s.object_id) + '] DROP CONSTRAINT [' + s.NAME + '];' + 
		   'ALTER TABLE [' + OBJECT_SCHEMA_NAME(s.object_id) + '].[' + OBJECT_NAME(s.object_id) + '] ADD CONSTRAINT [' + s.NAME + '] ' + 
		   'PRIMARY KEY ' + CASE s.type WHEN 1 THEN 'CLUSTERED ' ELSE 'NONCLUSTERED ' END +
			-- columns to be in the PK
		'(' + (SELECT 
	REPLACE(
	REPLACE( -- Replacing XML Tag by ,
	REPLACE(
		CAST(
		(SELECT a.name + CASE is_descending_key WHEN 0 THEN ' ASC' ELSE ' DESC' END as 'Column'
		FROM sys.index_columns i INNER JOIN sys.all_columns a 
		ON i.object_id = a.object_id AND i.column_id = a.column_id 
		WHERE i.is_included_column = 0 AND i.object_id = s.object_id AND i.index_id = s.index_id 
		ORDER BY key_ordinal
		FOR XML PATH('')) as nvarchar(max))
		, '</Column><Column>', ','), '</Column>',''), '<Column>','')
	) + ')'
			-- WITH Section
			+ ' WITH (SORT_IN_TEMPDB = ON) ' + 
			-- FILEGROUP Section
			CASE s.type WHEN 1 THEN 'ON [Data]' ELSE 'ON [INDEX]' END + ';'	as 'MOVE PK "DROP AND CREATE"'	
	FROM sys.indexes s INNER JOIN sys.all_objects o
		ON o.object_id = s.object_id	
	WHERE s.is_primary_key =1 and o.object_id >= 100 AND o.is_ms_shipped = 0 AND s.type > 0 /* Not Heap */
END
ELSE
BEGIN
	SELECT 
			-- PK
		   'ALTER TABLE [' + OBJECT_SCHEMA_NAME(s.object_id) + '].[' + OBJECT_NAME(s.object_id) + '] DROP CONSTRAINT [' + s.NAME + '];' + 
		   'ALTER TABLE [' + OBJECT_SCHEMA_NAME(s.object_id) + '].[' + OBJECT_NAME(s.object_id) + '] ADD CONSTRAINT [' + s.NAME + '] ' + 
		   'PRIMARY KEY ' + CASE s.type WHEN 1 THEN 'CLUSTERED ' ELSE 'NONCLUSTERED ' END +
			-- columns to be in the PK
		'(' + (SELECT 
	REPLACE(
	REPLACE( -- Replacing XML Tag by ,
	REPLACE(
		CAST(
		(SELECT a.name + CASE is_descending_key WHEN 0 THEN ' ASC' ELSE ' DESC' END as 'Column'
		FROM sys.index_columns i INNER JOIN sys.all_columns a 
		ON i.object_id = a.object_id AND i.column_id = a.column_id 
		WHERE i.is_included_column = 0 AND i.object_id = s.object_id AND i.index_id = s.index_id AND partition_ordinal = 0
		ORDER BY key_ordinal
		FOR XML PATH('')) as nvarchar(max))
		, '</Column><Column>', ','), '</Column>',''), '<Column>','')
	) + ')'
			-- WITH Section
			+ ' WITH (SORT_IN_TEMPDB = ON) ' + 
			-- FILEGROUP Section
			CASE s.type WHEN 1 THEN 'ON [Data]' ELSE 'ON [INDEX]' END + ';'	as 'MOVE PK "DROP AND CREATE"'	
	FROM sys.indexes s INNER JOIN sys.all_objects o
		ON o.object_id = s.object_id	
	WHERE s.is_primary_key =1 and o.object_id >= 100 AND o.is_ms_shipped = 0 AND s.type > 0 /* Not Heap */
END
GO
/* Create FK */

IF $(PCinIndex) = 1
BEGIN
	SELECT 'ALTER TABLE [' + OBJECT_SCHEMA_NAME(f.parent_object_id) + '].[' + OBJECT_NAME(f.parent_object_id) + '] WITH CHECK ADD CONSTRAINT [' + 
		OBJECT_NAME(f.object_id) + '] FOREIGN KEY (' +
		-- Column list in the refering table 		
			(SELECT 
		REPLACE(
		REPLACE( -- Replacing XML Tag by ,
		REPLACE(
		CAST(
		(SELECT a.name as 'Column'
		FROM sys.foreign_key_columns i INNER JOIN sys.all_columns a 
		ON i.parent_object_id = a.object_id AND i.parent_column_id = a.column_id 
		WHERE i.parent_object_id = f.parent_object_id
		AND f.object_id = i.constraint_object_id
		ORDER BY i.constraint_object_id
		FOR XML PATH('')) as nvarchar(max))
		, '</Column><Column>', ','), '</Column>',''), '<Column>','')
		) + ')'
		+ ' REFERENCES [' + OBJECT_SCHEMA_NAME(f.referenced_object_id) + '].[' + OBJECT_NAME(f.referenced_object_id) + '](' + 
		-- Column list in the referenced table	
			(SELECT 
		REPLACE(
		REPLACE( -- Replacing XML Tag by ,
		REPLACE(
		CAST(
		(SELECT  a.name as 'Column'
		FROM sys.foreign_key_columns i INNER JOIN sys.all_columns a 
		ON i.referenced_object_id = a.object_id AND i.referenced_column_id = a.column_id 
		WHERE i.parent_object_id = f.parent_object_id
		AND f.object_id = i.constraint_object_id
		ORDER BY i.constraint_object_id
		FOR XML PATH('')) as nvarchar(max))
		, '</Column><Column>', ','), '</Column>',''), '<Column>','')
		) + ') ' + CASE WHEN f.delete_referential_action = 0 THEN '' 
					WHEN f.delete_referential_action = 1 THEN 'ON DELETE CASCADE' 
					WHEN f.delete_referential_action = 2 THEN 'ON DELETE SET_NULL' 
					WHEN f.delete_referential_action = 3 THEN 'ON DELETE SET_DEFAULT' 
					ELSE '' END + ' '+ 
					+ CASE WHEN f.update_referential_action = 0 THEN '' 
					WHEN f.update_referential_action = 1 THEN 'ON UPDATE CASCADE' 
					WHEN f.update_referential_action = 2 THEN 'ON UPDATE SET_NULL' 
					WHEN f.update_referential_action = 3 THEN 'ON UPDATE SET_DEFAULT' 
					ELSE '' END + ' ; ' + 
		-- Check constraint 
		'ALTER TABLE [' + OBJECT_SCHEMA_NAME(f.parent_object_id) + '].[' + OBJECT_NAME(f.parent_object_id) + '] CHECK CONSTRAINT [' + OBJECT_NAME(f.object_id) + '];'AS 'Recreate FK'
	FROM sys.foreign_keys f 
END 
ELSE
BEGIN
	SELECT 'ALTER TABLE [' + OBJECT_SCHEMA_NAME(f.parent_object_id) + '].[' + OBJECT_NAME(f.parent_object_id) + '] WITH CHECK ADD CONSTRAINT [' + 
		OBJECT_NAME(f.object_id) + '] FOREIGN KEY (' +
		-- Column list in the refering table 		
			(SELECT 
		REPLACE(
		REPLACE( -- Replacing XML Tag by ,
		REPLACE(
		CAST(
		(SELECT a.name as 'Column'
		FROM sys.foreign_key_columns i INNER JOIN sys.all_columns a 
		ON i.parent_object_id = a.object_id AND i.parent_column_id = a.column_id 
		WHERE i.parent_object_id = f.parent_object_id
		AND f.object_id = i.constraint_object_id
		AND i.parent_column_id not in (SELECT column_id FROM  sys.index_columns id WHERE i.parent_object_id = id.object_id and partition_ordinal = 1)
		AND i.referenced_column_id not in (SELECT column_id FROM  sys.index_columns id  WHERE f.referenced_object_id = id.object_id and f.key_index_id = id.index_id and partition_ordinal = 1)
		ORDER BY i.constraint_object_id
		FOR XML PATH('')) as nvarchar(max))
		, '</Column><Column>', ','), '</Column>',''), '<Column>','')
		) + ')'
		+ ' REFERENCES [' + OBJECT_SCHEMA_NAME(f.referenced_object_id) + '].[' + OBJECT_NAME(f.referenced_object_id) + '](' + 
		-- Column list in the referenced table	
			(SELECT 
		REPLACE(
		REPLACE( -- Replacing XML Tag by ,
		REPLACE(
		CAST(
		(SELECT  a.name as 'Column'
		FROM sys.foreign_key_columns i INNER JOIN sys.all_columns a 
		ON i.referenced_object_id = a.object_id AND i.referenced_column_id = a.column_id 
		WHERE i.parent_object_id = f.parent_object_id
		AND f.object_id = i.constraint_object_id
		AND i.referenced_column_id not in (SELECT column_id FROM  sys.index_columns i WHERE f.referenced_object_id = i.object_id and f.key_index_id = i.index_id and partition_ordinal = 1)
		ORDER BY i.constraint_object_id
		FOR XML PATH('')) as nvarchar(max))
		, '</Column><Column>', ','), '</Column>',''), '<Column>','')
		) + ') ' + CASE WHEN f.delete_referential_action = 0 THEN '' 
					WHEN f.delete_referential_action = 1 THEN 'ON DELETE CASCADE' 
					WHEN f.delete_referential_action = 2 THEN 'ON DELETE SET_NULL' 
					WHEN f.delete_referential_action = 3 THEN 'ON DELETE SET_DEFAULT' 
					ELSE '' END + ' '+ 
					+ CASE WHEN f.update_referential_action = 0 THEN '' 
					WHEN f.update_referential_action = 1 THEN 'ON UPDATE CASCADE' 
					WHEN f.update_referential_action = 2 THEN 'ON UPDATE SET_NULL' 
					WHEN f.update_referential_action = 3 THEN 'ON UPDATE SET_DEFAULT' 
					ELSE '' END + ' ; ' + 
		-- Check constraint 
		'ALTER TABLE [' + OBJECT_SCHEMA_NAME(f.parent_object_id) + '].[' + OBJECT_NAME(f.parent_object_id) + '] CHECK CONSTRAINT [' + OBJECT_NAME(f.object_id) + '];'AS 'Recreate FK'
	FROM sys.foreign_keys f 
END
GO
--Heap
SELECT 'CREATE CLUSTERED INDEX '+ ISNULL(s.NAME, 'TEMP_For_Heap') + ' ON [' + OBJECT_SCHEMA_NAME(s.object_id) + '].[' + OBJECT_NAME(s.object_id) + '] ' +
	-- columns to be in the index
'(' + 
	(SELECT TOP 1 a.name + ' ASC' as 'Column'
	FROM sys.all_columns a 
	WHERE a.object_id = s.object_id) 
	+')'
		-- WITH Section
		+ ' WITH (SORT_IN_TEMPDB = ON) ' + 
		-- FILEGROUP Section
		'ON [Data]; DROP INDEX '+ ISNULL(s.NAME, 'TEMP_For_Heap') + ' ON [' + OBJECT_SCHEMA_NAME(s.object_id) + '].[' + OBJECT_NAME(s.object_id) + '];' AS 'Move table with HEAP IDX'
FROM sys.indexes s INNER JOIN sys.all_objects o
	ON o.object_id = s.object_id	
WHERE s.is_primary_key =0 and o.object_id >= 100 AND o.is_ms_shipped = 0 AND index_id = 0 and O.type = 'U'
GO

SELECT  'States Of filegroups'as 'object Name' ,'' as'Type',''as 'Index Name',''as 'Index Id',''as 'Filegroup Name' 
UNION ALL 
SELECT o.[name]as 'object Name', o.[type]as'Type', i.[name]as 'Index Name', i.[index_id]as 'Index Id', f.[name]as 'Filegroup Name' 
FROM sys.indexes i
INNER JOIN sys.filegroups f
ON i.data_space_id = f.data_space_id
INNER JOIN sys.all_objects o
ON i.[object_id] = o.[object_id]
WHERE i.data_space_id = f.data_space_id
--AND o.type = 'U' -- User Created Tables
AND f.name not in ('PRIMARY', 'Data','INDEX')
GO
-- Effacement des cl?s de partitionnement:
SELECT 'DROP PARTITION SCHEME [' + name + ']'  as 'DROP PARTITION SCHEME'
FROM sys.partition_schemes
GO
SELECT 'DROP PARTITION FUNCTION [' + name + ']'  as 'DROP PARTITION FUNCTION'
FROM sys.partition_functions
GO
-- les Files et filegroups
SELECT 'DBCC SHRINKFILE (N''' + f.name + ''',EMPTYFILE); ALTER DATABASE [' + DB_NAME() + ']  REMOVE FILE [' + f.name + ']' as 'Remove unused Data File'  
FROM sys.data_spaces s INNER JOIN sys.database_files f ON s.data_space_id = f.data_space_id
where f.data_space_id in (SELECT data_space_id FROM sys.data_spaces a
WHERE NOT EXISTS (SELECT ds.data_space_id
					FROM sys.data_spaces AS DS 
					INNER JOIN sys.allocation_units AS AU ON DS.data_space_id = AU.data_space_id 
					INNER JOIN sys.partitions AS PA ON (AU.type IN (1, 3) AND AU.container_id = PA.hobt_id) OR (AU.type = 2 AND AU.container_id = PA.partition_id) 
					INNER JOIN sys.objects AS OBJ ON PA.object_id = OBJ.object_id 
					INNER JOIN sys.schemas AS SCH ON OBJ.schema_id = SCH.schema_id 
					LEFT JOIN sys.indexes AS IDX  ON PA.object_id = IDX.object_id AND PA.index_id = IDX.index_id 
					WHERE a.data_space_id = ds.data_space_id )
					and  a.type ='FG')

SELECT 'ALTER DATABASE '+db_name()+' REMOVE FILEGROUP '+ name as 'Remove filegroup withoutfile' 
FROM sys.filegroups a
where data_space_id not in 
			(SELECT data_space_id FROM sys.database_files b
			where a.data_space_id = b.data_space_id)

SELECT 'DBCC SHRINKFILE ('''+[Name]+''','+LEFT(convert(nvarchar(12),([Space_Used_MB]+5)),CHARINDEX ('.',convert(nvarchar(12),([Space_Used_MB]+5)))-1) +')' as 'SHRINKFILE with good disk space (Data space + 5mb)'
FROM(SELECT [FileID], [File_Size_MB] = convert(decimal(12,2),round([size]/128.000,2)),
[Space_Used_MB] = convert(decimal(12,2),fileproperty([name],'SpaceUsed')/128.000),
[Free_Space_MB] = convert(decimal(12,2),([size]-fileproperty([name],'SpaceUsed'))/128.000) ,
[Name], [FileName], convert(datetime,Getdate(),112) as DateInserted
from dbo.sysfiles)A
where convert(decimal(12,2),(100*[Space_Used_MB]/ [File_Size_MB])) < 90