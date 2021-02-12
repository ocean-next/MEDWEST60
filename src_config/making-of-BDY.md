

## These 6 steps are detailed below:

* 1 Refine the MEDWEST domain to avoid potential problems with the bdys and rim.
* 2 Extract MEDWEST domain from eNATL60 on Occigen
* 3 Close look at the grid and bathymetry at the W and E boundaries to choose the namelist parameters for the bdy
* 4 Extract the bdys from the MEDWEST extraction.
* 5 Reformat the bdy files so that they can be read by NEMO.



---
---

# 1. MEDWEST domain:

* I extended the initial MEWEST domain from JMM so that the rim of the bdy doesn't not cut just along the coast just south of cape corse.
  In the end, the final domain with which i have extracted the bathymetry is:

  ```shell
  ncks -4 -L 1 -d x,5529,6411 -d y,1869,2671 eNATL60_coordinates_v3.nc4 MEDWEST60_coordinates_v3.nc4 
  ```

* Regarding the bathymetry, i've also filled in a couple of small areas on the east coast of corsica with ```cdfbathy```. The detailed is given [here](https://github.com/ocean-next/MEDWEST60/blob/main/src_config/making-of-Config.md).

* Note that with the fortran convention, the domain is :

   ```shell
   ncks -F x,5530,6412 y,1870,2672  deptht,1,212 
   ```


---
---

# 2. Extract MEDWEST domain from eNATL60 on Occigen

* eNATL60 outputs are stored on occigen so the extraction was done there too.

* I used script ```xMEDWEST``` inspired by JMM's script. It uses ```cdfclip``` instead of ```ncks``` in order to minimize the memory used. Also, it runs maximum 16 extractions at a time per node. And the script is run on the HPC via sbatch with a 'meta' script that loops over months and years:

  ```shell
  #!/bin/bash
  
  for m in {06..12} ; do
      sbatch -J xtrac$m xMEDWEST $m 2009
  done
  
  for m in {01..10} ; do
     sbatch -J xtrac$m xMEDWEST $m 2010
  done
  ```

* I ran it once per type of files (gridV, gridU, gridT, gridS, gridU-2D, gridV-2D, gridT-2D). Note that for the 2d files, teh script needs to be modified so that cdfclip no longer use ```-klim 1 212``` 

   ```shell
  #!/bin/bash
  #SBATCH --nodes=1
  #SBATCH --ntasks=1
  #SBATCH --ntasks-per-node=28
  #SBATCH --threads-per-core=1
  #SBATCH --constraint=BDW28
  #SBATCH -J NC4
  #SBATCH -e znc4.e%j
  #SBATCH -o znc4.o%j
  #SBATCH --time=4:00:00
  #SBATCH --exclusive
  
  
  if [ $# != 2 ] ; then
       echo "usage : extract_JMM mm yyyy"
       exit
  fi
  
  CONFIG=eNATL60
  CASE=BLBT02
  
  freq=1h
  year=$2
  mm=$1
  
  #CDFCLIP="cdfclip -zoom 5529 6411 1869 2671  -klim 1 198"
  CDFCLIP="cdfclip -zoom 5530 6412 1870 2672  -klim 1 212"
  CONFCASE=${CONFIG}-${CASE}
  
  CONFX=MEDWEST60
  
  ROOTDIR=/store/lbrodeau/${CONFIG}/ORGANIZED/${CONFCASE}-S
  
  
  ###############
  ulimit -s unlimited
  
  
  mkdir -p /store/lerouxst/eNATL60/ZOOMs/MEDWEST60/
  cd /store/lerouxst/eNATL60/ZOOMs/MEDWEST60/
  
  n=0
  for typ in   gridV    ; do
    for f in  ${ROOTDIR}/$typ/${CONFCASE}_${freq}_${year}${mm}??-${year}${mm}??_$typ.nc ; do
       tmp=$( echo $(basename $f) )
       tmp2=$(echo $tmp | awk -F_ '{print $3}' ) ; tmp2=${tmp2%-*}
       yyyy=${tmp2:0:4}
       mm=${tmp2:4:2}
       dd=${tmp2:6:2}
  
       lfs hsm_state $f | grep -q release
       if [ $? = 0 ] ; then
         echo $f released
         # find original name
         fo=$(ls -l $f | awk '{print $NF}')
         lfs hsm_restore $fo
       else
         echo $f
         g=${CONFX}-${CASE}_y${yyyy}m${mm}d${dd}.${freq}_${typ}.nc
         echo $g
  
         if [ ! -f $g ] ; then
            echo xtracting $g
            n=$((n+1))
            lfs setstripe -c 10 $g
            $CDFCLIP  -f $f  -nc4 -o $g   &
            if [ $n = 16 ] ; then
              wait
              n=0
            fi
         fi
       fi
    done
  done
  
  wait                                                                                                                                                 
  ```
