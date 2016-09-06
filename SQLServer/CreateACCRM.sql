DROP TABLE Provider
GO
CREATE TABLE Provider(
	Id		 INT,
	Name     VARCHAR(50) NOT NULL PRIMARY KEY,
	Created  DATETIME DEFAULT dbo.RemoveFractionalSeconds(GETDATE())
)