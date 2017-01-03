EXEC msdb.dbo.sysmail_help_account_sp

EXEC msdb.dbo.sysmail_help_configure_sp

EXEC msdb.dbo.sysmail_help_principalprofile_sp;

EXEC msdb.dbo.sysmail_help_profile_sp

EXEC msdb.dbo.sysmail_help_profileaccount_sp

/* Sample create account and profile */

-- Create a Database Mail account
EXECUTE msdb.dbo.sysmail_add_account_sp
    @account_name = 'test account using SMTP1',
    @description = 'Mail account for test',
    @email_address = 'test@test.fr',
    @replyto_address = '',
    @display_name = 'test@test.fr',
    @mailserver_name = 'SMTP1 server';

-- Create profile
EXECUTE msdb.dbo.sysmail_add_profile_sp
    @profile_name = 'test@test.fr',
    @description = 'test@test.fr';

-- Add the account to the profile
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'test@test.fr',
    @account_name = 'test account using SMTP1',
    @sequence_number = '1';

-- add a second account using a different smtp server*/
EXECUTE msdb.dbo.sysmail_add_account_sp
    @account_name = 'test account using SMTP2',
    @description = 'Mail account for test',
    @email_address = 'test@test.fr',
    @replyto_address = '',
    @display_name = 'test@test.fr',
    @mailserver_name = 'SMTP2 server';

-- Add the account to the profile
EXECUTE msdb.dbo.sysmail_add_profileaccount_sp
    @profile_name = 'test@test.fr',
    @account_name = 'test account using SMTP2',
    @sequence_number = '2';

-- Grant access to the profile to all msdb database users
-- Grant access to the profile to all msdb database users
EXECUTE msdb.dbo.sysmail_add_principalprofile_sp
    @profile_name = 'test@test.fr',
    @principal_name = 'public',
    @is_default = '0';
GO