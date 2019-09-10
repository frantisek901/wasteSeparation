extensions [nw matrix]

breed [consumats consumat]

turtles-own [
  attitude ;; actual attitude of consumat
  cognition ;; stores code of cognitive process used present round for determining non/sorting
  sorting ;; actual sorting behavior of consumat

  Nit-1 ;; Needs' satisfaction previous round
  Nit   ;; Needs' satisfaction recent round
  NSik  ;; Satisfaction of social needs
  NPik  ;; Satisfaction of personal needs
  Ui    ;; Uncertainity
  beta  ;; Randomly distributed agent parameter determining how much personal needs are weighted versus social ones

  record ;; list with recorded values of SORTING since SETUP until the last round
  changed? ;; did turtle changed SORTING since the previous round?
  loadedAttitude ;; attitude index loaded from file
  finalBehavior ;; final behavior index loaded from file
  finalSorting ;; final sorting behavior loaded from file
  simSorting ;; sorting RECORD rocoded into ordinal variable equivalent to FINALSORTING
  diffSorting2 ;; squarred difference between FINALSORTING and SIMSORTING
]

globals [
  end? ;; stores TRUE if conditions for finishing simulation are satisfied
  globalDiffSorting ;; indicator of quality of model fit to ISSP data
  individualDiffSorting ;; secondary indicator of model fit
]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; reporters substituting globals ;;;;
;; sorting: no/yes
to-report no
  report 0
end

to-report yes
  report 1
end

; cognitive processes
to-report repetition
  report 0
end

to-report imitation
  report 1
end

to-report deliberation
  report 2
end

to-report comparison
  report 3
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Startup and Setup
to startup
  ca
  setup
end

to setup
  ;; setup itself
  if randomSeed? [random-seed RS]
  turtle-setup
  check-cutoffs

  ;; Checking of right setting of CUTOFFs
  if cutOff12 < 0.005 [
    set globalDiffSorting 10
    set individualDiffSorting 10
    stop
  ]

  ;; reseting
  reset-ticks
  if randomSeed? [random-seed RS]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to check-cutoffs
  if cutOff23 >= cutOff34 [set cutOff23 (cutOff34 - 0.01)]
  if cutOff12 >= cutOff23 [set cutOff12 (cutOff23 - 0.01)]
end

to turtle-setup
  ;; cleaning environment
  ca
  set-default-shape turtles "circle"
  ask patches [set pcolor white]

  ;; Generation of Watts-Strogatz small-world network and loading data in turtles
  nw:generate-watts-strogatz turtles links 1841 closeLinks randomLinks [
    fd 35 ;; make a big circle
    set size 1 ;; be small
    set beta precision (random-float 1) 4 ;; set possible variables
    set record [] ;; initializing RECORD as a list
    set changed? false
  ]

  ;; Loading data in turtles after creating of small-world network
  ifelse ( file-exists? "dataMisa4.txt" ) [
    file-open "dataMisa4.txt"       ;; NOTE: DataMisa4.txt are sorted according Attitude,
    ifelse not homophily? [
      ask turtles [
        set finalBehavior file-read
        set loadedAttitude file-read
        set finalSorting file-read
      ]
    ][
      foreach sort-on [who] turtles [  ;;      that is why we are sorting turtles according WHO,
        [the-turtle] -> ask the-turtle [ ;;    so the turtles with low WHO have the most pro-sorting attitude
          set finalBehavior file-read
          set loadedAttitude file-read
          set finalSorting file-read
        ]
      ]
    ]
    file-close
  ][user-message "There is no dataMisa4.txt file in current directory!"]





  ;; turtle variables
  ask turtles  [
    if finalSorting > 4 or finalSorting < 1 [die] ;; turtles with no data or without chance to sort die
    set finalSorting (5 - finalSorting) ;; NOTE: we reverse FINALSORTING here, for better comparability mean of RECORD distribution
    set attitude loadedAttitude ;; for code-testing purposes we separate attitude used in simulation and value loaded in turtle from data
    set sorting ifelse-value (attitude > random-float 1) [yes] [no]  ;; initialization with respect to ATTITUDE
    change-colour
  ]
  ask turtles [if count my-links = 0 [create-link-with one-of other turtles show "Link added!"]] ;; Every turtle must be connected

  ;; For computing level of satisfaction we need finished network and all consumats in the network with set behavior
  ask turtles  [
    set Nit-1 satisfaction ;; use routines for NPi and NSi and SATISFACTION
    set Nit satisfaction ;; use routines for NPi and NSi and SATISFACTION
    set Ui uncertainity ;; USE ROUTINE uncertainity
    set record lput sorting record ;; We record SORTING as the first value on RECORD
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SETUP and GO reporters and routines
to-report uncertainity
  report sqrt( abs(Nit - Nit-1))
end

to-report satisfaction
  set NSik ((count link-neighbors with [sorting = [sorting] of myself]) / (count link-neighbors))
  set Nsik normalized (random-normal Nsik sigma)
  set NPik (1 - (abs (attitude - sorting)))
  let Nik (beta * NSik + (1 - beta) * NPik) ;; NSik and NPik weighted by BETA
  let price ((sortingPrice * sorting) + ((1 - sorting) * 1)) ;; designed that for sorting==no equal to 1, for sorting==yes equal to SortingPrice
  set Nik (Nik / price) ;; Nik is weighted by sortingPrice
  set Nik (normalized (Nik)) ;; We check the Nik is in the interval <0 ; 1>, in case not, we cut value to the interval
  report Nik
end

to-report normalized [x]
  if x > 1 [set x 1]
  if x < 0 [set x 0]
  report precision x 4 ;; NOTE: here we round values to 4 digits
end

to change-colour
  set color ifelse-value (sorting = yes) [green] [red]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  ;; Checking of right setting of CUTOFFs
  if cutOff12 < 0.005 [
    set globalDiffSorting 10
    set individualDiffSorting 10
    stop
  ]

  ;; GO routine itself
  ask turtles [update-variables]
  ask turtles [choose-cognitive-process]
  ask turtles [update-behavior]
  ask turtles [update-consequences]
  if ticks >= 9 [update-globals]
  check-end
  tick
  if end? [
    do-regression
    stop
  ]
end

to update-globals
    set globalDiffSorting global-difference-in-sorting
    set individualDiffSorting individual-difference-in-sorting
end

to do-regression
    let y sort ([simSorting] of turtles)
    let x sort ([finalSorting] of turtles)
    Print "Regression coeficients - the first element of second list is R2:"
    print matrix:regress matrix:from-column-list (list y x)
end

to-report global-difference-in-sorting
  let x sort ([simSorting] of turtles)
  let y sort ([finalSorting] of turtles)
  let z (map [[a b] -> ((a - b) ^ 2)] x y)
  report precision (mean z) 6
end

to-report individual-difference-in-sorting
  let x ([diffSorting2] of turtles)
  report precision (mean x) 6
end

to check-end
  ;; let's suppose, conditions are satisfied :)
  set end? true

  ;; Checking turtles' changes
  ask turtles [
    set changed? false
    let x (length record) - 2
    if length record > 1 and last record != (item x record) [set changed? true]
  ]

  ;; Checking length of simulation
  if count turtles with [changed?] > 0 [set end? false]  ;; we continue in simulation if here is some change
  if ticks <= 10 [set end? false] ;; anyway, we continue in simulation for 10 ticks
  ;if length ([record] of one-of turtles) = steps [set end? true] ;; anyway, we stop simulation at 100 ticks
  if ticks >= steps [set end? true] ;; anyway, we stop simulation at STEPS ticks
end

to update-variables
  set Nit-1 Nit ;; we copy Nit as past satisfaction
  set Nit satisfaction ;; we compute recent satisfaction via reporter SATISFACTION
  set Ui uncertainity ;; we compute recent uncertainity via reporter UNCERTAINITY
end

to choose-cognitive-process
  ;; here we just set value of variable COGNITION according NIT and UI values,
  ;; behavior itself would be chosen elsewhere
  ifelse Nit < tauN [
    set cognition ifelse-value (Ui > tauU) [comparison] [deliberation]
  ][set cognition ifelse-value (Ui > tauU) [imitation] [repetition]]
end

to update-behavior
  ;; choosing right cognitive routine
  if cognition = repetition   [do-repetition]
  if cognition = imitation    [do-imitation]
  if cognition = deliberation [do-deliberation]
  if cognition = comparison   [do-comparison]

  ;; Randomly reversing of planned behavior
  ;; Not only reverse behavior, we have also recalculate NIT of reversed behavior, but may be NOT...
  if pReverseSorting > random-float 1 [
    set sorting (1 - sorting)
    if recalculateNit? [set Nit satisfaction] ;; let us try it and experiment with difference in recalculation - now it seems there is no substantial effect of recalculation...
  ]
end

to update-consequences
  ;; recording behavior
  set record lput sorting record ;; We record new SORTING value as the last value on RECORD
  if length record > 100 [set record (but-first record)] ;; triming RECORD list to the last 100 records

  ;; Updating simulated answer to the sorting question
  if ticks >= 9 [
    let value (mean record)
    ifelse value < cutoff23 [
      set simSorting ifelse-value (value < cutoff12) [1][2]
    ][set simSorting ifelse-value (value < cutoff34) [3][4]
    ]
    set diffSorting2 ((simSorting - finalSorting) ^ 2)
  ]

  ;; Re-color
  change-colour
end

to do-repetition ;; consumat repeats SORTING
  ;; sorting is set from previous round, so there is no need to do anything :)
  ;; at least now :)
