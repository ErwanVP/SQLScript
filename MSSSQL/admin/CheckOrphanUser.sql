
-- list user
USE CarImportDB
GO
sp_change_users_login @Action='Report';
GO

-- remapper  user
GO
sp_change_users_login @Action='update_one', @UserNamePattern='user', @LoginName='login';
GO
