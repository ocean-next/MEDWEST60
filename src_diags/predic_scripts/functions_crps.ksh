#!/bin/ksh
# 

# A.1 - Prepare ensemble without truth
# ------------------------------------
#
function prepare_ensemble {

  f_true_member=$1
  f_hour=$2

  hourtag=`echo $f_hour | awk '{printf("%04d", $1)}'`
  nmembertag=`echo $nmember 1 | awk '{printf("%04d", $1 - $2)}'`

  ensdir="ENS${nmembertag}.nc.bas"
  rm -fr ${ensdir} ; mkdir ${ensdir} ; cd ${ensdir}

  let kept_member=1
  for member in $(seq 1 $nmember) ; do
    membertag=`echo $member | awk '{printf("%03d", $1)}'`
    if [ ${member} -ne ${f_true_member} ] ; then
      kmembertag=`echo $kept_member | awk '{printf("%04d", $1)}'`
      ln -s ${idir}/${var}_m${membertag}_h${hourtag}.nc ./vct${ftype}${kmembertag}.nc
      let kept_member=${kept_member}+1
    fi
  done

  cd $wdir
  membertag=`echo $f_true_member | awk '{printf("%03d", $1)}'`
  ln -sf ${idir}/${var}_m${membertag}_h${hourtag}.nc ./truth_${ftype}.nc

}

# A.2 - Compute CRPS score
# ------------------------
#
function compute_crps {

  f_true_member=$1
  f_hour=$2

  membertag=`echo $f_true_member | awk '{printf("%03d", $1)}'`
  hourtag=`echo $f_hour | awk '{printf("%04d", $1)}'`

  cd $wdir

  nmembertag=`echo $nmember 1 | awk '{printf("%04d", $1 - $2)}'`
  ensdir="ENS${nmembertag}.nc.bas"

  crps=`sesam -mode scor -inxbas ${ensdir} -invar truth_"#".nc -typeoper crps -inpartvar score_mask_#.nc | tail -1 | cut -c17-`
  echo "$membertag $hourtag $crps" >> $odir/crps_m${membertag}_${var}.txt

}

