SELECT p.name , wg.name,* FROM sys.dm_resource_governor_resource_pools p with (nolock)
inner join sys.dm_resource_governor_workload_groups wg with (nolock) ON P.pool_id = WG.pool_id