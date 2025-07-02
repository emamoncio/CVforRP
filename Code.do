********************************************************************************
* Using Computer Vision to Measure Design Similarity: An Application to Design Rights
* Author: Egbert Amoncio
* Date: 19 May 2025
********************************************************************************


cd "/Users/exyamc/Documents/GitHub/CVforRP/DesignPairs" // Replace the directory to where design pair chunks are stored

* Load the design pair chunks 
use "DesignPairs1.dta", clear

foreach i of num 2/35 {
append using  "DesignPairs`i'.dta", force
}
 

* Merge metadata for design1
merge m:1 design1 using "DesignMetaInfo.dta"
drop if _merge==2   // Drop if no design1 found
drop _merge
rename date2 design1_date2

* Merge metadata for design2
merge m:1 design2 using "DesignMetaInfo.dta"
drop if _merge==2
drop _merge
rename date2 design2_date2

* Remove USPC class information (to avoid duplicate variable issues)
drop uspc_class uspc_subclass

* Save the dataset with date metadata
save "DesignPairDates.dta", replace

* Create symmetric pairs by swapping design1 and design2
rename design1 temp
rename design2 design1
rename temp design2

renam design1_date2 temp
renam design2_date2 design1_date2
renam temp design2_date2

* Append the reversed version to original
append using "DesignPairDates.dta", force

* Return to original ordering
rename design1 temp
rename design2 design1
rename temp design2

renam design1_date2 temp
renam design2_date2 design1_date2
renam temp design2_date2 

* Keep only one direction (design1_date2 >= design2_date2)
keep if design1_date2 >= design2_date2

* Rank similarity for each design1
gsort design1 -ssim
by design1: gen rank = _n

* Keep only top 5 matches per design1
keep if rank <= 5

* Generate dummy indicators for NN levels
gen is_1nn = rank == 1
gen is_3nn = rank <= 3
gen is_5nn = rank <= 5

* Compute average similarity (SSIM) for 1, 3, 5 NN levels
egen nn_1 = mean(ssim) if is_1nn==1, by(design1)
egen nn_3 = mean(ssim) if is_3nn==1, by(design1)
egen nn_5 = mean(ssim) if is_5nn==1, by(design1)

drop if nn_1==.   // Keep a unique observation for each design1

* Clean dataset
drop design2 ssim rank is_1nn is_3nn is_5nn design1_date2 design2_date2
rename design1 design

* Save NN dataset
save "NearestNeighbor.dta", replace

* Merge metadata again to attach classification
rename design design1
merge m:1 design1 using "DesignMetaInfo.dta"
drop if _merge==2
drop _merge

* Extract filing year and cleanup
gen year = year(date2)
drop design2 date2

* Compute average NN similarity by class-subclass-year
egen dssd_1 = mean(nn_1), by(uspc_class uspc_subclass year)
egen dssd_3 = mean(nn_3), by(uspc_class uspc_subclass year)
egen dssd_5 = mean(nn_5), by(uspc_class uspc_subclass year)

* Save aggregation dataset
keep dssd_* uspc_class uspc_subclass year
duplicates drop uspc_class uspc_subclass year, force
save "DSSD.dta", replace

* Filter for final period and merge with outcome and controls
keep if year >= 2003 & year <= 2020
merge 1:1 uspc_class uspc_subclass year using ///
    "SubclassOutcomeControls.dta", force
keep if _merge==3
drop _merge

********************************************************************************
* MAIN REGRESSIONS - Litigation on DSSD
********************************************************************************

preserve
keep if subclass_no_unq_atty > 0
keep if subclass_no_unq_designs > 0

eststo clear

* Baseline PPML regression with similarity (quadratic)
eststo: ppmlhdfe subclass_litigation_count c.dssd_5##c.dssd_5, absorb(subclass) cluster(subclass)

