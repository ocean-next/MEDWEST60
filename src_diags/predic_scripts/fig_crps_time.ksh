#/bin/ksh
#

case="GSL14"
case="GSL19"
simu="ens01"
var="socurloverf"
var="sossheig"
var="sosstsst"
var="sosaline"
domain="dom1"

maxval="0.3"
maxval="0.05"
maxval="0.16"
maxval="0.13"

wdir="${WORK}/Immerse"
idir="${case}-${simu}-${domain}-crps"

cd $wdir

cat <<EOF > graphe.gp
#!/usr/bin/gnuplot
#
set term postscript eps color enhanced
set output 'tmp.ps'
set size 1,1.3
set tmargin 2
set bmargin 3
set lmargin 9
set rmargin 3
set xtics font 'arial bold,32'
set xtics offset 0,-1,0
set xtics (240,480,720,960,1200)
set xrange [1:1440]
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
plot [1:1440] "${idir}/crps_m001_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m002_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m003_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m004_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m005_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m006_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m007_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m008_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m009_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m010_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m011_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m012_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m013_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m014_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m015_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m016_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m017_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m018_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m019_${var}.txt" u 2:5 w l ls 7, "${idir}/crps_m020_${var}.txt" u 2:5 w l ls 7,
exit
EOF

gnuplot < graphe.gp
convert -density 200 tmp.ps Figures/crps_${case}-${simu}-${domain}-${var}.jpg
rm -f graphe.gp tmp.ps

