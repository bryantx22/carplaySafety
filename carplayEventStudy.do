clear all
set maxvar 30000

use "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\08_21_merged_vehicle.dta", clear

/*
Main specification setup:

1. Only include deaths where |year - mod_year| <= 2
2. Collapse into (i, \tau), where i is a specific car model (Audi A4) and \tau is model year
*/

replace prev_acc = 0 if missing(prev_acc) | prev_acc > 97 // think about this some more

drop if mod_year > 2019 | mod_year < 2000

drop if missing(year)
drop if missing(mod_year)
gen abs_diff = abs(year - mod_year)
drop if abs_diff > 2

drop if missing(makeid)
drop if missing(modelid)

collapse (sum) total_deaths (mean) prev_acc, by (makeid modelid mod_year)
save "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\deaths_collapsed_makeModel.dta", replace 

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

merge 1:m makeid modelid using "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\deaths_collapsed_makeModel.dta"

drop if _merge == 1 // not involved in accidents
gen l_deaths = log(total_deaths)
egen carid = group(makeid modelid)
gen freq = 1
egen car_count = total(freq), by(carid) 
gen timeToTreat = mod_year - start
replace timeToTreat = . if start > 2019 // last model year is 2019

// drop if start == 2018
// gen T = 0 // switches on for treatment group post treatment
// replace T = 1 if !missing(start) & mod_year >= start

xtset carid mod_year

// matrix results = J(15,2,.)
// matrix colnames results = "Levels" "Logs"
// matrix rownames results = "Pooled <= -4" "se" "-3" "se" "-2" "se" "0" "se" "1" "se" "2" "se" "3" "se" "N"
// local coef_names _k_eq_m4 _k_eq_m3 _k_eq_m2 _k_eq_p0 _k_eq_p1 _k_eq_p2 _k_eq_p3
// debug
// xtevent total_deaths, panelvar(carid) timevar(mod_year) policyvar(T) window(-3 2) impute(instag) plot

