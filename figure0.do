clear all
set maxvar 30000

use "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\08_22_merged_vehicle.dta", clear

drop if missing(year)
collapse (sum) total_deaths, by (year)
line total_deaths year, title("Total Deaths Over Time") xtitle("Calendar Year") ytitle("Total Deaths") xlabel(2008(2)2022) scheme(s1mono) 
graph export "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\newFigures\deaths_08_22.jpg", as(jpg) width(16000) replace

use "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\08_22_merged_vehicle.dta", clear
drop if missing(mod_year)
keep if mod_year >= 2000 & mod_year <= 2022
collapse (sum) total_deaths, by (mod_year)
line total_deaths mod_year, title("Total Deaths Over Model Year") xtitle("Model Year") ytitle("Total Deaths") scheme(s1mono) 
graph export "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\newFigures\deaths_modyear_08_22.jpg", as(jpg) width(16000) replace

// gen state_code = "HI"
// replace state_code = "Alabama" if state == 1
// replace state_code = "Alaska" if state == 2
// replace state_code = "Arizona" if state == 4
// replace state_code = "Arkansas" if state == 5
// replace state_code = "California" if state == 6
// replace state_code = "Colorado" if state == 8
// replace state_code = "Connecticut" if state == 9
// replace state_code = "Delaware" if state == 10
// replace state_code = "District of Columbia" if state == 11
// replace state_code = "Florida" if state == 12
// replace state_code = "Georgia" if state == 13
// replace state_code = "Hawaii" if state == 15
// replace state_code = "Idaho" if state == 16
// replace state_code = "Illinois" if state == 17
// replace state_code = "Indiana" if state == 18
// replace state_code = "Iowa" if state == 19
// replace state_code = "Kansas" if state == 20
// replace state_code = "Kentucky" if state == 21
// replace state_code = "Louisiana" if state == 22
// replace state_code = "Maine" if state == 23
// replace state_code = "Maryland" if state == 24
// replace state_code = "Massachusetts" if state == 25
// replace state_code = "Michigan" if state == 26
// replace state_code = "Minnesota" if state == 27
// replace state_code = "Mississippi" if state == 28
// replace state_code = "Missouri" if state == 29
// replace state_code = "Montana" if state == 30
// replace state_code = "Nebraska" if state == 31
// replace state_code = "Nevada" if state == 32
// replace state_code = "New Hampshire" if state == 33
// replace state_code = "New Jersey" if state == 34
// replace state_code = "New Mexico" if state == 35
// replace state_code = "New York" if state == 36
// replace state_code = "North Carolina" if state == 37
// replace state_code = "North Dakota" if state == 38
// replace state_code = "Ohio" if state == 39
// replace state_code = "Oklahoma" if state == 40
// replace state_code = "Oregon" if state == 41
// replace state_code = "Pennsylvania" if state == 42
// replace state_code = "Puerto Rico" if state == 43
// replace state_code = "Rhode Island" if state == 44
// replace state_code = "South Carolina" if state == 45
// replace state_code = "South Dakota" if state == 46
// replace state_code = "Tennessee" if state == 47
// replace state_code = "Texas" if state == 48
// replace state_code = "Utah" if state == 49
// replace state_code = "Vermont" if state == 50
// replace state_code = "Virginia" if state == 51
// replace state_code = "Virgin Islands (since 2004)" if state == 52
// replace state_code = "Washington" if state == 53
// replace state_code = "West Virginia" if state == 54
// replace state_code = "Wisconsin" if state == 55
// replace state_code = "Wyoming" if state == 56
//
// rename state_code name
// merge 1:1 name using "C:\Users\Bryant Xia\Downloads\trans.dta"
