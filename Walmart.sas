Filename REFFILE '/home/u44368888/CHARAN_SAS/Walmart_Store_sales.csv';

PROC IMPORT DATAFILE=REFFILE DBMS=CSV OUT=WORK.IMPORT;
	GETNAMES=YES;
RUN;

PROC CONTENTS DATA=WORK.IMPORT;
RUN;

PROC MEANS DATA=IMPORT MEAN STDDEV MIN MAX;
	VAR Weekly_Sales;
	CLASS STORE;
	QUIT;

PROC SQL;
	SELECT * FROM IMPORT;
QUIT;

* Creating an output from PROC MEANS STATEMENT;

PROC MEANS DATA=IMPORT MEAN STDDEV;
	VAR Weekly_Sales;
	Class Store;
	OUTPUT OUT=Statistical_data;
RUN;

PROC SQL;
	CREATE TABLE Statistical_table1 AS SELECT Store, Weekly_Sales as Std_dev from 
		Statistical_data where Store >=1 and _STAT_="STD";
QUIT;

PROC SQL;
	SELECT STORE, Std_dev from Statistical_table1 where Std_dev=(SELECT 
		MAX(Std_dev) from Statistical_table1);
QUIT;

PROC SQL;
	CREATE TABLE Statistical_table2 AS SELECT Store, Weekly_Sales as Mean from 
		Statistical_data where Store >=1 and _STAT_="MEAN";
QUIT;

PROC SQL;
	CREATE TABLE Final_stat as SELECT Statistical_table1.Store, 
		Statistical_table2.Mean, Statistical_table1.Std_dev from Statistical_table1 
		Inner join Statistical_table2 on 
		Statistical_table1.Store=Statistical_table2.Store;
QUIT;

/*  Holiday */
PROC SQL;
	SELECT * from IMPORT;
	RUN;

PROC MEANS DATA=IMPORT;
	VAR Weekly_Sales;
	CLASS Store;
	QUIT;

PROC SQL;
	CREATE TABLE Non_Holiday AS SELECT STORE, AVG(Weekly_Sales) as 
		Non_Holiday_average FROM IMPORT Where Holiday_Flag=0 Group by STORE;
	RUN;

PROC SQL;
	CREATE TABLE Holiday AS SELECT STORE, AVG(Weekly_Sales) as Holiday_average 
		FROM IMPORT Where Holiday_Flag=1 Group by STORE;
	RUN;

DATA Sales_figure;
	SET Non_holiday;
	SET Holiday;
RUN;

PROC SQL;
	CREATE TABLE Final_Sales AS SELECT *, (Holiday_average - Non_Holiday_average) 
		as Final_Sale from Sales_figure;
	RUN;

PROC MEANS DATA=Final_Sales;
	VAR Final_Sale;
	Class Store;
	QUIT;

PROC MEANS DATA=Final_Sales;
	VAR Final_Sale;
	Class Month;
	QUIT;

PROC SQL;
	CREATE TABLE Positive_Sales AS SELECT * FROM Final_Sales where Final_Sale > 0;
	RUN;

PROC MEANS DATA=Positive_Sales;
	VAR Final_Sale;
	Class Store;
	QUIT;

	/* Holiday vs normalweeks */
PROC SQL;
	CREATE TABLE Non_Holiday AS SELECT * FROM IMPORT Where Holiday_Flag=0;
	RUN;

PROC SQL;
	CREATE TABLE Holiday AS SELECT * FROM IMPORT Where Holiday_Flag=1;
	RUN;

PROC SQL;
	CREATE TABLE NonHoliday as SELECT Store, AVG(Weekly_Sales) as Non_holiday_sum 
		from Non_Holiday GROUP BY Store;
QUIT;

PROC SQL;
	CREATE TABLE HolidayDay as SELECT Store, AVG(Weekly_Sales) as Holiday_sum from 
		Holiday GROUP BY Store;
QUIT;

PROC SQL;
	CREATE TABLE Comparison as Select NonHoliday.Store, HolidayDay.Holiday_sum, 
		NonHoliday.Non_holiday_sum from NonHoliday Inner Join HolidayDay on 
		HolidayDay.Store=NonHoliday.Store;
	RUN;

PROC SQL;
	CREATE TABLE Tabular as SELECT Store, (Holiday_sum - Non_holiday_sum) as 
		FinalSales from Comparison;
	RUN;

PROC SQL;
	SELECT * FROM Tabular where FinalSales < 0;
	RUN;
	ods graphics on;

PROC CORR DATA=IMPORT PLOTS=matrix(HISTOGRAM);
	VAR Weekly_Sales CPI Unemployment Fuel_Price;
run;

ods graphics off;

PROC REG DATA=IMPORT;
	MODEL Temperature CPI Unemployment Fuel_Price=Weekly_Sales;
	RUN;

PROC arima DATA=IMPORT;
	IDENTIFY VAR=Weekly_Sales nlag=24;
	RUN;

PROC arima DATA=IMPORT;
	IDENTIFY VAR=Weekly_Sales(1) nlag=24;
	ESTIMATE P=1;
	FORECAST LEAD=6 INTERVAL=MONTH ID=DATE;
	RUN;