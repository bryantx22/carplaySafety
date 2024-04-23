clear all
use "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\08_21_merged_vehicle.dta", clear

// figure out which body class are hit from the CarPlay data

gen carplay = .

replace carplay = 0 if bodyclassid == 16 | bodyclassid == 73 | bodyclassid == 11 | bodyclassid == 80 | bodyclassid == 94
replace carplay = 1 if bodyclassid == 10 | bodyclassid == 7 | bodyclassid == 13
drop if missing(carplay)
drop if missing(year)

collapse (sum) deaths (mean) carplay, by(bodyclassid year)

foreach v of numlist 2009/2019{
	gen treat_`v' = (year == `v') * carplay
}

gen treat_lag_pool = (year <= 2008) * carplay
gen treat_lead_pool = (year >= 2019) * carplay

drop treat_2013

gen T = 0
replace T = 1 if carplay == 1 & year >= 2014

// drop treat_2013

gen l_deaths = log(deaths)
regress l_deaths i.carplay i.year treat_*

xtevent l_deaths, panelvar(bodyclassid) timevar(year) policyvar(T) window(-5 5) impute(nuchange) plot