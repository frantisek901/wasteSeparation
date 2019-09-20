****** Do file for empirical specification of model proMisuV10 ******
*
* Created: FdSS 2019/04/24
* Edited:  FdSS 2019/09/19

set more off
capture cd E:\!KVAS\
capture cd K:\!KVAS\
capture cd "C:\Users\Kalvas\ownCloud\!!!NetLogo\!MisaKudrnacova\"
capture log close
log using vyhodnoceniV10, text replace



*** non-fixed cut-offs
insheet using "C:\Users\Kalvas\ownCloud\!!!NetLogo\!MisaKudrnacova\proMisuV10b.finalCheckedBests.csv", comma clear
sum bestfitnesssofar taun tauu cutoff12 cutoff23 cutoff34, detail
sum bestfitnesssofar /// following values are parameters for the best fitness
taun /// 0.35
tauu /// 0.5
cutoff12 /// 0.355
cutoff23 /// 0.605
cutoff34 /// 0.805
if  bestfitnesssofar < 0.09, detail

sort bestfitnessrechecked // Let's sort it by fitness
list tau* cut* best* // the best valueas are at the comments above



*** OK, we set the values in NetLogo simulation and try to do with them 2,000 simulations.
*** Now, let's check if the fitness is still so low.
insheet using testOfParamsV10.csv, comma clear // loading testing data
drop in 1/7 // skipping first rubish lines of data
destring v*, replace // turning string numbers into numbers
rename v1 rs // renaming needed variables
rename v17 fitness
drop v* // dropping all variables without need

** Testing itself
sort fitness
list    // listing of sorted file
sum fitness, detail // summary statistics of FITNESS variable

* OK! Median fitness is: 0.038   Mean fitness is: 0.045   99% of fitness is: 0.125   1% of fitness is: 0.007

log close
exit