end

to do-imitation ;; consumat imitates the most common value of SORTING
  ;; we use MODES function, which returns list of most common values,
  ;; in case more values are the most frequent it returns list of all the most common values
  let mostCommonValues modes [sorting] of link-neighbors

  ;; from these most common values we choose randomly by function ONE-OF,
  ;; in case the list contain only one value, ONE-OF turns list of one value into the value
  set sorting one-of mostCommonValues
end

to do-deliberation ;; consumat compares NIT valueas for both values of SORTING
  ;;;; We set SORTING to NO, compute NIT, then we set it to YES, compute again and compare results
  ;; Computing for NO
  set sorting no
  let NitNo satisfaction

  ;; Computing for YES
  set sorting yes
  let NitYes satisfaction

  ;; Setting SORTING to better value
  ifelse NitNo = NitYes [
    set sorting one-of (list no yes)  ;; in case of tie we choose randomly
  ][set sorting ifelse-value (NitYes > NitNo) [yes] [no]] ;; else we choose better value
end

to do-comparison ;; consumat compares SORTING
  ;;;; Firstly we compute NIT for actual SORTING,
  ;;;; then secondly for the most common SORTING in the neighborhood,
  ;;;; lastly we choose the better value.
  ;; Computing for my SORTING
  let myNit Nit ;; SORTING is already set, NIT was already computed, we just store it in new variable for sure
  let mySorting sorting ;; we have to store respective SORTING

  ;; Computing for their SORTING - it would be possible use here DO-IMITATION routine,
  ;; but for sure, we write it here again
  ;; (may be in the future versions of DO-IMITATION will not be possible or suitable use this routine).
  set sorting one-of modes [sorting] of link-neighbors  ;; very condensed version of code used for DO-IMITATION
  let theirNit satisfaction ;; we compute NIT for the most common value of SORTING
  let theirSorting sorting ;; we have to store respective SORTING

  ;; Setting SORTING to better value
  ifelse theirNit = myNit [
    set sorting one-of (list mySorting theirSorting) ;; in case of tie we choose randomly
  ][set sorting ifelse-value (myNit > theirNit) [mySorting] [theirSorting]] ;; else we choose better value
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@#$#@#$#@
GRAPHICS-WINDOW
210
10
644
445
-1
-1
6.0
1
10
1
1
1
0
0
0
1
-35
35
-35
35
1
1
1
ticks
30.0

