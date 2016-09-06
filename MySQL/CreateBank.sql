DROP TABLE Expenditure.Bank;

CREATE TABLE Expenditure.Bank(
	`Code`          varchar(20) NOT NULL,
	`Bank`          varchar(20) NOT NULL,
	`SortCode`      varchar(8) NULL,
	`AccountNumber` varchar(20) NULL,
	`CardNumber`    varchar(20) NULL,
	`Owner`         varchar(20) NULL,
	PRIMARY KEY (`Code`  ASC)
); 
INSERT Expenditure.Bank values ('HF1', 'Halifax',   '110854', '00476796', '4462 9140 6944 6719', 'Chris Close');
INSERT Expenditure.Bank values ('SN1', 'Santander', '090128', '55360378', '4547 4281 4410 8995', 'Joint');
INSERT Expenditure.Bank values ('SN2', 'Santander', NULL,     NULL,       '5229 4899 6196 6222', 'Chris Close');
INSERT Expenditure.Bank values ('SN3', 'Santander', NULL,     NULL,       NULL,                  'Robyn Close');

