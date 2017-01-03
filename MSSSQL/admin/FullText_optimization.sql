http://technet.microsoft.com/fr-fr/library/ms142560.aspx

http://technet.microsoft.com/fr-fr/library/ms189912.aspx


USE master;
GO
EXEC sp_configure 'show advanced option', '1';
GO 
GO 
sp_configure 'max full-text crawl range' ,'8'
RECONFIGURE
-- difiend the nunber of processor