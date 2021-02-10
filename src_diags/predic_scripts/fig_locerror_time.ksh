#/bin/ksh
#

case="GSL19"
case2="GSL14"
case3="GSL15"
simu="ens01"
var="sosstsst"
var="sosaline"
domain="dom1"

maxval="80"

wdir="${WORK}/Immerse"
idir="${case}-${simu}-${domain}-locerror"
idir2="${case2}-${simu}-${domain}-locerror"
idir3="${case3}-${simu}-${domain}-locerror"

#figfile="Figures/locerror_${case}-${simu}-${domain}-${var}.jpg"
figfile="Figures/locerror_${case}-${case3}-${simu}-${domain}-${var}.jpg"

cd $wdir

plotlist=""
let nmember=20
for tmember in $(seq 1 $nmember) ; do
for member in $(seq 1 $nmember) ; do
  ttag=`echo $tmember | awk '{printf("%03d", $1)}'`
  mtag=`echo $member | awk '{printf("%03d", $1)}'`
  if [ $member -ne $tmember ] ; then
    ifile="${idir}/locerror_t${ttag}_m${mtag}_${var}.txt"
    plotlist="$plotlist \"$ifile\" u 3:4 w l ls 7,"
    #plotlist="$plotlist \"$ifile\" u 3:4 w l ls 5,"
    #ifile="${idir2}/locerror_t${ttag}_m${mtag}_${var}.txt"
    #plotlist="$plotlist \"$ifile\" u 3:4 w l ls 7,"
    ifile="${idir3}/locerror_t${ttag}_m${mtag}_${var}.txt"
    plotlist="$plotlist \"$ifile\" u 3:4 w l ls 4,"
  fi
done
done

echo $plotlist

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
set style line 4 lc rgb "red" lw 1 lt 1
set style line 5 lc rgb "green" lw 1 lt 1
set style line 6 lc rgb "red" lw 5 lt 1
set style line 7 lc rgb "blue" lw 1 lt 1
plot [1:1440] $plotlist
exit
EOF

gnuplot < graphe.gp
convert -density 200 tmp.ps $figfile
#rm -f graphe.gp tmp.ps

