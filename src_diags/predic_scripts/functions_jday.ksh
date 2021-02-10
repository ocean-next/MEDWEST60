#!/bin/ksh
#

# A.1 - Get number of days in a year
# ----------------------------------
#
function get_daysinyear {

   gdy_year=$1

   leap_year=$( echo "scale=0;${gdy_year}%4" | bc -l )

   if [ ${leap_year} -eq 0 ] ; then
      daysinyear='366'
   else
      daysinyear='365'
   fi

}

# A.2 - Get number of days in a month
# -----------------------------------
#
function get_daysinmonth {

   gdm_month=$1
   gdm_year=$2

   leap_year=$( echo "scale=0;${gdm_year}%4" | bc -l )

   case ${gdm_month} in
     1 ) daysinmonth=31 ;;
     2 ) daysinmonth=28 ;;
     3 ) daysinmonth=31 ;;
     4 ) daysinmonth=30 ;;
     5 ) daysinmonth=31 ;;
     6 ) daysinmonth=30 ;;
     7 ) daysinmonth=31 ;;
     8 ) daysinmonth=31 ;;
     9 ) daysinmonth=30 ;;
    10 ) daysinmonth=31 ;;
    11 ) daysinmonth=30 ;;
    12 ) daysinmonth=31 ;;
   esac

   if [ ${gdm_month} = '2' ] ; then
      if [ ${leap_year} -eq 0 ] ; then
         daysinmonth=29
      fi
   fi

}

# A.3 - Convert Julian day to date
# --------------------------------
#
function jday2date {

   ts_jday=$1

   let ts_year=1950
   let ts_month=1
   let ts_day=1
   let ts_jday0=-1

   while [ $ts_jday0 -lt $ts_jday ]
   do
     get_daysinyear $ts_year
     let ts_year=$ts_year+1
     let ts_jday0=$ts_jday0+$daysinyear
   done
   let ts_year=$ts_year-1
   let ts_jday0=$ts_jday0-$daysinyear

   ts_dayinyear=$( echo "$ts_jday - $ts_jday0" | bc -l )

   while [ $ts_jday0 -lt $ts_jday ]
   do
     get_daysinmonth $ts_month $ts_year
     let ts_month=$ts_month+1
     let ts_jday0=$ts_jday0+$daysinmonth
   done
   let ts_month=$ts_month-1
   let ts_jday0=$ts_jday0-$daysinmonth

   ts_day=$( echo "$ts_jday - $ts_jday0" | bc -l )

   ts_day=`echo $ts_day | awk '{printf("%02d", $1)}'`
   ts_month=`echo $ts_month | awk '{printf("%02d", $1)}'`
   ts_year=`echo $ts_year | awk '{printf("%04d", $1)}'`

   ts_date="${ts_year}${ts_month}${ts_day}"

}

# A.4 - Convert date to Julian day
# --------------------------------
#
function date2jday {

   ts_date=$1

   ts_year=`echo ${ts_date}|cut -c1-4`
   ts_month=`echo ${ts_date}|cut -c5-6`
   ts_day=`echo ${ts_date}|cut -c7-8`

   let ts_jday=$ts_day-1

   let ts_month_idx=1
   while [ $ts_month_idx -lt $ts_month ]
   do
     get_daysinmonth $ts_month_idx $ts_year
     let ts_jday=$ts_jday+$daysinmonth
     let ts_month_idx=$ts_month_idx+1
   done

   let ts_year_idx=1950
   while [ $ts_year_idx -lt $ts_year ]
   do
     get_daysinyear $ts_year_idx
     let ts_jday=$ts_jday+$daysinyear
     let ts_year_idx=$ts_year_idx+1
   done

}
