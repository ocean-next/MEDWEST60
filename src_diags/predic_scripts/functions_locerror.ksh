#!/bin/ksh
# 

# Compute location error
# ----------------------
#
function compute_locerror {

  f_true_member=$1
  f_hour=$2

  truemembertag=`echo $f_true_member | awk '{printf("%03d", $1)}'`
  hourtag=`echo $f_hour | awk '{printf("%04d", $1)}'`

  cd $wdir

  ln -sf ${idir}/${var}_m${truemembertag}_h${hourtag}.nc ./ft_${ftype}.nc
  rm -f zsort_${ftype}.nc zquant_${ftype}.nc
  sesam -mode oper -invar ft_"#".nc -outvar zsort_"#".nc -typeoper quantiles_20 > /dev/null
  sesam -mode oper -invar ft_"#".nc -outvar zquant_"#".nc -typeoper quantize_20 > /dev/null

  for member in $(seq 1 $nmember) ; do
    membertag=`echo $member | awk '{printf("%03d", $1)}'`

    if [ ${member} -ne ${f_true_member} ] ; then

      ln -sf ${idir}/${var}_m${membertag}_h${hourtag}.nc ./f_${ftype}.nc

      rm -f zquan_${ftype}.nc zlocerror_${ftype}.nc
      sesam -mode oper -invar f_"#".nc -outvar zquan_"#".nc -typeoper quantize_20 > /dev/null
      sesam -mode oper -invar zquan_"#".nc -invarref zquant_"#".nc -outvar zlocerror_"#".nc -typeoper locerror > /dev/null
      mv quantiles.txt quantiles.txt.bak
      sesam -mode oper -invar zlocerror_"#".nc -outvar zsort_"#".nc -typeoper quantiles_10 > /dev/null
      locerror=`tail -2 quantiles.txt | head -1`
      mv quantiles.txt.bak quantiles.txt
      echo "${truemembertag} $membertag $hourtag $locerror" >> $odir/locerror_t${truemembertag}_m${membertag}_${var}.txt
      echo "${truemembertag} $membertag $hourtag $locerror"
      mv zquan_${ftype}.nc ${idir}/${var}_m${membertag}_h${hourtag}_quan.nc
      mv zlocerror_${ftype}.nc ${idir}/${var}_m${membertag}_h${hourtag}_locerror.nc

    fi

  done

}