BUTTON
18
10
81
43
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
81
10
144
43
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
18
42
207
75
randomLinks
randomLinks
0.00
0.50
0.1
0.001
1
NIL
HORIZONTAL

SLIDER
18
75
207
108
closeLinks
closeLinks
1
15
3.0
1
1
NIL
HORIZONTAL

SLIDER
18
108
207
141
tauN
tauN
0
1
0.4
0.05
1
NIL
HORIZONTAL

SLIDER
18
141
207
174
tauU
tauU
0
1
0.5
0.05
1
NIL
HORIZONTAL

PLOT
656
11
1077
175
Environmental behaviour
NIL
NIL
0.0
10.0
0.0
2000.0
true
true
"" ""
PENS
"red" 1.0 0 -5298144 true "" "plot count turtles with [sorting = no]"
"green" 1.0 0 -12087248 true "" "plot count turtles with [sorting = yes]"
"changed" 1.0 0 -16777216 true "" "plot count turtles with [changed?]"

MONITOR
128
400
210
445
N
count turtles
0
1
11

BUTTON
144
10
207
43
1step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
128
355
210
400
 % long links
100 * count links with [link-length > 2] / count links
3
1
11

SLIDER
1076
326
1275
359
sortingPrice
sortingPrice
0.5
2
1.05
0.05
1
NIL
HORIZONTAL

MONITOR
46
355
128
400
changed?
count turtles with [changed?]
17
1
11

PLOT
656
175
861
295
Sorting of agents
NIL
NIL
0.0
1.1
0.0
10.0
true
false
"" "set-plot-y-range 0 10"
PENS
"default" 0.03 1 -16777216 true "" "histogram [mean record] of turtles"

PLOT
861
175
1077
295
Sorting of resps. (REVERSED!)
NIL
NIL
0.5
5.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [finalSorting] of turtles"

PLOT
861
295
1077
445
Behavioral index of respondents
NIL
NIL
0.0
1.1
0.0
10.0
true
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram [finalBehavior] of turtles"

PLOT
656
295
861
445
Attitudes of respondents
NIL
NIL
0.0
1.1
0.0
10.0
true
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram [loadedAttitude] of turtles"

SWITCH
1076
294
1275
327
randomSeed?
randomSeed?
1
1
-1000

MONITOR
46
400
128
445
% sorting
100 * mean [sorting] of turtles
1
1
11

PLOT
1076
11
1276
175
Beta of "changed?" agents
NIL
NIL
0.0
1.1
0.0
10.0
true
false
"" "set-plot-y-range 0 10"
PENS
"default" 0.1 1 -16777216 true "" "histogram [beta] of turtles with [changed?]"

SLIDER
18
174
207
207
pReverseSorting
pReverseSorting
0
.2
0.1
0.001
1
NIL
HORIZONTAL

SLIDER
18
207
207
240
sigma
sigma
0
0.6
0.0
0.01
1
NIL
HORIZONTAL

INPUTBOX
1076
358
1130
418
RS
1.0
1
0
Number

INPUTBOX
1129
358
1184
418
steps
105.0
1
0
Number

SLIDER
18
239
207
272
cutoff12
cutoff12
0.005
0.495
0.105
0.01
1
NIL
HORIZONTAL

SLIDER
18
272
207
305
cutoff23
cutoff23
0.105
0.895
0.495
0.01
1
NIL
HORIZONTAL

SLIDER
18
305
207
338
cutoff34
cutoff34
0.505
0.995
0.875
0.01
1
NIL
HORIZONTAL

PLOT
1076
175
1276
295
Sorting of agents (RECODED!)
NIL
NIL
0.5
5.0
0.0
10.0
true
false
"" "set-plot-y-range 0 10"
PENS
"default" 1.0 1 -16777216 true "" "histogram [simSorting] of turtles"

MONITOR
1183
358
1275
403
NIL
globalDiffSorting
17
1
11

MONITOR
1183
402
1275
447
NIL
individualDiffSorting
17
1
11

PLOT
656
445
1077
595
Attitude vs. sim/finalSorting
NIL
NIL
0.5
4.5
0.0
1.0
true
true
"" "clear-plot\n"
PENS
"simSorting" 1.0 2 -16777216 true "" "ask turtles [plotxy simSorting attitude]"
"finalSorting" 1.0 2 -2674135 true "" "ask turtles [plotxy (finalSorting + 0.15) attitude]"

