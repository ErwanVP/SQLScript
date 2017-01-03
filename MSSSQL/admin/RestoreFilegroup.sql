DECLARE @PWD nvarchar(30) = 'media password'
DECLARE @Databasepath nvarchar(200)= 'z:\backup\backup.bak'

DECLARE  @sqlcmd nvarchar(max)

SET @sqlcmd ='RESTORE FILELISTONLY  FROM DISK =  '''+@Databasepath +'''
WITH MEDIAPASSWORD = '''+@PWD+'''';

declare @fileListTable table
(
    LogicalName          nvarchar(128),
    PhysicalName         nvarchar(260),
    [Type]               char(1),
    FileGroupName        nvarchar(128),
    Size                 numeric(20,0),
    MaxSize              numeric(20,0),
    FileID               bigint,
    CreateLSN            numeric(25,0),
    DropLSN              numeric(25,0),
    UniqueID             uniqueidentifier,
    ReadOnlyLSN          numeric(25,0),
    ReadWriteLSN         numeric(25,0),
    BackupSizeInBytes    bigint,
    SourceBlockSize      int,
    FileGroupID          int,
    LogGroupGUID         uniqueidentifier,
    DifferentialBaseLSN  numeric(25,0),
    DifferentialBaseGUID uniqueidentifier,
    IsReadOnl            bit,
    IsPresent            bit,
    TDEThumbprint        varbinary(32) -- remove this column if using SQL 2005
)
insert into @fileListTable 
exec (@sqlcmd)

SELECT ',MOVE '''+ RTRIM(LogicalName) + ''' TO ''' + REPLACE( RTRIM(PhysicalName),'source path','destination path') +''''  FROM @fileListTable 
where FileGroupName like 'FG_InfosChanges%' 

SELECT DISTINCT (FileGroupName) FROM @fileListTable 
where FileGroupName like 'FG_InfosChanges%' 

RESTORE DATABASE adb FILEGROUP='FG_InfosChanges_2004',FILEGROUP='FG_InfosChanges_2005',FILEGROUP='FG_InfosChanges_2006',
FILEGROUP='FG_InfosChanges_IDX_2004',FILEGROUP='FG_InfosChanges_IDX_2005',FILEGROUP='FG_InfosChanges_IDX_2006'
   FROM DISK = @Databasepath 
,PARTIAL, RECOVERY,MEDIAPASSWORD = @PWD;