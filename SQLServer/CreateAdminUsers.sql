USE [master]
GO

/* For security reasons the login is created disabled and with a random password. */
/****** Object:  Login [appuser]    Script Date: 27/06/2023 10:33:54 ******/
CREATE LOGIN [appuser] WITH PASSWORD=N'ap-qr01', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[British], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
GO

ALTER LOGIN [appuser] DISABLE
GO

ALTER SERVER ROLE [sysadmin] ADD MEMBER [appuser]
GO

ALTER SERVER ROLE [securityadmin] ADD MEMBER [appuser]
GO

ALTER SERVER ROLE [serveradmin] ADD MEMBER [appuser]
GO

ALTER SERVER ROLE [setupadmin] ADD MEMBER [appuser]
GO

ALTER SERVER ROLE [processadmin] ADD MEMBER [appuser]
GO

ALTER SERVER ROLE [diskadmin] ADD MEMBER [appuser]
GO

ALTER SERVER ROLE [dbcreator] ADD MEMBER [appuser]
GO

ALTER SERVER ROLE [bulkadmin] ADD MEMBER [appuser]
GO


USE [master]
GO

/****** Object:  Login [DESKTOP-T2V8TQN\ChrisLocal]    Script Date: 27/06/2023 10:35:01 ******/
CREATE LOGIN [DESKTOP-T2V8TQN\ChrisLocal] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[British]
GO

ALTER SERVER ROLE [sysadmin] ADD MEMBER [DESKTOP-T2V8TQN\ChrisLocal]
GO

