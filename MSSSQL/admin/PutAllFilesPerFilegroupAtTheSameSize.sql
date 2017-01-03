IF object_id('##Temp') is Not null
    DROP TABLE ##Temp
GO
SELECT d.data_space_id, MAX(size) as MAXSize
INTO  ##Temp 
FROM sys.database_files d 
GROUP BY d.data_space_id
GO

SELECT DISTINCT d.MAXSize * 8 / 1024, b.size * 8 / 1024,
'ALTER DATABASE ' + DB_NAME() + ' MODIFY FILE (name = ''' + b.name + ''',SIZE = ' + CAST(d.maxsize * 8 /1024 as nvarchar(10)) + 'MB);' + CHAR(13) 
FROM  ##Temp d inner join sys.database_files b
ON d.data_space_id = b.data_space_id
WHERE  d.Maxsize > b.size AND b.state_desc = 'ONLINE'
 