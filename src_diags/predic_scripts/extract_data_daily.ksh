#!/bin/ksh
  
. ./functions_jday.ksh

dirbase="/gpfsstore/rech/egi/commun"
config="MEDWEST60"
case="GSL19"
case="GSL14"
case="GSL15"
simu="ens01"
freq="1h"
ftype="curloverf-2D"
ftype="gridT-2D"
var="sossheig"
var="socurloverf"
var="sosstsst"
var="sosaline"
domain="dom1"

idir="${dirbase}/${config}/${config}-${case}-S/${simu}/${freq}/${ftype}"
odir="${SCRATCH}/Immerse/${case}-${simu}-${domain}"

if [ ! -d $odir ] ; then
  mkdir $odir
fi

member_ini="1"
member_end="20"
date_ini="20100206"
date_ini="20100205"
date_end="20100406"
date_end="20100405"

imin=`grep imin region_${domain} | cut -d"=" -f2`
imax=`grep imax region_${domain} | cut -d"=" -f2`
jmin=`grep jmin region_${domain} | cut -d"=" -f2`
jmax=`grep jmax region_${domain} | cut -d"=" -f2`

date2jday ${date_ini}
jday_ini=$ts_jday
date2jday ${date_end}
jday_end=$ts_jday

let member=${member_ini}
while [ $member -le ${member_end} ] ; do
  membertag=`echo $member | awk '{printf("%03d", $1)}'`

  let hour=0
  let jday=${jday_ini}
  while [ $jday -le ${jday_end} ] ; do
    jday2date $jday
    date=$ts_date
    ifile=`ls ${idir}/${membertag}*${date}-${date}.nc`

    let hourinday=23
    let hour=$hour+24
    hourtag=`echo $hour | awk '{printf("%04d", $1)}'`
    ofile="${odir}/${var}_m${membertag}_h${hourtag}.nc"
    rm -f $ofile
    ncks -d x,${imin},${imax} -d y,${jmin},${jmax} \
         -d time_counter,${hourinday},${hourinday} \
         -v nav_lat,nav_lon,${var} ${ifile} ${ofile}

    let jday=$jday+1
  done

  let member=$member+1
done

