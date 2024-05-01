/*
Clean and merge several FARS data sets.

FARS updates several data sets yearly. The relevant ones for my purposes are vehicle, vpicdecode, and accident. Vehicle includes information on the vehicles involved in accidents (e.g. model year, body type, etc.); vpicdecode contains information from decoding the vehicle identification number (VIN) of vehciles in the data files (the numerical info here is helpful for matching later on); and finally, the accident data contains non-occupant deaths involved in crashes.

We define total death for a vehicle in a crash by: v + m/n, where v is the death(s) in this vehcile, m is the total number of non-occupant deaths in this crash, and n is the total number of vehicles involved in the crash. In other words, we attribute non-occupant deaths evenly across all vehicles involved.
*/

clear all

foreach y of numlist 2008/2022 {	
	// subset variables I want from vpic types
	import delimited "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\FARS`y'NationalCSV\vehicle.csv", clear
	gen year = `y'
	keep state st_case veh_no model body_typ vin vin_* mod_year make mak_mod deaths trav_sp rollover impact1 deformed deaths dr_drink dr_wgt dr_hgt prev_acc prev_sus* prev_dwi prev_spd prev_oth year
	save "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\trimmed_`y'.dta", replace
	
	// subset variables I want from decoding vin
	import delimited "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\FARS`y'NationalCSV\vpicdecode.csv", clear
	keep state st_case veh_no vehicletypeid makeid modelid bodyclassid vindecodeerror
	merge 1:1 state st_case veh_no using "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\trimmed_`y'.dta"
	drop if _merge == 1 // don't care about the vin file; the accident file is what matters
	drop _merge
	
	// get non-occupant deaths from the accident file
	save "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\trimmed_`y'.dta", replace
	import delimited "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\FARS`y'NationalCSV\accident.csv", clear
	keep state st_case fatals
	merge 1:m state st_case using "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\trimmed_`y'.dta"
	drop if _merge == 1 // same reason
	drop _merge
	
	// accident data files
	egen occ_deaths = total(deaths), by(state st_case)
	gen diff = fatals - deaths
	gen freq = 1
	egen total_vehicles = total(freq), by(state st_case)
	replace diff = 0 if missing(diff)
	gen total_deaths = deaths + diff/total_vehicles
	
	save "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\trimmed_`y'.dta", replace
} 

use "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\trimmed_2008.dta", clear

foreach y of numlist 2009/2022 {
    append using "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\trimmed_`y'.dta"
} 

save "C:\Users\Bryant Xia\Desktop\Projects\CarPlay\Data\08_22_merged_vehicle.dta", replace