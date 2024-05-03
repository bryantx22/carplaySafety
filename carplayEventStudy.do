clear all
cls
set maxvar 30000
use "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\08_22_merged_vehicle.dta", clear

// Main Specification

/*
Main specification setup:

1. Only include deaths where |year - mod_year| <= 2
2. Collapse into (i, \tau), where i is a specific car model (Audi A4) and \tau is model year

Potentially do something like driver's sex as a balance test?
*/

// collapsing to (makeid, modelid, model year)
replace prev_acc = 0 if missing(prev_acc) | prev_acc > 97
drop if mod_year > 2020 | mod_year < 2005
drop if missing(year)
drop if missing(mod_year)
gen abs_diff = abs(year - mod_year)
drop if abs_diff > 2
drop if missing(makeid)
drop if missing(modelid)

collapse (sum) total_deaths (mean) prev_acc, by (makeid modelid mod_year)
save "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\deaths_collapsed_makeModel.dta", replace 

// processing apple's list
import delimited "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\apple_vin.csv", clear 

replace start = 2017 if start == 2017.5 // Nissan - Murano (actually 2017.5; https://www.apple.com/ios/carplay/available-models/)
drop if modelids == -1 | makeids == -1
drop if fuzzy_score < 85

rename makeids makeid
rename modelids modelid

sort makeid modelid
quietly by makeid modelid:  gen dup = cond(_N==1,0,_n)
drop if dup > 1 // some are repeated because the same model shows up again when it supports "keys" (e.g. BMW i3 on Apple's site)
drop dup

save "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\apple_cleaned.dta", replace

// event study - main specification
merge 1:m makeid modelid using "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\deaths_collapsed_makeModel.dta"

drop if _merge == 1 // from Apple's list; not involved in accidents
gen l_deaths = log(total_deaths)
egen carid = group(makeid modelid)
gen timeToTreat = mod_year - start
replace timeToTreat = . if start > 2020 // last model year is 2019

xtset carid mod_year // not necessary

local depvars total_deaths l_deaths prev_acc
local names "Deaths Log_Deaths Avg_Priors"

forvalues i = 1/3{
	
	local depvar : word `i' of `depvars'
	local name : word `i' of `names'
	
	// no trend
	qui: reghdfe `depvar', absorb(i.mod_year#i.makeid i.carid)
	qui: egen treatment_baseline = mean(`depvar') if e(sample) == 1 & timeToTreat == -1 // get sample; eventdd does not support this
	qui: sum(treatment_baseline) // sum treatment gp's baseline
	local mean_bl = r(mean)
	qui: eventdd `depvar', hdfe absorb(i.mod_year#i.makeid i.carid) accum leads(5) lags(4) timevar(timeToTreat) ci(rcap) cluster(carid) graph_op(caption("Note: The average of the treatment group at t = -1 is `mean_bl'") xtitle("Event Time") ytitle("`name'"))
	qui: graph export "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\newFigures\tau_`depvar'NoTrend.png", as(jpg) width(16000) replace
	drop treatment_baseline

	// linear trend
	qui: reghdfe `depvar', absorb(i.mod_year#i.makeid i.carid i.carid#c.mod_year)
	qui: egen treatment_baseline = mean(`depvar') if e(sample) == 1 & timeToTreat == -1
	qui: sum(treatment_baseline)
	local mean_bl = r(mean)
	qui: eventdd `depvar', hdfe absorb(i.mod_year#i.makeid i.carid i.carid#c.mod_year) accum leads(5) lags(4) timevar(timeToTreat) ci(rcap) cluster(carid) graph_op(caption("Note: The average of the treatment group at t = -1 is `mean_bl'") xtitle("Event Time") ytitle("`name'"))
	qui: graph export "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\newFigures\tau_`depvar'Trend.png", as(jpg) width(16000) replace
	drop treatment_baseline
}

// Sun and Abraham:
gen control = missing(start)

// leads and lags
gen F_5 = (timeToTreat <= -5)
gen L_4 = (timeToTreat >= 4)
forvalues i=2/4{
	gen F_`i' = (timeToTreat == -1 * `i')
}
forvalues i=0/3{
	gen L_`i' = (timeToTreat == `i')
}

local depvars total_deaths l_deaths prev_acc
local names "Deaths Log_Deaths Avg_Priors"

