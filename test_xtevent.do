clear all

set obs 100
gen person = _n
expand 100
sort person
gen t = _n

replace t = mod(t, 100)
replace t = 100 if t == 0

gen T = 0

replace T = 1 if person >= 50 & person <= 80 & t >= person

gen noise = rnormal(3)
gen outcome = 1 + 3 * T + noise

gen event_start = 0
replace event_start = person if person >= 50 & person <= 80
gen treated = 0
replace treated = 1 if person >= 50 & person <= 80

foreach i of numlist 2/5{
	gen dummy_lag_`i' = treated * ((event_start - t) == `i')
}

foreach i of numlist 0/5{
	gen dummy_lead_`i' = treated * ((t - event_start) == `i')
}

gen dummy_lag_pool =  treated * ((event_start - t) >= 6)
gen dummy_lead_pool =  treated * ((t - event_start) >= 6)

reg outcome i.t i.person dummy_lag* dummy_lead*

xtevent outcome, panelvar(person) timevar(t) policyvar(T) window(-5 5) impute(nuchange) plot 

gen never_treat = 1 - treated