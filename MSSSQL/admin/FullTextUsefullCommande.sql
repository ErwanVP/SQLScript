GO
/* Create catalog*/
CREATE FULLTEXT CATALOG catalog
WITH ACCENT_SENSITIVITY = OFF

/* Create Stoplist base on sytem stoplist*/
GO
CREATE FULLTEXT STOPLIST [StoplistName]
FROM SYSTEM STOPLIST;

GO
/* Drop some value */
ALTER FULLTEXT STOPLIST [StoplistName] DROP '0' LANGUAGE 'Neutral';
GO
ALTER FULLTEXT STOPLIST [StoplistName] DROP '2' LANGUAGE 'Neutral';
GO
ALTER FULLTEXT STOPLIST [StoplistName] DROP '3' LANGUAGE 'Neutral';
GO
ALTER FULLTEXT STOPLIST [StoplistName] DROP '4' LANGUAGE 'Neutral';
GO
ALTER FULLTEXT STOPLIST [StoplistName] DROP '5' LANGUAGE 'Neutral';
GO
ALTER FULLTEXT STOPLIST [StoplistName] DROP '6' LANGUAGE 'Neutral';
GO
ALTER FULLTEXT STOPLIST [StoplistName] DROP '7' LANGUAGE 'Neutral';
GO
ALTER FULLTEXT STOPLIST [StoplistName] DROP '8' LANGUAGE 'Neutral';
GO
ALTER FULLTEXT STOPLIST [StoplistName] DROP '9' LANGUAGE 'Neutral';
GO

/* you can also drop all ^^ */
ALTER FULLTEXT STOPLIST eutx_Stoplist
DROP ALL ;

GO
/* Create anindex fulltext with system stoplist*/ 
CREATE FULLTEXT INDEX ON _My_ProductDocs
(DocSummary, DocContent TYPE COLUMN FileExtension LANGUAGE 1033)
KEY INDEX PK_ProductDocs_DocID
ON My_ProductFTS
WITH STOPLIST = SYSTEM
Go
/* add stop list to an indexe */

ALTER FULLTEXT INDEX ON _My_ProductDocs SET STOPLIST = [StoplistName]

-- info stop list

SELECT * FROM sys.fulltext_stoplists

-- word stoped

SELECT * FROM sys.fulltext_stopwords

--know wich stoplist is used

SELECT * 
FROM 
sys.fulltext_indexes