---
---

# 3. Choice of the namelist parameters for the bdys

#### - Starting from v3.4 bathymetry

####  - Looked carefully at the boundaries with ```cdfzoom```

```
cdfzoom -f MEDWEST60_Bathymetry_v3.4.nc4 -zoom 1 20 55 85 -v Bathymetry -time 0 0
```

#### - Decisions:

* BD1W (gibraltar): 
  - i=2 to 13 included (12 points)
  - j: 60 to 80.
  - Note: i=13 stops justy before widening of the gibraltar canal.
  - Note: j=60-80: just making sure that its a rectangle and it ends over land on both E and W sides.

* BD2E:
  - choice to extract same width (12 points) as BD1W.
  - has to starts at jpiglo-2 at max meaning i=881
  - i from 870 to 881 (12 points): NOTE: only 5 points ends over land at cap corse. 
  - j from 165 to 795 to make sure the rectangle ends over land on both sides.

  - NOTE: Extraction of gridU swiched (C-grid) ```ncks -F  x,871,882```



---
---

# 4. Extract the bdys from the MEDWEST extracted files on Occigen

* I used script ```xbdy``` inspired by JMM's script. 

* The script is run via sbatch with a "meta" script as above (```meta_xby```)

 ```shell
  #!/bin/bash
  #SBATCH --nodes=1
  #SBATCH --ntasks=1
  #SBATCH --ntasks-per-node=28
  #SBATCH --threads-per-core=1
  #SBATCH --constraint=BDW28
  #SBATCH -J BDY
  #SBATCH -e BDY.e%j
  #SBATCH -o BDY.o%j
  #SBATCH --time=4:00:00
  #SBATCH --exclusive
  
  
  ###############
  ulimit -s unlimited
  
  
  yyyy=$2
  mm=$1
  
  DATADIR=/store/lerouxst/eNATL60/ZOOMs/MEDWEST60
  BDYOUTDIR=x
  
  
  
  cd $DATADIR
  
  n=0
  for typ in   gridS gridT  gridV gridV-2D  gridT-2D   ; do
    for f in  MEDWEST60-BLBT02_y${yyyy}m${mm}d??.1h_${typ}.nc ; do
  
      n=$((n+1))
  
      ncks -F -4 -L 1 -d x,2,13 -d y,60,80 $f BD1W_$f
      ncks -F -4 -L 1 -d x,870,881 -d y,165,795 $f BD2E_$f
  
      if [ $n = 16 ] ; then
         wait
         n=0
      fi
  
    done
  done
  
  
  mv BD1W_*.nc ${BDYOUTDIR}/
  mv BD2E_*.nc ${BDYOUTDIR}/
```


* Same for gridU and gridU-2D with  ```ncks -F -4 -L 1 -d x,871,882 -d y,165,795 $f BD2E_$f``` for eastern boundary.

  



---
---

# 5. Modify file format of the bdy files so that they can be read by NEMO (run on Occigen)

* I used the script ```rbde``` on Occigen.
* the script is run via meta script ```meta_rbde```.
* The Western boundary BD1W is modified so that the variables are written with y (the dimension along the bdy) the rightest dimension in the file
* The Easter boundary BD2E is modified so that the variables are written with y (the dimension along the bdy) the rightest dimension in the file and the x dimension is reversed so that indices fo from the outter values to the inner values.

 ```shell
#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=28
#SBATCH --threads-per-core=1
#SBATCH --constraint=BDW28
#SBATCH -J BDY
#SBATCH -e BDY.e%j
#SBATCH -o BDY.o%j
#SBATCH --time=4:00:00
#SBATCH --exclusive


###############
ulimit -s unlimited


yyyy=$2
mm=$1

BD='BD1W'

BDYOUTDIR=/store/lerouxst/eNATL60/BDY_MEDWEST



cd $BDYOUTDIR

n=0
for typ in gridT gridU gridV gridS gridU-2D gridV-2D gridT-2D    ; do
#for typ in   gridT    ; do
  for f in  ${BD}_MEDWEST60-BLBT02_y${yyyy}m${mm}d??.1h_${typ}.nc ; do

    n=$((n+1))


     # will reverse order of dimensions so that y (along the bdy) is tha rightest dim in the output file)
     # if BDEast, will also reverse the order of the x arrays so that x indicies (perpendicular to the bdy) go from outter to inner values
     if [ "${BD}" = "BD2E" ]
     then
        ncpdq -U -F -a  -x,y $f R_$f
     else
        ncpdq -U -F -a  x,y $f R_$f
     fi

    if [ $n = 16 ] ; then
       wait
       n=0
    fi

  done
done
```

* Finally, concatenate files in 1-YR file. Thes Yearly files for 2009 and 2010 must be completed by "fake" data for the time of year when there is no eNATL data.