* Add number of designs
eststo: ppmlhdfe subclass_litigation_count c.dssd_5##c.dssd_5 subclass_no_unq_designs, absorb(subclass) cluster(subclass)

* Add average firm design activity
eststo: ppmlhdfe subclass_litigation_count c.dssd_5##c.dssd_5 subclass_no_unq_designs ///
    subclass_ave_firm_no_unq_des, absorb(subclass) cluster(subclass)

* Add variance in firm design activity
eststo: ppmlhdfe subclass_litigation_count c.dssd_5##c.dssd_5 subclass_no_unq_designs ///
    subclass_ave_firm_no_unq_des subclass_var_firm_no_unq_des, absorb(subclass) cluster(subclass)

* Add attorney count
eststo: ppmlhdfe subclass_litigation_count c.dssd_5##c.dssd_5 subclass_no_unq_designs ///
    subclass_ave_firm_no_unq_des subclass_var_firm_no_unq_des subclass_no_unq_atty, ///
    absorb(subclass) cluster(subclass)

* Export regression results
esttab using USDC_Litigation.rtf, replace stats(N r2 ar2, fmt(3)) ///
    cells(b(star fmt(3)) se(par fmt(3))) starlevels(* 0.10 ** 0.05 *** 0.01) nogap

* Summary stats of estimation sample
asdoc su if e(sample)==1, replace
restore

********************************************************************************
* ROBUSTNESS: PANEL SETUP AND XTPOISSON
********************************************************************************

xtset subclass year

preserve
keep if subclass_no_unq_atty > 0
keep if subclass_no_unq_designs > 0

eststo clear

* Random effects Poisson
eststo: xtpoisson subclass_litigation_count c.dssd_5##c.dssd_5 ///
    subclass_no_unq_designs subclass_ave_firm_no_unq_des ///
    subclass_var_firm_no_unq_des subclass_no_unq_atty i.year, re vce(robust)

* PPML with subclass and year fixed effects
eststo: ppmlhdfe subclass_litigation_count c.dssd_5##c.dssd_5 ///
    subclass_no_unq_designs subclass_ave_firm_no_unq_des ///
    subclass_var_firm_no_unq_des subclass_no_unq_atty, ///
    absorb(subclass year) cluster(subclass)

* Export results
esttab using USDC_Litigation_Robust.rtf, replace stats(N r2 ar2, fmt(3)) ///
    cells(b(star fmt(3)) se(par fmt(3))) starlevels(* 0.10 ** 0.05 *** 0.01) nogap
restore

********************************************************************************
* UTEST: Joint test of linear and squared term
********************************************************************************

preserve
keep if subclass_no_unq_atty > 0
keep if subclass_no_unq_designs > 0

* Create squared term
gen sq_dssd_5 = dssd_5 * dssd_5

* Run PPML and test
eststo: ppmlhdfe subclass_litigation_count dssd_5 sq_dssd_5 ///
    subclass_no_unq_designs subclass_ave_firm_no_unq_des ///
    subclass_var_firm_no_unq_des subclass_no_unq_atty, ///
    absorb(subclass) cluster(subclass)

utest dssd_5 sq_dssd_5
restore

********************************************************************************
* PLOT MARGINAL EFFECTS
********************************************************************************

preserve
keep if year >= 2003 & year <= 2020
keep if subclass_no_unq_atty > 0
keep if subclass_no_unq_designs > 0

* Main model
ppmlhdfe subclass_litigation_count c.dssd_5##c.dssd_5 ///
    subclass_no_unq_designs subclass_ave_firm_no_unq_des ///
    subclass_var_firm_no_unq_des subclass_no_unq_atty, ///
    absorb(subclass) cluster(subclass)

* Margins and plot
margins, at(dssd_5 = (0(0.01)0.99)) predict(xb)
marginsplot, noci xlabel(#10) ylabel(, angle(horizontal))

restore

********************************************************************************
* END OF SCRIPT
********************************************************************************