MONITOR
1077
418
1145
463
group4
(word precision (mean [attitude] of turtles with [simSorting = 4]) 2\n\"; \"\nprecision (median [attitude] of turtles with [simSorting = 4]) 2\n)
17
1
11

MONITOR
1077
462
1145
507
group3
(word precision (mean [attitude] of turtles with [simSorting = 3]) 2\n\"; \"\nprecision (median [attitude] of turtles with [simSorting = 3]) 2\n)
17
1
11

MONITOR
1077
506
1145
551
group2
(word precision (mean [attitude] of turtles with [simSorting = 2]) 2\n\"; \"\nprecision (median [attitude] of turtles with [simSorting = 2]) 2\n)
17
1
11

MONITOR
1077
550
1145
595
group1
(word precision (mean [attitude] of turtles with [simSorting = 1]) 2\n\"; \"\nprecision (median [attitude] of turtles with [simSorting = 1]) 2\n)
17
1
11

SWITCH
1144
446
1275
479
recalculateNit?
recalculateNit?
0
1
-1000

SWITCH
1144
478
1275
511
homophily?
homophily?
0
1
-1000

@#$#@#$#@
## Korespondence

Dobré dopoledne,

aha, tak to se mi tedy úplně nepovedlo... Snažila jsem se ten model přizpůsobit co nejlíp, ale letní škola, kde jsem loni byla, mi pomohla jen s teoretickými znalostmi a ze skutečného kódování tam nebylo nic, takže jsem se tím musela nějak protlouct sama. No a proto to vypadá tak, jak to vypadá.
K vašemu návrhu: hodně jsem nad tím včera/dnes přemýšlela. Když jsem začala na projektu diplomky pracovat, chtěla jsem si všechno udělat sama, ale postupem času jsem začala zjišťovat, že abych to zvládla úplně sama, tak by to zabralo mnohonásobně víc času a to s mým pracovním vytížením není moc reálné. Navíc, jak říkáte, jsou tam chyby a rozhodně prostor ke zlepšení a zjednodušení. Když jste ochotný mi s modelem pomoct, byla bych hloupá, kdybych vaši nabídku odmítla. Budu ráda, když mi pomůžete, a když spolu dáme dohromady ten článek.

Předem moc díky a hezký den,
Míša

čt 7. 3. 2019 v 14:33 odesílatel František <kalvas@kss.zcu.cz> napsal:

    Ok, omluva přijata! :)

    Co se týče postojů a chování (self-reported) - v současné podobě tam postoje k ničemu nejsou, model pracuje jen s prvním údajem v listu a tím údajem je chování, postoj je až druhý (item 1) a žádná část kódu ho nevyužívá. Tím že používáte chování místo postoje, se odcizujete původnímu modelu - ten vysvětluje chování postoji, vy vysvětlujete chování chováním. Vyjít z chování nedává smysl, protože to samo je cílem.

    GB modeloval skrze model dopad cenové politiky na produkci CO2, vy takový externí cíl nemáte. Osobně doporučuji - ale nenutím - abyste vyšla z postojů a index chování využila pro kalibraci modelu, tedy nastavení těch 4 parametrů, které tam jsou. S tou kalibrací vám rád pomůžu.

    Až bude model kalibrovaný, můžete si vybrat jeden ze 4 parametrů (zatím je favorit random-link) a zahrát si s ním 'coby-kdyby'. A bude to.

    Ještě bych navrhoval Přepsat to srdce modelu - go a jeho procedury, a jen tím vynucená místa v setupu. Jak je to zbytečně založené na těch listech, tak je to strašně nepřehledné. Mám pro Vás návrh - já to přepíšu rovnou tak, aby šlo udělat kalibraci, vy v práci přiznáte, že jsem Vám s tím pomohl a pak spolu o adaptaci toho modelu, kalibraci, výsledcích atd. napíšeme článek. Co Vy na to?

    S úctou,
    František

    7. 3. 2019 napsal(a):

        Dobré ráno,
        ano, máte samozřejmě pravdu. Měla jsem to udělat už u prvního emailu, ale nabyla jsem dojmu, že model je už "dost můj" a že bude stačit vám poslat jen moji verzi přizpůsobeného modelu. Až při pokusu o ODD mi došlo, že to vůbec není pravda a že kromě přizpůsobení na moje data a pár jednoduchých features se mi tolik změn udělat nepovedlo a pak už mi to bylo trapné přiznávat. Takový model by mi trval věky vytvořit, bůh ví, jestli by se to vůbec podařilo. I přizpůsobování tohohle modelu nebylo vůbec jednoduché a trvalo mi dlouho. Dlužím vám omluvu, vážně mě to mrzí a cítím se hloupě. Jestli to alespoň trochu zmírní vaše rozčilení, tak bych jen chtěla říct, že jsem nikdy nemínila model vydávat za zcela nově vytvořený a předstírat, že žádná předloha pro něj neexistuje.

        S touhle částí modelu se mi nedaří se poprat. Z regresní analýzy, kterou jsem si udělala, vyplývá, že postoje jsou velmi slabým až téměř žádným prediktorem chování, přišlo mi tak vhodnější pracovat s vytvořenou škálou chování. Navíc tím, že to vyplývá z dotazníku (self-reported behaviour) mi přišlo lepší pracovat spíš s chováním a postoje zahrnout jen v minimální míře, ale přesto ho tam nechat. Dává to takhle smysl?

        Právě jsem přemýšlela o tom, co zmiňujete: "Váš model by pak vlastně propojoval postoje s chováním tím, že model zohledňuje vliv soc. okolí." Jen si nejsem úplně jistá, jak to udělat prakticky. Ještě se na to budu podívat, teď ten email čtu hodně rychle před tím, než půjdu do práce.

        Zatím jsem si jistá hlavně tím, že nechci nijak pracovat s cenami a vážně uvažuji o tom, že willingness-to-change z modelu úplně vyřadím. Přijde mi mnohem důležitější vliv toho sociálního okolí, tedy jak jste řekl už vy: "Zda budeme více třídit, když budeme mít navázané pouze s lidmi s podobným názorem na třídění, nebo zda se nějak výsledek změní, když navážeme vazby s lidmi s jiným pohledem?" Navíc se chci maximálně pokusit o to, aby větší část modelu byla realistická a založená na datech z dotazníku, ne jen domněnkách.

        Díky moc! Odpoledne/ zítra se na to ještě podívám a pokusím se s tím nějak pohnout. Snad to půjde...

        Hezký den,
        Michaela Kudrnáčová


        čt 7. 3. 2019 v 1:51 odesílatel PhDr. Mgr. Frantisek Kalvas Ph.D. <kalvas@kss.zcu.cz> napsal:

            Milá Míšo,



            příště, až mně, nebo někomu jinému, budete psát "Dala jsem dohromady jakousi základní verzi", tak prosím rovnou na rovinu přiznejte, že jste model od někoho opajcovala a rovnou přiložte i kód, ze kterého jste vyšla. Ušetří to dost času, tomu, kdo Vám v dobré víře pomáhá. Abychom si rozuměli - používat přiznaně cizí kód je naprosto v pořádku, je to jako někoho doslovně citovat, jen je zcela vpořádku "citovat" velmi rozsáhlé pasáže. Já se v té Vaší verzi snažil vyznat a pořád mi vrtalo hlavou, proč tam pořád operujete s listy, když nejsou potřeba a úplně by stačily místo listů jednoduché proměnné. Jenže listy používal v původní verzi Gingiaccomo, že, tak Vám tam zůstaly... Kdybych rovnou věděl odkud vítr vane, začal bych se orientovat dřív, protože ta kostra od GB je složitá jak křížovka ve Vlastě - těžko se v těch listech orientuju, co kde může být na jaké pozici, dávám přednost proměnným, jejichž název rovnou o něčem vypovídá. Ale dost vyčítání.

            Původní GB model funguje tak, že na základě eko-chování lidí v okolí a preference pro eko-chování se určí samotné chování agenta, přičemž chování jsou tři druhy (proto ty listy...): jídlo (na základě dvou preferencí), doprava (jedna preference) a energetika (jedna preference). To je Vám jasné, to z naší korespondence vím. Mně pak ale není jasné, proč do preferencí ve své verzi nahráváte dvě hodnoty - postoj a chování - když máte jen jedno chování (podle názvu proměnných jde o třídění odpadu, že?)?

            Když jsem prošel Váš kód, zjistil jsem, že pro výpočet spokojenosti používáte jen první hodnotu z dvojice - a překvapilo mi, že nejde o index postoje (jak bych čekal, neb model se snaží rozkrýt dynamiku vyvažování mého postoje a mého chování a chování druhých), ale index chování. No nevím, co si o tom myslet. Buď je to tak dobře - index chování má vypovídat o tom, jak se chce osoba chovat, je to tedy preference pro třídění, záměr - nebo je to špatně - index chování říká, jak moc osoba opravdu třídí.  Pokud je index chování opravdu preference chování, pak je zbytečné operovat s nějakým postojem.

            Pokud index chování vypovídá o samotném chování, tj. je to popis stavu, žádný záměr, pak by to byla skvělá šance na validaci/kalibraci! Rozumíte - Váš model by pak vlastně propojoval postoje s chováním tím, že model zohledňuje vliv soc. okolí. Pak stačí do preference načíst správnou hodnotu (postoj) a vymyslet, jak srovnat chování agenta a s indexem chování (buď se dá udělat cut-off, tj. řeknete že od hodnoty indexu např. 0.6 (hodnotu nastavíte tak, aby počet třídičů v modelu odpovídal počtu třídičů v ČR) to znamená, že třídí, pod tím netřídí, a po např. 100 krocích model zastavíte a srovnáte si binarizovaný index chování s tím, jestli agent třídí nebo ne; nebo od 101. do 200. kroku zaznamenáte kolikrát agent třídil a počet třídění srovnáte s indexem vynásobeným 100 a spočítáte jaká je odchylka mezi indexem, tj. chováním respondenta, a chováním agenta). Pak můžete hledat takové nastavení parametrů sítě a prahů spokojenosti a nejistoty, které přinese co nejmenší odchylku mezi indexem a chováním agenta.

            A ještě jedna otázka - co je vlastně výzkumná otázka, kterou má model zodpovědět? V modelu vidím celkem 4 parametry: počet náhodných spojení, počet blízkých spojení, minimální spokojenost a tolernce nejistoty, přičemž v GB modelu 3. a 4. parametr autoři zafixovali na 0,5 a 0,2, neb tak nejlépe model replikoval jejich data o chování spotřebitelů, oni vlastně i 1. a 2. parametr zafixovali, na agrgument už si nevzpomínám. Vlastně je tu ještě 5. proměnná - willingnes to change, ten parametr při nastavení preferenceChange na Type 2 zvyšuje inklinaci k třídění.

            A teď jde o to, vliv čeho na třídění odpadu chcete modelovat? Z dostupných proměnných máte tedy 5 možností:
            1) a 2) jak změna hodnot prahů spokojenosti a nejistoty změní výsledek - to nedoporučuji, výsledek by byl asi banální, se změnou prahů se častěji bude dostávat do hry jiný typ volby chování, což se dá čekat, a povede to pak k příslušným změnám, které se dají také čekat; osobně bych ty hodnoty nechal tak, jak je zafixoval GB, případně, pokud bude možné provést kalibraci na data z ISSP, tak bych tyhle hodnoty zafixoval na nějaké lepší hodnotě, ale nečinil bych je předmětem výzkumné otázky;

            3) a 4) máte možnost měnit těmito parametry podobu sítě mezi agenty a sledovat její vliv - jestli na to máte nějakou hypotézu , tak směle do toho, jako slibné bych viděl experimentování s random-links: protože close-links jsou definovány jako spojení s agenty, kteří mi jsou nejpodobnější, random-links mi pak říká, kolik procent agentů jednu z těchto vazeb na někoho podobného zruší a naváže vztah náhodně, bez ohledu na podobnost. Otázka pak může znít, zda budeme více třídit, když budeme mít navázané pouze s lidmi s podobným názorem na třídění, nebo zda se nějak výsledek změní, když navážeme vazby s lidmi s jiným pohledem?

            5) můžete experimentovat s willingness-to-change, tj. otázka: jak moc se zvýší třídění v závislosti na zvýšení preference třídit? Ergo, neřešíte jak toho dosáhnout, toho zvýšení, jakými marketingovými fintami, ale ptáte se, když tu referenci zvýším o 50 %, kolik % lidí začne třídit navíc?

            6) v původních modelech byla i cena chování, tj. otázka: O kolik je třeba finančně zvýhodnit eko-chování, aby se významně zvýšilo? Pak by bylo potřeba doplnit parametr pro finanční sankci do modelu, GB to tam myslím má, rozhodně to mají Janssen a Jager ve vzorečcích ve svém článku.

            7) vymyslíte ještě něco dalšího...



            S úctou,
            František

             Pondělí, 4 Březen, 2019 13:21 CET, Michaela Kudrnáčová <kudrnacova.m@gmail.com> napsal:

            > - článek v příloze
            > - vzorečky mám jen tak, jak jsou v NetLogu, nevymyslela jsem je sama, jsou
            > hodně inspirované jiným modelem jen předělané tak, aby dávaly smysl na můj
            > model:
            > 
            > ; satisfaction and uncertainty
            >   ask turtles [
            >     set n-of-neighbors count link-neighbors
            >     set uncertainty [0 0]
            >     set need-satisfaction (compute-satisfaction actions)
            >   ]
            > end
            > 
            > ; satisfaction evaluation procedures
            > to evaluate-satisfaction
            >   ask turtles [
            >     set past-satisfaction need-satisfaction
            >     set need-satisfaction compute-satisfaction actions
            >     set uncertainty (list sqrt(abs(item 0 need-satisfaction - item 0

            > past-satisfaction))
            >      )
            >   ]
            > end
            > 
            > to-report compute-satisfaction [my-action]
            >   let behaviour-satisfaction behaviour-sat (item 0 my-action)
            >   let satisfaction (list behaviour-satisfaction)
            >   report satisfaction
            > end
            > 
            > to-report behaviour-sat [x]
            >   let behaviour-pers 1 - (abs ((item x behaviour-char) - item 0 preference))
            >   let behaviour-soc (count link-neighbors with [item 0 actions = x]) /
            > n-of-neighbors
            >   let satisfaction (beta * behaviour-soc + (1 - beta) * behaviour-pers)
            >   report satisfaction
            > end
            > 
            > 
            > Co se zohledňuje u vzorců chování (vždy SAT i UN):
            > 
            > to choose-behaviour
            >   if item 0 need-satisfaction < min-satisfaction and item 0 uncertainty <=
            > uncertainty-tolerance [deliberation-behaviour]
            >   if item 0 need-satisfaction >= min-satisfaction and item 0 uncertainty >
            > uncertainty-tolerance [imitation-behaviour]
            >   if item 0 need-satisfaction < min-satisfaction and item 0 uncertainty >
            > uncertainty-tolerance [social-comparison-behaviour]
            >   ; in the case need-satisfaction >= min-satisfaction and uncertainty <=
            > uncertainty-tolerance agents will repeat the previous action
            >   ; and hence maintain the behaviour
            > end
            > 
            > - imitation - je to tak, sice si agenti můžou pokazit SAT, ale protože mají
            > vysokou nejistotu, tak je to prostě něco, o čem vědí, že riskují. Mně to
            > tak dává docela smysl. Hezky to tak i zapadne mezi všechny ty ostatní vzorce
            > 
            > - proměnné jsou jen 2, a ne 4 (jak říkáte vnitřní a vnější)
            > - existuje prahová hodnota, kterou si lze navolit v interface:
            > "min-satisfaction" a "uncertainty tolerance"
            > - to, jak jste popsal daný proces mi přijde trefné :)

            > 
            > Míša
            > 
            > 
            > po 4. 3. 2019 v 12:17 odesílatel PhDr. Mgr. Frantisek Kalvas Ph.D. <
            > kalvas@kss.zcu.cz> napsal:
            > 
            > > Milá Míšo,
            > >
            > >
            > >
            > > Marco Janssen a Wander Jaeger jsou určitě super! Pro mne se jedná o dva
            > > velmi respektované autory. Skvělý výběr! Od nich se můžete opravdu něco
            > > učit... Docela by mi zajímalo, jak svůj model popisovali - je to datované
            > > před ustavením ODD... Můžete mi prosím poslat ten jejich článek? Stačí
            > > odkaz ke stažení, ať šetříme optické kabely :)
            > >
            > > Teď bych ještě prosil o vzorečky, jak se počítá UNCERTAINITY a
            > > SATISFACTION, a to raději zvlášť pro VNITŘNÍ/PSYCHYCKOU (konzistence
            > > postoje a vlastního chování) a VNĚJŠÍ/SOCIÁLNÍ (konzistence vlastního
            > > chování a chování okolí), měly by totedy být 4 vzorečky: PU (psychical
            > > uncertainity), PS (psychical satisfaction), SU (social uncertainity) a SS
            > > (social satisfaction). Potřebuji to mít na papíře od Vás, abych mohl
            > > zkontrolovat, jestli je to v kódu implementované podle toho, co jste mi
            > > napsala bokem.
            > >
            > > Už jsem trochu pochopil, jak se agent rozhoduje, zda provede tu či onu
            > > akci - závisí to na kombinaci UNCERTAINITY a SATISFACTION:
            > >
            > > hiS + lowU = REPETITION (chovám se stejně, jako v minulém kole)
            > >
            > > lowS + lowU = DELIBERATION (spočítám si, jak by vypadala moje SATISFACTION
            > > v tom či onom případě mého vlastního chování - tady mám dotaz: při DELIB se
            > > zohledňuje jen SAT, nebo se do DELIB zahrnuje také UNCERT? Přijde mi to
            > > důležité, neb obojí dává smysl - DELIB může být definovaná jako proces,
            > > který řeší jen SAT, ale také jako proces, který řeší celkový well-being,
            > > tedy SAT+UNCERT)
            > >
            > > hiS + hiU = IMITATION (chovám se tak, jak se chovají moji sousedi - hmm...
            > > tohle mi překvapilo, tu jednoznačnou imitaci bych čekal spíš v situaci lowS
            > > + hiU, protože tam jsem komplet v háji a moje SAT a UNCERT se mohou imitací
            > > jen zlepšit, tady si přeci můžu imitací pokazit SAT, které je hiS, ale může
            > > to po imitaci klesnout na lowS, můžete to znovu zkontrolovat?)
            > >
            > > lowS + hiU = COMPARISON (porovnám si, mojí SAT, která plyne z mého
            > > chování, s tím, jaká by SAT byla, kdybych se choval, jako se převážně chová
            > > moje okolí, a vyberu si to, co mi dává vyšší SAT - tady mám opět podobný
            > > dotaz: při COMP se zohledňuje jen SAT, nebo se do COMP zahrnuje také
            > > UNCERT? Přijde mi to důležité, neb obojí dává smysl - COMP může být
            > > definovaná jako proces, který řeší jen SAT, ale také jako proces, který
            > > řeší celkový well-being, tedy SAT+UNCERT)
            > >
            > > Ještě mi napadá, jestli jsou ty proměnné, 4, jestli nejsou jen dvě:
            > > VNITŘNÍ/SATISFACTION a VNĚJŠÍ/UNCERTAINITY?
            > >
            > > A poslední:
            > > Jak se určuje, kdy je SAT a UNCERT hi nebo low? Je tam nějaká prahová
            > > hodnota jako parametr, se kterým se dá manipulovat? Má každý ty prahy
            > > jinak? Nebo se jejich velikost neporovnává s prahem, ale prostě se to nějak
            > > vypočte? Zkrátka, jak agent dojde k tomu, že má SAT a UNCERT hi nebo low?
            > >
            > > Jinak, teď mi proces z hlediska agenta přijde takto - opratve mne, prosím:
            > > 1) určím své hodnoty SAT a UNCERT (sleduji sebe a svoje síťové okolí)
            > > 2) určím jestli jsou SAT a UNCERT hi nebo low
            > > 3) podle kombinace hi/lowS + hi/lowU vyberu proceduru pro určení chování v
            > > tomto kole
            > > 4) aplikuji proceduru, zvolím chování v tomto kole (eco un/friendly)
            > >
            > >
            > >
            > > S úctou,
            > > František
            > >
            > >
            > >  Pondělí, 4 Březen, 2019 09:51 CET, Michaela Kudrnáčová <
            > > kudrnacova.m@gmail.com> napsal:
            > >
            > > > Dobré dopoledne,
            > > >
            > > > Proces je následující: každý agent si spočítá level nejistoty
            > > (uncertainty)
            > > > a spokojenosti (satisfaction) konzistence postojů a chování, pak je
            > > > postaven před volbu, zda se zachovat ekologicky nebo ne podle jedné ze
            > > čtyř
            > > > procedur: repetition, imitation, deliberation and social comparison
            > > > (Janssen and Jager 2002), přičemž pro agenty je důležité zvýšit celkovou
            > > > spokojenost (satisfaction) a snížit nejistotu (uncertainty) při této
            > > volbě
            > > > procedury.
            > > > REPETITION: Agenti s vysokou potřebou spokojenosti (need satisfaction) a
            > > > nízkou nejistotou (low uncertainty) zopakují předchozí volbu.
            > > > DELIBERATION: Agenti s nízkou spokojeností a nízkou nejistotou si
            > > spočítají
            > > > očekávanou spokojenost (tj. konzistence postojů a chování) a podle toho
            > > si
            > > > vyberou, jak se zachovají (ekologicky nebo ne.
            > > > IMITATION: Agenti s vysokou úrovní spokojenosti a vysokou nejistotou
            > > budou
            > > > imitovat chování jejich sousedů.
            > > > SOCIAL COMPARISON: Nespokojení a nejistí agenti si porovnají, jaká by
            > > byla
            > > > jejich úroveň spokojenosti, kdyby se zachovali stejně, jako předtím, s
            > > > úrovní spokojenosti, která by plynula z chování jejich sousedů
            > > >
            > > > Snad to takhle dává větší smysl. Je to právě na základě toho článku
            > > > (Janssen and Jager 2002) a už jsem to viděla použité u nejméně jednoho
            > > > modelu určitě.
            > > >
            > > > S pozdravem,
            > > > Míša
            > > >
            > > >
            > > > ne 3. 3. 2019 v 22:42 odesílatel PhDr. Mgr. Frantisek Kalvas Ph.D. <
            > > > kalvas@kss.zcu.cz> napsal:
            > > >
            > > > > Hmm... Už jsem leccos pochopil, ale potřebuji detailně napsat lidskou
            > > > > řečí, jak probíhá jeden krok simulace, tj. potřebuji zpřesnit 3.
            > > Process
            > > > > overview. Popište mi to normálně lidsky:
            > > > >
            > > > > "Agent na začátku kola zjistí, jak se chovali jeho sousedé v síti,
            > > > > zaznamená počet, kolik z nich se chovalo stejně, uloží si to do
            > > proměnné
            > > > > sameActingNeis, potom..." atd.
            > > > >
            > > > > Ale už je mi jasné, že ti agenti balancují svůj postoj, svoje chování a
            > > > > chování ostatních, a že někdo víc inklinuje k tomu sladit svůj postoj a
            > > > > svoje chování a někdo víc klade důraz na sladění svého a cizího
            > > chování.
            > > > > Ale zatím mi není jasné, kdy a proč by měl agent svoje chování měnit -
            > > > > řekněme, kdyby každý volil chování na úvod náhodně, proč by ho měl
            > > měnit,
            > > > > na základě čeho, co s čím porovnává, aby došel k závěru, že není
            > > spokojený
            > > > > a jak dojde k závěru, že má provést změnu, nebo nespokojenost vždy
            > > vede ke
            > > > > změně? Tohle mi z toho pořád není jasné...
            > > > >
            > > > >
            > > > >
            > > > > S úctou,
            > > > > František
   


      


## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experimentV01" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [simSorting = 1]</metric>
    <metric>count turtles with [simSorting = 2]</metric>
    <metric>count turtles with [simSorting = 3]</metric>
    <metric>count turtles with [simSorting = 4]</metric>
    <steppedValueSet variable="RS" first="1" step="1" last="30"/>
    <enumeratedValueSet variable="pReverseSorting">
      <value value="0.085"/>
      <value value="0.125"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauN">
      <value value="0.35"/>
      <value value="0.45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauU">
      <value value="0.5"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <steppedValueSet variable="closeLinks" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="randomLinks">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSeed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sortingPrice">
      <value value="1.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff12">
      <value value="0.095"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff23">
      <value value="0.495"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff34">
      <value value="0.805"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="steps">
      <value value="105"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentV02" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [simSorting = 1]</metric>
    <metric>count turtles with [simSorting = 2]</metric>
    <metric>count turtles with [simSorting = 3]</metric>
    <metric>count turtles with [simSorting = 4]</metric>
    <steppedValueSet variable="RS" first="31" step="1" last="100"/>
    <enumeratedValueSet variable="pReverseSorting">
      <value value="0.085"/>
      <value value="0.125"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauN">
      <value value="0.35"/>
      <value value="0.45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauU">
      <value value="0.5"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <steppedValueSet variable="closeLinks" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="randomLinks">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSeed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sortingPrice">
      <value value="1.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff12">
      <value value="0.095"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff23">
      <value value="0.495"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff34">
      <value value="0.805"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="steps">
      <value value="105"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentV03" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [simSorting = 1]</metric>
    <metric>count turtles with [simSorting = 2]</metric>
    <metric>count turtles with [simSorting = 3]</metric>
    <metric>count turtles with [simSorting = 4]</metric>
    <steppedValueSet variable="RS" first="101" step="1" last="200"/>
    <enumeratedValueSet variable="pReverseSorting">
      <value value="0.085"/>
      <value value="0.125"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauN">
      <value value="0.35"/>
      <value value="0.45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauU">
      <value value="0.5"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <steppedValueSet variable="closeLinks" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="randomLinks">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSeed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sortingPrice">
      <value value="1.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff12">
      <value value="0.095"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff23">
      <value value="0.495"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff34">
      <value value="0.805"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="steps">
      <value value="105"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentV04" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [simSorting = 1]</metric>
    <metric>count turtles with [simSorting = 2]</metric>
    <metric>count turtles with [simSorting = 3]</metric>
    <metric>count turtles with [simSorting = 4]</metric>
    <steppedValueSet variable="RS" first="201" step="1" last="400"/>
    <enumeratedValueSet variable="pReverseSorting">
      <value value="0.085"/>
      <value value="0.125"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauN">
      <value value="0.35"/>
      <value value="0.45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauU">
      <value value="0.5"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <steppedValueSet variable="closeLinks" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="randomLinks">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSeed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sortingPrice">
      <value value="1.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff12">
      <value value="0.095"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff23">
      <value value="0.495"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff34">
      <value value="0.805"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="steps">
      <value value="105"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentV05" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [simSorting = 1]</metric>
    <metric>count turtles with [simSorting = 2]</metric>
    <metric>count turtles with [simSorting = 3]</metric>
    <metric>count turtles with [simSorting = 4]</metric>
    <steppedValueSet variable="RS" first="401" step="1" last="600"/>
    <enumeratedValueSet variable="pReverseSorting">
      <value value="0.085"/>
      <value value="0.125"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauN">
      <value value="0.35"/>
      <value value="0.45"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauU">
      <value value="0.5"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <steppedValueSet variable="closeLinks" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="randomLinks">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSeed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sortingPrice">
      <value value="1.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff12">
      <value value="0.095"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff23">
      <value value="0.495"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff34">
      <value value="0.805"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="steps">
      <value value="105"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentV07" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [simSorting = 1]</metric>
    <metric>count turtles with [simSorting = 2]</metric>
    <metric>count turtles with [simSorting = 3]</metric>
    <metric>count turtles with [simSorting = 4]</metric>
    <steppedValueSet variable="RS" first="1" step="1" last="600"/>
    <enumeratedValueSet variable="pReverseSorting">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauN">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauU">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="closeLinks" first="3" step="1" last="3"/>
    <enumeratedValueSet variable="randomLinks">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSeed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sortingPrice">
      <value value="1.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff12">
      <value value="0.105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff23">
      <value value="0.495"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff34">
      <value value="0.875"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="steps">
      <value value="105"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentV06" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [simSorting = 1]</metric>
    <metric>count turtles with [simSorting = 2]</metric>
    <metric>count turtles with [simSorting = 3]</metric>
    <metric>count turtles with [simSorting = 4]</metric>
    <steppedValueSet variable="RS" first="601" step="1" last="1600"/>
    <enumeratedValueSet variable="pReverseSorting">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauN">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauU">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="closeLinks" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="randomLinks">
      <value value="0.05"/>
      <value value="0.1"/>
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSeed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sortingPrice">
      <value value="1.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff12">
      <value value="0.105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff23">
      <value value="0.495"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff34">
      <value value="0.875"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="steps">
      <value value="105"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sensitivityTest" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [simSorting = 1]</metric>
    <metric>count turtles with [simSorting = 2]</metric>
    <metric>count turtles with [simSorting = 3]</metric>
    <metric>count turtles with [simSorting = 4]</metric>
    <steppedValueSet variable="RS" first="601" step="1" last="1600"/>
    <enumeratedValueSet variable="pReverseSorting">
      <value value="0.05"/>
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauN">
      <value value="0.3"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauU">
      <value value="0.4"/>
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="closeLinks">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomLinks">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSeed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sortingPrice">
      <value value="1"/>
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff12">
      <value value="0.105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff23">
      <value value="0.495"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff34">
      <value value="0.875"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="steps">
      <value value="105"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentV08" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [simSorting = 1]</metric>
    <metric>count turtles with [simSorting = 2]</metric>
    <metric>count turtles with [simSorting = 3]</metric>
    <metric>count turtles with [simSorting = 4]</metric>
    <steppedValueSet variable="RS" first="1" step="1" last="300"/>
    <enumeratedValueSet variable="pReverseSorting">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauN">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauU">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="closeLinks" first="1" step="1" last="5"/>
    <enumeratedValueSet variable="randomLinks">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSeed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomNeis?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sortingPrice">
      <value value="1.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff12">
      <value value="0.105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff23">
      <value value="0.495"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff34">
      <value value="0.875"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="steps">
      <value value="105"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experimentV08b" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [simSorting = 1]</metric>
    <metric>count turtles with [simSorting = 2]</metric>
    <metric>count turtles with [simSorting = 3]</metric>
    <metric>count turtles with [simSorting = 4]</metric>
    <steppedValueSet variable="RS" first="1" step="1" last="300"/>
    <enumeratedValueSet variable="pReverseSorting">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauN">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tauU">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="closeLinks" first="6" step="1" last="10"/>
    <enumeratedValueSet variable="randomLinks">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSeed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomNeis?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sortingPrice">
      <value value="1.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff12">
      <value value="0.105"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff23">
      <value value="0.495"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cutoff34">
      <value value="0.875"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="steps">
      <value value="105"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
