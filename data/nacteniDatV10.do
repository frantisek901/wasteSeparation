****** Do-file for loading data simulated in model proMisuV10 after new empirical specification ******
*
* Vytvoril: FdSS 2019/04/24
* Upravil:  FdSS 2019/09/20

clear
set more off
capture cd E:\!KVAS\
capture cd K:\!KVAS\
capture cd "C:\Users\Kalvas\ownCloud\!!!NetLogo\!MisaKudrnacova\"
capture log close
log using nacteniDat, text replace

*** Variables in dataset
*"[run number]","RS","pReverseSorting","tauN","tauU","closeLinks","randomLinks","randomSeed?","randomNeis?","sigma","sortingPrice","cutoff12","cutoff23","cutoff34","steps","[step]",
*"count turtles with [simSorting = 1]","count turtles with [simSorting = 2]","count turtles with [simSorting = 3]","count turtles with [simSorting = 4]",
*"longTimeSorting%","globalDiffSorting"

*** The dataset loading
insheet using simulationResults.csv, comma clear
drop in 1/7 // Omitting usless lines of dataset
destring v*, replace

* Omitting constant variables
drop v8 v10-v16 

* Renaming and labelling
rename v1 ids
lab var ids "ID Simulace"

rename v2 rs
lab var rs "NetLogo random seed"

rename v3 prs
replace prs = prs * 100
lab var prs "Pravdepodobnost zmeny chovani (v %)"

rename v4 tauN
lab var tauN "Prah uspokojeni"

rename v5 tauU
lab var tauU "Prah nejistoty"

rename v6 cl
*lab var cl "Pocet kratkych vazeb (uz vynasobeno!)"
lab var cl "Number of close links"
replace cl = cl * 2

rename v7 rl
replace rl = rl * 100
lab var rl "Pravdepodobnost zmeny kratke vazby na dlouhou (v %)"

rename v9 rn
*lab var rn "Sousedství ve small-world síti" 
lab var rn "Neighbourhood in small-world network" 
replace rn = "0" if rn=="false"
replace rn = "1" if rn=="true"
destring rn, replace
*lab def rn 1 "Homofilie (eco-postoj)" 0 "Náhodné"
lab def rn 1 "Homophily (eco-attitude)" 0 "Random"
lab val rn rn 

rename v17 ss1
lab var ss1 "1: Never sorts"

rename v18 ss2
lab var ss2 "2: Sometimes sorts"

rename v19 ss3
lab var ss3 "3: Frequently sorts"

rename v20 ss4
lab var ss4 "4: Always sorts"

rename v21 perc
lab var perc "Percentage of long-dureé sorting"

rename v22 fitness
lab var fitness "Difference between simulated and ISSP 2012 resulting variable"


* Saving data
compress
save dataV10, replace

*** Main graph
graph box ss1 ss2 ss3 ss4, over(cl) ///
   by(rn, title("Effect of number of close-links on sorting behavior")) ///
   ytitle("Number of non/sorting agents")
graph export closeLinksVsHomophilyBox.png, width(1600) replace


*** Another main graph
* Preparation of variables
gen p0 = perc if rn==0 
lab var p0 "Random"
gen p1 = perc if rn==1
lab var p1 "Homophily (eco-attitude)"
reg perc rn##cl
predict trend
lab var trend "Main trend"

* Sorting to proper order
sort rn cl
gen s = _n
replace s = 0 - s if rn == 0
sort s

* Graph itself
scatter p0 cl, jitter(5.4) msymbol(Oh) mlwidth(vvthin) msize(large) || ///
scatter p1 cl, jitter(2.7) msymbol(Oh) mlwidth(vvthin) color(green) || ///
scatter trend cl, c(l) color(cranberry) ///
   title("Effect of number of close-links on sorting behavior") ///
   ytitle("% sorting in long dureé")
graph export closeLinksVsHomophilyPerc.png, width(1600) replace


* Exit
log close
exit
