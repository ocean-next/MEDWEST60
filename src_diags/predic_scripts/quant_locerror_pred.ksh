#/bin/ksh
#

case="GSL15"
case="GSL14"
case="GSL19"
simu="ens01"
var="socurloverf"
var="sosaline"
var="sossheig"
var="sosstsst"
domain="dom1"
lagtime="30" # 30 days
tottime="60"
lagtime="5" # 5 days
lagtime="1" # 1 day
lagtime="20" # 20 days
lagtime="2" # 2 days
lagtime="10" # 10 days
lagtime="15" # 15 day

zoom=""
maxval="50"
maxval="20" ; zoom="-zoom"

wdir="${WORK}/Immerse"
idir="${case}-${simu}-${domain}-locerror"

cd $wdir

cp Figures/pred-locerror_${case}-${simu}-${domain}-${var}-${lagtime}.txt tmpsorted.txt

rm -f tmpquantile.txt

lmax=`wc -l tmpsorted.txt|cut -f1 -d' '`
let l0=1 ; let dl=960 ; let quantile=48 ; let median=48
while [ $l0 -le $lmax ] ; do
  let l1=$l0+$dl
  let l1=$l1-1
  #head -$l1 tmpsorted.txt | tail -$dl | sort -g | head -$quantile | tail -1 >> tmpquantile.txt
  head -$l1 tmpsorted.txt | tail -$dl > tmpblock.txt
  cat tmpblock.txt | cut -f1 | sort -g > tmpinitial.txt
  cat tmpblock.txt | cut -f2 | sort -g > tmpfinal.txt
  cat tmpinitial.txt | head -$quantile | tail -1 > tmpquantini.txt
  cat tmpfinal.txt | head -$median | tail -1 > tmpquantfin.txt
  paste tmpquantini.txt tmpquantfin.txt >> tmpquantile.txt
  let l0=$l1+1
done

mv tmpquantile.txt Figures/pred-qua-locerror_${case}-${simu}-${domain}-${var}-${lagtime}.txt

rm -f tmphead.txt tmptail.txt tmpscore.txt tmpinitial.txt tmpfinal.txt tmpquantile.txt

