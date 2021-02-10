#/bin/ksh
#

case="GSL19"
case2="GSL14"
case3="GSL15"
simu="ens01"
var="socurloverf"
var="sosstsst"
var="sosaline"
var="sossheig"
domain="dom1"
lagtime="480" # 20 days
lagtime="24" # 1 day
lagtime="240" # 10 days
lagtime="120" # 5 days
lagtime="48" # 2 days
tottime="1440"

maxval="0.005"
maxval="0.3"
maxval="0.16"
maxval="0.13"
maxval="0.05"

wdir="${WORK}/Immerse"
idir="${case}-${simu}-${domain}-crps"

cd $wdir

cp Figures/pred-crps_${case}-${simu}-${domain}-${var}-${lagtime}.txt tmpsorted1.txt
cp Figures/pred-crps_${case2}-${simu}-${domain}-${var}-${lagtime}.txt tmpsorted2.txt
cp Figures/pred-crps_${case3}-${simu}-${domain}-${var}-${lagtime}.txt tmpsorted3.txt

rm -f tmpquantile*.txt

lmax=`wc -l tmpsorted1.txt|cut -f1 -d' '`
let l0=1 ; let dl=960 ; let quantile_a=48 ; let quantile_b=480 ; let quantile_c=912
while [ $l0 -le $lmax ] ; do
  let l1=$l0+$dl
  let l1=$l1-1

  head -$l1 tmpsorted1.txt | tail -$dl > tmpblock.txt
  cat tmpblock.txt | cut -f1 | sort -g > tmpinitial.txt
  cat tmpblock.txt | cut -f2 | sort -g > tmpfinal.txt
  cat tmpinitial.txt | head -$quantile_a | tail -1 > tmpquantini.txt
  cat tmpfinal.txt | head -$quantile_a | tail -1 > tmpquantfin.txt
  paste tmpquantini.txt tmpquantfin.txt >> tmpquantile1a.txt

  head -$l1 tmpsorted1.txt | tail -$dl > tmpblock.txt
  cat tmpblock.txt | cut -f1 | sort -g > tmpinitial.txt
  cat tmpblock.txt | cut -f2 | sort -g > tmpfinal.txt
  cat tmpinitial.txt | head -$quantile_b | tail -1 > tmpquantini.txt
  cat tmpfinal.txt | head -$quantile_b | tail -1 > tmpquantfin.txt
  paste tmpquantini.txt tmpquantfin.txt >> tmpquantile1b.txt

  head -$l1 tmpsorted1.txt | tail -$dl > tmpblock.txt
  cat tmpblock.txt | cut -f1 | sort -g > tmpinitial.txt
  cat tmpblock.txt | cut -f2 | sort -g > tmpfinal.txt
  cat tmpinitial.txt | head -$quantile_c | tail -1 > tmpquantini.txt
  cat tmpfinal.txt | head -$quantile_c | tail -1 > tmpquantfin.txt
  paste tmpquantini.txt tmpquantfin.txt >> tmpquantile1c.txt

   head -$l1 tmpsorted2.txt | tail -$dl > tmpblock.txt
  cat tmpblock.txt | cut -f1 | sort -g > tmpinitial.txt
  cat tmpblock.txt | cut -f2 | sort -g > tmpfinal.txt
  cat tmpinitial.txt | head -$quantile_a | tail -1 > tmpquantini.txt
  cat tmpfinal.txt | head -$quantile_a | tail -1 > tmpquantfin.txt
  paste tmpquantini.txt tmpquantfin.txt >> tmpquantile2a.txt

  head -$l1 tmpsorted2.txt | tail -$dl > tmpblock.txt
  cat tmpblock.txt | cut -f1 | sort -g > tmpinitial.txt
  cat tmpblock.txt | cut -f2 | sort -g > tmpfinal.txt
  cat tmpinitial.txt | head -$quantile_b | tail -1 > tmpquantini.txt
  cat tmpfinal.txt | head -$quantile_b | tail -1 > tmpquantfin.txt
  paste tmpquantini.txt tmpquantfin.txt >> tmpquantile2b.txt

  head -$l1 tmpsorted2.txt | tail -$dl > tmpblock.txt
  cat tmpblock.txt | cut -f1 | sort -g > tmpinitial.txt
  cat tmpblock.txt | cut -f2 | sort -g > tmpfinal.txt
  cat tmpinitial.txt | head -$quantile_c | tail -1 > tmpquantini.txt
  cat tmpfinal.txt | head -$quantile_c | tail -1 > tmpquantfin.txt
  paste tmpquantini.txt tmpquantfin.txt >> tmpquantile2c.txt

  head -$l1 tmpsorted3.txt | tail -$dl > tmpblock.txt
  cat tmpblock.txt | cut -f1 | sort -g > tmpinitial.txt
  cat tmpblock.txt | cut -f2 | sort -g > tmpfinal.txt
  cat tmpinitial.txt | head -$quantile_a | tail -1 > tmpquantini.txt
  cat tmpfinal.txt | head -$quantile_a | tail -1 > tmpquantfin.txt
  paste tmpquantini.txt tmpquantfin.txt >> tmpquantile3a.txt

  head -$l1 tmpsorted3.txt | tail -$dl > tmpblock.txt
  cat tmpblock.txt | cut -f1 | sort -g > tmpinitial.txt
  cat tmpblock.txt | cut -f2 | sort -g > tmpfinal.txt
  cat tmpinitial.txt | head -$quantile_b | tail -1 > tmpquantini.txt
  cat tmpfinal.txt | head -$quantile_b | tail -1 > tmpquantfin.txt
  paste tmpquantini.txt tmpquantfin.txt >> tmpquantile3b.txt

  head -$l1 tmpsorted3.txt | tail -$dl > tmpblock.txt
  cat tmpblock.txt | cut -f1 | sort -g > tmpinitial.txt
  cat tmpblock.txt | cut -f2 | sort -g > tmpfinal.txt
  cat tmpinitial.txt | head -$quantile_c | tail -1 > tmpquantini.txt
  cat tmpfinal.txt | head -$quantile_c | tail -1 > tmpquantfin.txt
  paste tmpquantini.txt tmpquantfin.txt >> tmpquantile3c.txt

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
set lmargin 9
set rmargin 5
set xtics font 'arial bold,32'
set xtics offset 0,-1,0
set xrange [0:${maxval}]
set ytics font 'arial bold,32'
set yrange [0:${maxval}]
unset key
set style line 1 lc rgb "black" lw 5 lt 1
set style line 2 lc rgb "green" lw 2 lt 1
set style line 3 lc rgb "blue" lw 5 lt 1
set style line 4 lc rgb "red" lw 2 lt 1
set style line 5 lc rgb "green" lw 5 lt 1
set style line 6 lc rgb "red" lw 5 lt 1
set style line 7 lc rgb "blue" lw 2 lt 1
set style line 8 lc rgb 'blue' pt 7 ps 0.1 # circle
plot [0:${maxval}] "tmpquantile1a.txt" u 1:2 w l ls 2, "tmpquantile1b.txt" u 1:2 w l ls 5, "tmpquantile1c.txt" u 1:2 w l ls 2, "tmpquantile2a.txt" u 1:2 w l ls 7, "tmpquantile2b.txt" u 1:2 w l ls 3, "tmpquantile2c.txt" u 1:2 w l ls 7, "tmpquantile3a.txt" u 1:2 w l ls 4, "tmpquantile3b.txt" u 1:2 w l ls 6, "tmpquantile3c.txt" u 1:2 w l ls 4
exit
EOF

rm -f Figures/pred3-crps_${case}-${case2}-${case3}-${simu}-${domain}-${var}-${lagtime}.jpg

gnuplot < graphe.gp
convert -density 300 tmp.ps Figures/pred-crps_${case}-${case2}-${case3}-${simu}-${domain}-${var}-${lagtime}.jpg
rm -f graphe.gp tmp.ps
rm -f tmp*.txt

