USE [master]
GO
-- This turns on advanced options and is needed to configure xp_cmdshell
EXEC sp_configure 'show advanced options', '1'
RECONFIGURE
-- The following is required to allow the task script sqlsvrbackup.bat to run.
EXEC sp_configure 'xp_cmdshell', '1' 
RECONFIGURE
/*
 * This modifies the provider MSDASQL in Linked Servers Providers. Don't know why this is necessary, but without it
 * the queries accessing MySQL database fail.
 */
EXEC master.dbo.sp_MSset_oledb_prop N'MSDASQL', N'LevelZeroOnly', 1
GO
/****** Object:  LinkedServer [MYSQL]    Script Date: 23/05/2023 09:26:18 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'MYSQL', @srvproduct=N'MYSQL Database', @provider=N'MSDASQL', @datasrc=N'MYSQL'
GO 
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'MYSQL',@useself=N'False',@locallogin=NULL,@rmtuser=N'appuser',@rmtpassword='ap-qr01'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQL', @optname=N'collation compatible', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQL', @optname=N'data access', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQL', @optname=N'dist', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQL', @optname=N'pub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQL', @optname=N'rpc', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQL', @optname=N'rpc out', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQL', @optname=N'sub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQL', @optname=N'connect timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQL', @optname=N'collation name', @optvalue=null
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQL', @optname=N'lazy schema validation', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQL', @optname=N'query timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQL', @optname=N'use remote collation', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQL', @optname=N'remote proc transaction promotion', @optvalue=N'true'
GO

/****** Object:  LinkedServer [MYSQLBP]    Script Date: 23/05/2023 09:26:49 ******/
EXEC master.dbo.sp_addlinkedserver @server = N'MYSQLBP', @srvproduct=N'MYSQL Database', @provider=N'MSDASQL', @datasrc=N'MYSQLBp'
GO
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'MYSQLBP',@useself=N'False',@locallogin=NULL,@rmtuser=N'appuser',@rmtpassword='ap-qr01'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQLBP', @optname=N'collation compatible', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQLBP', @optname=N'data access', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQLBP', @optname=N'dist', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQLBP', @optname=N'pub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQLBP', @optname=N'rpc', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQLBP', @optname=N'rpc out', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQLBP', @optname=N'sub', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQLBP', @optname=N'connect timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQLBP', @optname=N'collation name', @optvalue=null
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQLBP', @optname=N'lazy schema validation', @optvalue=N'false'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQLBP', @optname=N'query timeout', @optvalue=N'0'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQLBP', @optname=N'use remote collation', @optvalue=N'true'
GO
EXEC master.dbo.sp_serveroption @server=N'MYSQLBP', @optname=N'remote proc transaction promotion', @optvalue=N'true'
GO

