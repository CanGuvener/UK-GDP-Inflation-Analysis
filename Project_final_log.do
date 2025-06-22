clear

*Memory adjustments are made automatically in this version of stata, so setting memory is not needed


*changing directory
cd "C:\Users\ceyci\OneDrive\Masaüstü"


*opening log file
log using project.log, replace



*opening our dataset
*the data is obtained quarterly by Office of National Statistics 
use "C:\Users\ceyci\OneDrive\Masaüstü\Study\STATA docs\project_variables_clean_01.03.dta"

	

*seasonally adjusted quarterly gdp is used for gdp values
*https://fred.stlouisfed.org
sum gdp 


*RPI values are used for inflation rates
*https://www.ons.gov.uk/economy/inflationandpriceindices/timeseries/doge/mm23
sum inflation 


*For quarterly interest rates, the average of 3 monthly interest rates are used
*https://www.bankofengland.co.uk/monetary-policy/the-interest-rate-bank-rate
sum interest 


*obtained by Office of National Statistics
*https://www.ons.gov.uk/employmentandlabourmarket/peoplenotinwork/unemployment/timeseries/mgsx/lms
sum unemp


*quarterly trade balance is calcualted by substracting the imports by the exports
*units are seasonally adjusted and in £ million 
*https://www.ons.gov.uk/economy/nationalaccounts/balanceofpayments/datasets/uktradegoodsandservicespublicationtables 
sum trade 


*Gross fixed capital formation is used, £ million 
*https://www.ons.gov.uk/economy/grossdomesticproductgdp/datasets/grossfixedcapitalformationbysectorandasset
sum capital


*numeric value for each quarter to define the data as time series
sum time 


*checking if there are any missing values 
codebook gdp inflation interest unemp trade capital





*generating the explanained variable ln(gdp)
*It is appropriate for this model, to use a logarithm for gdp; it normalizes the data, helps interpreting the coefficient in terms of percentage which is suitable for observing the changes in the data 
gen gdp_log = log(gdp)




*generating trade balance as a percentage of gdp, to use as a explanatory variable; a standard way of the measure, provides a relative measure of the importance of the trade balance to the economy, it is also the appropriate way of use for policy making. 
gen trade_gdp = trade/gdp 



*Labelling new variables
label variable gdp_log "ln(GDP)"
label variable trade_gdp "Trade Balance / GDP"




*having a look to the inflation and gdp values graphically, to generate a basic idea
graph twoway lowess inflation gdp_log




*Doing the regression

*ln(gdp) = B0 + B1*inflation_rate + B2*interest_rate + B3*unemployment_rate + B4*trade_balance/gdp + B5*gross_fixed_capital_formation

*The chosen model is consistent with the literature on economic growth, and variable relevance
regress gdp_log inflation interest unemp trade_gdp capital


*Checking for multicollinearity with a VIF test
vif
*Since the VIF value is bigger than 10 for capital, there is multicollinearity present


*Checking multicollinearity again with the correlation matrix, to see the problem more clearly
pwcorr inflation unemp interest trade_gdp capital, sig
*As we can see from a(5,2) = -0.8971, there is evidence of multicollinearity between unemployment rate and gross fixed capital formation.

*Since they are both capital variables, we should eliminate one to prevent multicollinearity.  

*Doing the regression without unemployment 
regress gdp_log inflation interest trade_gdp capital

*Our new model is: 
*ln(gdp) = B0 + B1*inflation_rate + B2*interest_rate + B3*trade_balance/gdp + B4*gross_fixed_capital_formation

*Since the p-value is smaller than 0.05, we can state that the model is statistically significant at 5% significance level
*The adjusted R-squared value is 0.9035, so we can state that the model explains approximately 90.35% of the variability in the dependent variable
*We can also claim that the causal relation between interest rate and GDP growth is insignificant at 5% significance level, since the t-value for interest is 0.57 which is lower than 1.96
*For the rest of the explanatory variables (inflation rate, trade balance, gross fixed capital formation), the the relationship is significant at 5%, according to each t-value. 


vif
*There is no multicollinearity in the new model, according to the VIF test



*Using Ramsey REST Test to test for omitted-variable bias
ovtest
*Based on the Ramsey REST Test, we do not have sufficient evidence to conclude that the model has omitted variables in 95% confidence interval, since the p-value is greater than the associated F-value


*Using Added Variable plots to check for outliers
avplots
*There are no outliers spotted on the avplots 


*Checking for Heteroskedasticity with a Breush-Pagan Test. Breush-Pagan is predominantly used in the literaure for heteroskedasticity testing. 
estat hettest
*We cannot reject homoskedasticity since the p-value is greater than 0.05, therefore there is no heteroskedasticity problem in the model. 


*time variable is set for Breush-Godfrey Test
tsset time

*Testing for serial correlation with Breush-Godfrey Test 
estat bgodfrey, lags(1)

*there is serial correlation present, since the p-value is smaller than 0.05


	 
*Using the Newey-West HAC method to fix serial correlation
newey gdp_log inflation interest trade_gdp capital, lag(12)
*Inflation is still statistically significant at 95% confidence interval


*Creating a residuals variable to check the normality of residuals
predict e, residuals


*Checking for normality with kernel density plot
kdensity e, normal
*The distribution shows that the assumptions of normality of the residuals is reasonably met




	 
	 
log close


