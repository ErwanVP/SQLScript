SELECT * FROM sysmail_allitems (nolock) order by last_mod_date desc --les verifier tout les mails créé avec le status de l'envoit


 SELECT * FROM sysmail_event_log (nolock) order by last_mod_date desc -- verifier si le service a bien demarrré et le message d'erreur


SELECT * FROM sysmail_faileditems (nolock) order by last_mod_date desc -- Les mail qui ont echoué

select * from msdb.dbo.sysmail_unsentitems 



EXEC msdb.dbo.sysmail_help_status_sp; -- verifier si datamail est demarré

EXEC msdb.dbo.sysmail_start_sp; -- lancé les service d'envoit de mail

EXEC msdb.dbo.sysmail_help_queue_sp @queue_type = 'mail' --vérifiez l'état de la file d'attente des messages


/* supression mail */
EXEC msdb.dbo.sysmail_delete_mailitems_sp 
    @sent_before =  '2013-09-11',
    @sent_status = 'unsent';



/* activation queue */
Use MSDB

ALTER QUEUE ExternalMailQueue WITH STATUS = ON

set nocount on

declare @Conversation_handle uniqueidentifier;

declare @message_type nvarchar(256);

declare @counter bigint;

declare @counter2 bigint;

set @counter = (select count(*) from ExternalMailQueue)

set @counter2=0

while (@counter2<=@counter)

begin

receive @Conversation_handle = conversation_handle, @message_type = message_type_name from ExternalMailQueue

set @counter2 = @counter2 + 1

end