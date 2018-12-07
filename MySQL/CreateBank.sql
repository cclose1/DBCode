DROP TABLE IF EXISTS Expenditure.Bank;

CREATE TABLE Expenditure.Bank(
	`Code`          varchar(20) NOT NULL,
	`Bank`          varchar(20) NOT NULL,
	`SortCode`      varchar(8)  NULL,
	`AccountNumber` varchar(20) NULL,
	`Type`          varchar(10) NOT NULL,
	`CardNumber`    varchar(20) NULL,
	`CardType`      varchar(20) NULL,
	`Owner`         varchar(20) NULL,
	`Description`   varchar(50) NULL,
	PRIMARY KEY (`Code`  ASC)
); 
INSERT Expenditure.Bank values ('HF1', 'Halifax',   '110854', '00476796', 'Account', '4462 9140 6944 6719', 'Visa',       'Chris Close', 'Personal');
INSERT Expenditure.Bank values ('HF2', 'Halifax',   '110854', '11456266', 'Account', '4462 9136 0991 5188', 'Visa',       'Chris Close', 'Crypto Dealings');
INSERT Expenditure.Bank values ('HF3', 'Halifax',   '110854', '10264364', 'Account', NULL,                  NULL,         'Robyn Close', 'Personal');
INSERT Expenditure.Bank values ('SN1', 'Santander', '090128', '55360378', 'Account', '4547 4281 4410 8995', 'Visa',       'Joint',       'Household Expenditure');
INSERT Expenditure.Bank values ('SN2', 'Santander', NULL,     NULL,       'Credit',  '5229 4899 6196 6222', 'MasterCard', 'Chris Close', 'Household Credit Card');
INSERT Expenditure.Bank values ('SN3', 'Santander', '090128', '65218889', 'Account', NULL,                  NULL,         'Robyn Close', 'Personal');
INSERT Expenditure.Bank values ('RV1', 'Revolut',   '236972', '06037018', 'Account', '4596 5482 8140 7874', 'Visa',       'Chris Close', 'Personal');
INSERT Expenditure.Bank values ('RV2', 'Revolut',   '236972', '06472777', 'Account', NULL,                  NULL,         'Robyn Close', 'Personal');