forvalues i=1/2{
	
	local depvar : word `i' of `depvars'
	local name : word `i' of `names'
	
	qui: reghdfe `depvar', absorb(i.mod_year#i.makeid i.carid c.mod_year#i.carid)
	eventstudyinteract `depvar' L_* F_* if e(sample)==1, vce(cluster carid) absorb(i.mod_year#i.makeid i.carid c.mod_year#i.carid) cohort(start) control_cohort(control)
	event_plot e(b_iw)#e(V_iw), default_look graph_opt(xtitle("event time") ytitle("`name'") xlabel(-5(1)4)) stub_lag(L_#) stub_lead(F_#) 
	qui: graph export "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\newFigures\tau_SA_`depvar'Trend.png", as(jpg) width(16000) replace
}

// Alternative Specification
clear all
cls
set maxvar 30000
use "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\08_22_merged_vehicle.dta", clear

replace prev_acc = 0 if missing(prev_acc) | prev_acc > 97
drop if mod_year >= 9998 | mod_year < 2005
drop if missing(makeid)
drop if missing(modelid)
drop if missing(year)

collapse (sum) total_deaths deaths (mean) prev_acc, by (year modelid makeid)
save "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\deaths_collapsed_makeModelTime.dta", replace

use "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\apple_cleaned.dta", clear

merge 1:m makeid modelid using "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\deaths_collapsed_makeModelTime.dta"
drop if _merge == 1

gen timeToTreat = year - start
replace timeToTreat = . if start > 2022
egen carid = group(makeid modelid)
gen l_deaths = log(total_deaths)

local depvars total_deaths l_deaths prev_acc
local names "Deaths Log_Deaths Avg_Priors"

forvalues i = 1/3{
	
	local depvar : word `i' of `depvars'
	local name : word `i' of `names'
	
	// no trend
	qui: reghdfe `depvar', absorb(i.year#i.makeid i.carid)
	qui: egen treatment_baseline = mean(`depvar') if e(sample) == 1 & timeToTreat == -1 // get sample; eventdd does not support this
	qui: sum(treatment_baseline) // sum treatment gp's baseline
	local mean_bl = r(mean)
	qui: eventdd `depvar', hdfe absorb(i.year#i.makeid i.carid) accum leads(5) lags(4) timevar(timeToTreat) ci(rcap) cluster(carid) graph_op(caption("Note: The average of the treatment group at t = -1 is `mean_bl'") xtitle("Event Time") ytitle("`name'"))
	qui: graph export "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\newFigures\yr_`depvar'NoTrend.png", as(jpg) width(16000) replace
	drop treatment_baseline

	// linear trend
	qui: reghdfe `depvar', absorb(i.year#i.makeid i.carid i.carid#c.year)
	qui: egen treatment_baseline = mean(`depvar') if e(sample) == 1 & timeToTreat == -1
	qui: sum(treatment_baseline)
	local mean_bl = r(mean)
	qui: eventdd `depvar', hdfe absorb(i.year#i.makeid i.carid i.carid#c.year) accum leads(5) lags(4) timevar(timeToTreat) ci(rcap) cluster(carid) graph_op(caption("Note: The average of the treatment group at t = -1 is `mean_bl'") xtitle("Event Time") ytitle("`name'"))
	qui: graph export "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\newFigures\yr_`depvar'Trend.png", as(jpg) width(16000) replace
	drop treatment_baseline
}

// Sun and Abraham:
gen control = missing(start)

// leads and lags
gen F_5 = (timeToTreat <= -5)
gen L_4 = (timeToTreat >= 4)
forvalues i=2/4{
	gen F_`i' = (timeToTreat == -1 * `i')
}
forvalues i=0/3{
	gen L_`i' = (timeToTreat == `i')
}

local depvars total_deaths l_deaths prev_acc
local names "Deaths Log_Deaths Avg_Priors"

forvalues i=1/2{
	
	local depvar : word `i' of `depvars'
	local name : word `i' of `names'
	
	qui: reghdfe `depvar', absorb(i.year#i.makeid i.carid c.year#i.carid)
	eventstudyinteract `depvar' L_* F_* if e(sample)==1, vce(cluster carid) absorb(i.year#i.makeid i.carid c.year#i.carid) cohort(start) control_cohort(control)
	event_plot e(b_iw)#e(V_iw), default_look graph_opt(xtitle("event time") ytitle("`name'") xlabel(-5(1)4)) stub_lag(L_#) stub_lead(F_#) 
	qui: graph export "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\newFigures\tau_SA_`depvar'Trend.png", as(jpg) width(16000) replace
}