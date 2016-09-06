DROP TABLE Expenditure.PaymentSource;

CREATE TABLE Expenditure.PaymentSource(
	`Code`    varchar(20) NULL,
	`Account` varchar(20) NULL,
	`Type`    varchar(20) NULL,
	`Comment` varchar(1000) NULL,
	PRIMARY KEY(`Code`)
);

INSERT Expenditure.PaymentSource(`Code`, `Account`, `Type`) Values ('Cash',   NULL, NULL);
INSERT Expenditure.PaymentSource(`Code`, `Account`, `Type`) Values ('HCCSO', 'HF1', 'Standing Order');
INSERT Expenditure.PaymentSource(`Code`, `Account`, `Type`) Values ('HCCDD', 'HF1', 'Direct Debit');
INSERT Expenditure.PaymentSource(`Code`, `Account`, `Type`) Values ('HCCDC', 'HF1', 'Debit Card');
INSERT Expenditure.PaymentSource(`Code`, `Account`, `Type`) Values ('HCCCH', 'HF1', 'Cheque');
INSERT Expenditure.PaymentSource(`Code`, `Account`, `Type`) Values ('SJNSO', 'SN1', 'Standing Order');
INSERT Expenditure.PaymentSource(`Code`, `Account`, `Type`) Values ('SJNDD', 'SN1', 'Direct Debit');
INSERT Expenditure.PaymentSource(`Code`, `Account`, `Type`) Values ('SJNCC', 'SN2', 'Credit Card');
INSERT Expenditure.PaymentSource(`Code`, `Account`, `Type`) Values ('SRCSO', 'SN3', 'Standing Order');
INSERT Expenditure.PaymentSource(`Code`, `Account`, `Type`) Values ('SRCDD', 'SN3', 'Direct Debit');
INSERT Expenditure.PaymentSource(`Code`, `Account`, `Type`) Values ('SRCDC', 'SN3', 'Debit Card');