#/bin/ksh
#

case="GSL19"
case="GSL14"
case="GSL15"
simu="ens01"
var="socurloverf"
var="sosstsst"
var="sosaline"
var="sossheig"
domain="dom1"
lagtime="480" # 20 days
lagtime="24" # 1 day
lagtime="120" # 5 days
lagtime="240" # 10 days
lagtime="48" # 2 days
tottime="1440"

zoom=""
maxval="0.3"
maxval="0.05"
maxval="0.16"
maxval="0.13"
maxval="0.01" ; zoom="-zoom"

wdir="${WORK}/Immerse"
idir="${case}-${simu}-${domain}-crps"

cd $wdir

nline=$( echo "$tottime - $lagtime" | bc -l )

rm -f tmpscore.txt

let i=1
let m=20
while [ $i -le $m ] ; do
  itag=`echo $i | awk '{printf("%03d", $1)}'`
  head -$nline ${idir}/crps_m${itag}_${var}.txt | cut -c41- > tmphead.txt
  tail -$nline ${idir}/crps_m${itag}_${var}.txt | cut -c41- > tmptail.txt
  paste tmptail.txt tmphead.txt >> tmpscore.txt
  let i=$i+1
done

cat tmpscore.txt | sort -g > tmpsorted.txt
cat tmpsorted.txt | cut -f1 > tmpfinal.txt
cat tmpsorted.txt | cut -f2 > tmpinitial.txt
paste tmpinitial.txt tmpfinal.txt > tmpsorted.txt

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

cat <<EOF > graphe.gp
#!/usr/bin/gnuplot
#
set term postscript eps color enhanced
set output 'tmp.ps'
set size 1,1.3
set tmargin 1
set bmargin 3
#set lmargin 9
set lmargin 11
set rmargin 5
set xtics font 'arial bold,32'
set xtics offset 0,-1,0
set xrange [0:${maxval}]
set ytics font 'arial bold,32'
set yrange [0:${maxval}]
unset key
set style line 1 lc rgb "black" lw 5 lt 1
set style line 2 lc rgb "black" lw 2 lt 1
set style line 3 lc rgb "blue" lw 5 lt 1
set style line 4 lc rgb "red" lw 2 lt 1
set style line 5 lc rgb "green" lw 5 lt 1
set style line 6 lc rgb "red" lw 5 lt 1
set style line 7 lc rgb "blue" lw 2 lt 1
set style line 8 lc rgb 'blue' pt 7 ps 0.1 # circle
plot [0:${maxval}] "tmpsorted.txt" u 1:2 w p ls 8, "tmpquantile.txt" u 1:2 w l ls 5
exit
EOF

rm -f Figures/pred-crps_${case}-${simu}-${domain}-${var}-${lagtime}${zoom}.jpg

gnuplot < graphe.gp
convert -density 300 tmp.ps Figures/pred-crps_${case}-${simu}-${domain}-${var}-${lagtime}${zoom}.jpg
rm -f graphe.gp tmp.ps
mv tmpsorted.txt Figures/pred-crps_${case}-${simu}-${domain}-${var}-${lagtime}.txt
rm -f tmphead.txt tmptail.txt tmpscore.txt tmpinitial.txt tmpfinal.txt tmpquantile.txt

