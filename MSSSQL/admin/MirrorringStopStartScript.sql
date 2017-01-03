--	print 'stop Sql Agent'
--	exec sp_configure 'agent XPs', 1

/* Resquest for principal server */
SELECT 
	d.name 'Database',
	m.mirroring_role_desc 'MirroringRole',
	m.mirroring_state_desc 'MirroringState',
	m.mirroring_witness_state_desc 'MirroringWitnessState',
	'ALTER DATABASE ' + d.name + ' SET PARTNER SUSPEND' 'SuspendMirror', 
	'ALTER DATABASE ' + d.name + ' SET WITNESS OFF' 'StopMirror', 
	'ALTER DATABASE ' + d.name + ' SET PARTNER RESUME' 'ResumeMirror',
	'ALTER DATABASE ' + d.name + ' SET Witness = ''' + m.mirroring_witness_name + '''' 'ReactivateMirror',
	'ALTER DATABASE ' + d.name + ' SET PARTNER TIMEOUT 30' 'SetTimeoutMirror'
FROM
	sys.database_mirroring m INNER JOIN
	sys.databases d 
	ON m.database_id = d.database_id 
WHERE 
	m.mirroring_role = 1

/* Query for mirroring server */ 
SELECT 
	d.name 'Database',
	m.mirroring_role_desc 'MirroringRole',
	m.mirroring_state_desc 'MirroringState',
	m.mirroring_witness_state_desc 'MirroringWitnessState',
	'ALTER DATABASE ' + d.name + ' SET PARTNER SUSPEND' 'SuspendMirror', 
	'ALTER DATABASE ' + d.name + ' SET WITNESS OFF' 'StopMirror', 
	'ALTER DATABASE ' + d.name + ' SET PARTNER RESUME' 'ResumeMirror',
	'ALTER DATABASE ' + d.name + ' SET Witness = ''' + m.mirroring_witness_name + '''' 'ReactivateMirror',
	'ALTER DATABASE ' + d.name + ' SET PARTNER TIMEOUT 30' 'SetTimeoutMirror'
FROM
	sys.database_mirroring m INNER JOIN
	sys.databases d 
	ON m.database_id = d.database_id 
WHERE 
	m.mirroring_role = 2

/*suspend and resume script*/
SELECT 
	'ALTER DATABASE ' + d.name + ' SET PARTNER SUSPEND' 'StopMirror', 
	'ALTER DATABASE ' + d.name + ' SET PARTNER RESUME' 'ReactivateMirror',
	d.database_id,
	m.mirroring_witness_state_desc 'State'
FROM
	sys.database_mirroring m INNER JOIN
	sys.databases d 
	ON m.database_id = d.database_id 
WHERE 
	m.mirroring_role = 1