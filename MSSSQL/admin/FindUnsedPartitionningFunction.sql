SELECT *
FROM sys.partition_schemes a
where data_space_id not in (
SELECT psch.data_space_id
FROM sys.partitions part
INNER JOIN sys.indexes idx ON idx.[object_id] = part.[object_id] and idx.index_id = part.index_id
INNER JOIN sys.data_spaces dsp ON dsp.data_space_id = idx.data_space_id
INNER JOIN sys.partition_schemes psch ON psch.data_space_id = dsp.data_space_id
where psch.data_space_id = a.data_space_id)


SELECT* FROM  sys.partition_functions a
where function_id not in 
(SELECT pfun.function_id
FROM sys.partitions part
INNER JOIN sys.indexes idx ON idx.[object_id] = part.[object_id] and idx.index_id = part.index_id
INNER JOIN sys.data_spaces dsp ON dsp.data_space_id = idx.data_space_id
INNER JOIN sys.partition_schemes psch ON psch.data_space_id = dsp.data_space_id
INNER JOIN sys.partition_functions pfun ON pfun.function_id = psch.function_id
WHERE pfun.function_id =a.function_id )