* What i did is the following: take the data from the other year, copy it and modify the timestamps so that it becomes "fake" data to complete the given year. See example for 2010 below:

  

  * For 2010:   ```makefakeyearly2010.sh ```

    ```shell
    #!/bin/bash
    #SBATCH --nodes=1
    #SBATCH --ntasks=1
    #SBATCH --ntasks-per-node=28
    #SBATCH --threads-per-core=1
    #SBATCH --constraint=BDW28
    #SBATCH -J f2010
    # SBATCH -e f2010.e%j
    # SBATCH -o f2010.o%j
    # SBATCH --time=00:59:00
    # SBATCH --exclusive
    
    # Purpose: modify time coordinate of 2010 files so that it atrificially becomes 2009 data
    
     ulimit -s unlimited
    
      cd /store/lerouxst/eNATL60/BDY_MEDWEST/
    
      for BD in "R_BD1W" "R_BD2E" ;do
      for typ in gridU gridT gridV gridS "gridT-2D" "gridU-2D" "gridV-2D" ;do
    
      for mm in {11..12} ; do
        for f in  ${BD}_MEDWEST60-BLBT02_y2009m${mm}d??.1h_${typ}.nc ; do
           ncap2 -4 -L 1 -s 'time_counter+=31536000' $f ./fake2010_$f
        done
      done
    
      for dd in {30..31} ; do
           f="${BD}_MEDWEST60-BLBT02_y2009m10d${dd}.1h_${typ}.nc"
           ncap2 -4 -L1 -s 'time_counter+=31536000' $f ./fake2010_$f
      done
    
      done
      done
      
    ```

  

  

  * Script ```concat```:


 ```shell
  #!/bin/bash
      echo "USAGE: concat 2010 BD1W"
      YR=$1
      BD=$2
      for typ in gridT gridU gridV gridS "gridT-2D" "gridU-2D" "gridV-2D" ; do
          ncrcat *R_${BD}*_${typ}.nc YR_${BD}_MEDWEST60-BLBT02_y${YR}.1h_${typ}.nc
      done
 ```

#### NOTE:

* For gridU-2D and gridV-2D, files for 2009 and 2010 don't contain exactly same variable (taux added in 2010 outputs). This difference needs to be delt with.

  - for 2009:

  ```shell
  #!/bin/bash
  # Purpose: modify time coordinate of 2010 files so that it atrificially becomes 2009 data
  
  cd /store/lerouxst/eNATL60/BDY_MEDWEST/
  
  for BD in "R_BD1W" "R_BD2E" ;do
  for typ in "gridV-2D" ;do #gridT gridU gridV
  
  for mm in {01..05} ; do
    for f in  ${BD}_MEDWEST60-BLBT02_y2010m${mm}d??.1h_${typ}.nc ; do
       ncap2 -4 -L 1 -s 'time_counter-=31536000' $f ./prefake2009_$f
       #ncks -v nav_lon,nav_lat,bozocrtx,sozocrtx ./prefake2009_$f ./fake2009_$f
       ncks -v nav_lon,nav_lat,bomecrty,somecrty ./prefake2009_$f ./fake2009_$f
    done
  done
  
  for dd in {01..29} ; do
    f="${BD}_MEDWEST60-BLBT02_y2010m06d${dd}.1h_${typ}.nc"
       ncap2 -4 -L1 -s 'time_counter-=31536000' $f ./prefake2009_$f
       #ncks -v nav_lon,nav_lat,bozocrtx,sozocrtx ./prefake2009_$f ./fake2009_$f
       ncks -v nav_lon,nav_lat,bomecrty,somecrty ./prefake2009_$f ./fake2009_$f
  done
  
  done
  done
  
  ```

   - For 2010 (```gridU2D```):

     ```shell
     #!/bin/bash
     # Purpose: modify time coordinate of 2010 files so that it atrificially becomes 2009 data
     
     cd /store/lerouxst/eNATL60/BDY_MEDWEST/
     
     for BD in "R_BD1W" "R_BD2E" ;do
     for typ in "gridU-2D"  ;do
     #for typ in "gridV-2D" ;do
     for f in  ${BD}_MEDWEST60-BLBT02_y2010m??d??.1h_${typ}.nc ; do
     ncks -v nav_lon,nav_lat,bozocrtx,sozocrtx $f ./mod_$f
     #ncks -v nav_lon,nav_lat,bomecrty,somecrty $f ./mod_$f
     done
     done
     done
     ``
  
---
---

CONCATENATE IN YEARLY FILES


Basically: ```ncrcat R_BD1W_*y2010*gridS.nc  zfake2010*_gridS.nc ```

Make sure that the files are in the right order (first R_2010 than zfakefrom2009 ).


