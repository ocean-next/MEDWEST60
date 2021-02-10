#!/bin/ksh

. ./functions_locerror.ksh

case="GSL19"
case="GSL14"
case="GSL15"
simu="ens01"
ftype="gridT"
var="sossheig"
var="socurloverf"
var="sosaline"
var="sosstsst"
domain="dom1"

sdir="${SCRATCH}/Immerse"
wdir="${WORK}/Immerse"
idir="${sdir}/${case}-${simu}-${domain}"
odir="${wdir}/${case}-${simu}-${domain}-locerror"

if [ ! -d $odir ] ; then
  mkdir $odir
fi

true_member_ini="1"
true_member_end="20"
hour_ini="24"
hour_end="1440"
hour_stp="24"
nmember="20"

# Prepare SESAM input files
cp sesamlist_${var} $wdir/sesamlist

cd $wdir

membertag=`echo $true_member_ini | awk '{printf("%03d", $1)}'`
hourtag=`echo $hour_ini | awk '{printf("%04d", $1)}'`
ln -sf ${idir}/${var}_m${membertag}_h${hourtag}.nc ./mask.nc

ln -sf mask.nc mask_${ftype}.nc
rm -f score_mask_${ftype}.nc
sesam -mode oper -invar mask_#.nc -outvar score_mask_#.nc  -typeoper cst_1 >/dev/null
rm -f mask_${ftype}.nc

date
# Loop on members
let true_member=${true_member_ini}
while [ $true_member -le ${true_member_end} ] ; do
  true_member_tag=`echo $true_member | awk '{printf("%03d", $1)}'`

  rm -f $odir/crps_m${true_member_tag}_${var}.txt

  rm -f $odir/locerror_t${true_member_tag}_m???_${var}.txt
  # Loop on hours
  let hour=${hour_ini}
  while [ $hour -le ${hour_end} ] ; do
    echo "True member: ${true_member_tag}, hour: $hour"
    compute_locerror ${true_member} ${hour}
    let hour=$hour+${hour_stp}
  done

  let true_member=$true_member+1
done
date

