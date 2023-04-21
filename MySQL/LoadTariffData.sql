SELECT * FROM expenditure.tariff ORDER BY Start DESC;

delete from tariff;

INSERT INTO tariff(Name, Type, Start, End, UnitRate, StandingCharge, Description)
SELECT Name, 'Gas', Start, End,  GasRate, GasStandingCharge, Description FROM EnergyRates;
INSERT INTO tariff(Name, Type, Start, End, UnitRate, StandingCharge, Description)
SELECT Name, 'Electric', Start, End,  ElectricRate, ElectricStandingCharge, Description FROM EnergyRates;
