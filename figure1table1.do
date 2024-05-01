/*
This file creates two figures:

a) CarPlay adoption over time
b) Summary statistics 
*/

// CarPlay adoptions figure

cd "C:\Users\Bryant Xia\Desktop\Projects\CarPlay"
clear all
import delimited apple, clear

sort start
gen freq = 1
collapse (sum) freq, by(start)

rename freq adopted
line adopted start, title("Adoption of Carplay Over Time") note("1") caption("source: scrapped from apple.com/ios/carplay/available-models/ by the author") xtitle("Year") ytitle("New Adoptions") scheme(s1mono) 

graph export "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\figures\adoption.jpg", as(jpg) name("Graph") quality(100)

// Summary statistics from the merged accidents file

use "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\08_21_merged_vehicle.dta", clear

replace mod_year = . if mod_year == 9999
replace prev_acc = . if prev_acc > 97

dtable deaths mod_year prev_acc, sample(, statistics(freq) place(seplabels)) sformat("(N=%s)" frequency)

* Prepare matrix to store results
matrix results = J(3,5,.)
matrix rownames results = "deaths" "model year of vehicle" "prev accidents"
matrix colnames results = "mean" "sd" "25th" "74th" "N" 

local outcomes total_deaths mod_year prev_acc

local row = 1

foreach v of local outcomes{
	qui sum `v', detail
	mat results[`row', 1] = r(mean)
	mat results[`row', 2] = r(sd)
	mat results[`row', 3] = r(p25)
	mat results[`row', 4] = r(p75)
	mat results[`row', 5] = r(N)
	local row = `row' + 1
}

matrix list results,format(%10.3f)
putexcel set table1, modify
putexcel E1 = matrix(results), overwritefmt colnames nformat(number_d2) 