eventdd total_deaths, hdfe absorb(i.mod_year#i.makeid i.carid) accum leads(5) lags(3) timevar(timeToTreat) ci(rcap) cluster(carid) 
eventdd total_deaths, hdfe absorb(i.mod_year#i.makeid i.carid i.carid#c.mod_year) accum leads(5) lags(3) timevar(timeToTreat) ci(rcap) cluster(carid)
eventdd total_deaths, hdfe absorb(i.mod_year#i.makeid i.carid i.carid#c.mod_year) timevar(timeToTreat) ci(rcap) cluster(carid)

// xtevent

xtevent prev_acc i.makeid#i.mod_year i.carid#c.mod_year, panelvar(carid) timevar(mod_year) policyvar(T) window(-3 2) impute(instag) note

xteventplot, title("Main Specification - Placebo Test")  caption("Note: The number inside the parentheses report the average of the outcome" "variable for the treated group when the event time is -1.") xtitle("Event Time") ytitle("Avg. Priors of Drivers") scheme(s1mono) 

graph export "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\figures\main_placebo_priors.jpg", as(jpg) name("Graph") quality(100) replace

xtevent total_deaths i.makeid#i.mod_year i.carid#c.mod_year, panelvar(carid) timevar(mod_year) policyvar(T) window(-3 2) impute(instag) note

local counter = 1

forvalues i = 1(2)14 {
	local name `: word `counter' of `coef_names''
	mat results[`i',1] = _b[`name']
	mat results[`i'+1,1] = _se[`name']
	local ++counter
}
mat results[15,1] = e(N)

xteventplot, title("Main Specification with Linear Trends")  caption("Note: The number inside the parentheses report the average of the outcome" "variable for the treated group when the event time is -1.") xtitle("Event Time") ytitle("Total Deaths") scheme(s1mono) 

graph export "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\figures\main_levels_linear.jpg", as(jpg) name("Graph") quality(100) replace

xtevent l_deaths i.makeid#i.mod_year i.carid#c.mod_year, panelvar(carid) timevar(mod_year) policyvar(T) window(-3 2) impute(instag) note

local counter = 1

forvalues i = 1(2)14 {
	local name `: word `counter' of `coef_names''
	mat results[`i',2] = _b[`name']
	mat results[`i'+1,2] = _se[`name']
	local ++counter
}
mat results[15,2] = e(N)

xteventplot, title("Main Specification with Linear Trends")  caption("Note: The number inside the parentheses report the average of the outcome" "variable for the treated group when the event time is -1.") xtitle("Event Time") ytitle("Log Total Deaths") scheme(s1mono) 

graph export "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\figures\main_logs_linear.jpg", as(jpg) name("Graph") quality(100) replace

putexcel set "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\figures\main_spec.xlsx", replace

putexcel A1 = matrix(results), names nformat(number_d2)

// alternative specification

clear all
set maxvar 30000

use "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\08_21_merged_vehicle.dta", clear
replace prev_acc = 0 if missing(prev_acc) | prev_acc > 97 // think about this some more

drop if mod_year < 2000

drop if missing(makeid)
drop if missing(modelid)
drop if missing(year)

collapse (sum) total_deaths (mean) prev_acc, by (year modelid makeid)
save "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\deaths_collapsed_makeModelTime.dta", replace

import delimited "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\apple_vin.csv", clear 

replace start = 2017 if start == 2017.5 // one weird case actually labeled 2017.5
drop if modelids == -1 | makeids == -1
drop if fuzzy_score < 85

rename makeids makeid
rename modelids modelid

sort makeid modelid
quietly by makeid modelid:  gen dup = cond(_N==1,0,_n)

drop if dup > 1

merge 1:m makeid modelid using "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\deaths_collapsed_makeModelTime.dta"

drop if _merge == 1

// gen treatment_gp = 0
// replace treatment_gp = 1 if _merge == 3
// drop if missing(year)
// drop if missing(makeid)
// drop if missing(modelid)
//
// replace start = -1 if missing(start)
//
// gen T = 0
// replace T = 1 if year >= start & start != -1
// egen carid = group(makeid modelid)
// gen l_deaths = log(total_deaths)

replace start = . if start > 2021
gen timeToTreat = year - start
egen carid = group(makeid modelid)
gen l_deaths = log(total_deaths)

eventdd total_deaths, hdfe absorb(i.year#i.makeid i.carid i.carid#c.year) accum leads(5) lags(3) timevar(timeToTreat) ci(rcap) cluster(carid)

eventdd total_deaths, hdfe absorb(i.year#i.makeid i.carid i.carid#c.year) keepbal(carid) leads(5) lags(3) timevar(timeToTreat) ci(rcap) cluster(carid)

eventdd l_deaths, hdfe absorb(i.year#i.makeid i.carid i.carid#c.year) keepbal(carid) leads(5) lags(3) timevar(timeToTreat) ci(rcap) cluster(carid)

eventdd l_deaths, hdfe absorb(i.year#i.makeid i.carid i.carid#c.year) accum leads(5) lags(3) timevar(timeToTreat) ci(rcap) cluster(carid)

xtevent prev_acc i.makeid#i.year i.carid#c.year, panelvar(carid) timevar(year) policyvar(T) window(-9 4) impute(instag) note

xteventplot, title("Alt. Specification - Placebo Test")  caption("Note: The number inside the parentheses report the average of the outcome" "variable for the treated group when the event time is -1.") xtitle("Event Time") ytitle("Avg. Priors of Drivers") scheme(s1mono) 

graph export "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\figures\alt_placebo_priors.jpg", as(jpg) name("Graph") quality(100) replace

matrix results = J(31,2,.)
matrix colnames results = "Levels" "Logs"
matrix rownames results = "Pooled <= -10" "se" "-9" "se" "-8" "se" "-7" "se" "-6" "se" "-5" "se" "-4" "se" "-3" "se" "-2" "se" "0" "se" "1" "se" "2" "se" "3" "se" "4" "se" "5" "se" "N"
local coef_names _k_eq_m10 _k_eq_m9 _k_eq_m8 _k_eq_m7 _k_eq_m6 _k_eq_m5 _k_eq_m4 _k_eq_m3 _k_eq_m2 _k_eq_p0 _k_eq_p1 _k_eq_p2 _k_eq_p3 _k_eq_p4 _k_eq_p5

xtevent total_deaths i.makeid#i.year i.carid#c.year, panelvar(carid) timevar(year) policyvar(T) window(-9 4) impute(instag) note

local counter = 1

forvalues i = 1(2)29 {
	local name `: word `counter' of `coef_names''
	mat results[`i',1] = _b[`name']
	mat results[`i'+1,1] = _se[`name']
	local ++counter
}
mat results[31,1] = e(N)

xteventplot, title("Alt. Specification with Linear Trends")  caption("Note: The number inside the parentheses report the average of the outcome" "variable for the treated group when the event time is -1.") xtitle("Event Time") ytitle("Total Deaths") scheme(s1mono)

graph export "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\figures\alt_levels_linear.jpg", as(jpg) name("Graph") quality(100) replace

xtevent l_deaths i.makeid#i.year i.carid#c.year, panelvar(carid) timevar(year) policyvar(T) window(-9 4) impute(instag) note

local counter = 1

forvalues i = 1(2)29 {
	local name `: word `counter' of `coef_names''
	mat results[`i',2] = _b[`name']
	mat results[`i'+1,2] = _se[`name']
	local ++counter
}
mat results[31,2] = e(N)

xteventplot, title("Alt. Specification with Linear Trends")  caption("Note: The number inside the parentheses report the average of the outcome" "variable for the treated group when the event time is -1.") xtitle("Event Time") ytitle("Log Total Deaths") scheme(s1mono)

graph export "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\figures\alt_logs_linear.jpg", as(jpg) name("Graph") quality(100) replace

putexcel set "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\figures\alt_spec.xlsx", replace

putexcel A1 = matrix(results), names nformat(number_d2)

// older stuff
// forvalue i = 2/5{
// 	gen dummy_lag_`i' = treatment_gp * ((start - mod_year) == `i')
// }
//
// forvalue i = 0/5{
// 	gen dummy_lead_`i' = treatment_gp * ((mod_year - start) == `i')
// }
//
// gen dummy_lag_pool =  treatment_gp * ((start - mod_year) >= 6)
// gen dummy_lead_pool =  treatment_gp * ((mod_year - start) >= 6)
//
// regress total_deaths i.carid i.mod_year  dummy_lead_* dummy_lag_*