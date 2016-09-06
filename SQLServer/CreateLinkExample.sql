DECLARE @remote sysname

SET @remote = N'CCLOSE-1\SQLEXPRESSTEST'

EXEC master.dbo.sp_addlinkedserver @server = @remote, @srvproduct=N'SQL Server'
EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=@remote,@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL
EXEC master.dbo.sp_serveroption @server=@remote, @optname=N'collation compatible', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=@remote, @optname=N'data access', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=@remote, @optname=N'dist', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=@remote, @optname=N'pub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=@remote, @optname=N'rpc', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=@remote, @optname=N'rpc out', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=@remote, @optname=N'sub', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=@remote, @optname=N'connect timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=@remote, @optname=N'collation name', @optvalue=null
EXEC master.dbo.sp_serveroption @server=@remote, @optname=N'lazy schema validation', @optvalue=N'false'
EXEC master.dbo.sp_serveroption @server=@remote, @optname=N'query timeout', @optvalue=N'0'
EXEC master.dbo.sp_serveroption @server=@remote, @optname=N'use remote collation', @optvalue=N'true'
EXEC master.dbo.sp_serveroption @server=@remote, @optname=N'remote proc transaction promotion', @optvalue=N'true'
GO





