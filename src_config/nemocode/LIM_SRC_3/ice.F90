MODULE ice
   !!======================================================================
   !!                        ***  MODULE ice  ***
   !! LIM-3 Sea Ice physics:  diagnostics variables of ice defined in memory
   !!=====================================================================
   !! History :  3.0  ! 2008-03  (M. Vancoppenolle) original code LIM-3
   !!            4.0  ! 2011-02  (G. Madec) dynamical allocation
   !!----------------------------------------------------------------------
#if defined key_lim3
   !!----------------------------------------------------------------------
   !!   'key_lim3'                                      LIM-3 sea-ice model
   !!----------------------------------------------------------------------
   USE in_out_manager ! I/O manager
   USE lib_mpp        ! MPP library

   IMPLICIT NONE
   PRIVATE

   PUBLIC    ice_alloc  !  Called in sbc_lim_init

   !!======================================================================
   !! LIM3 by the use of sweat, agile fingers and sometimes brain juice, 
   !!  was developed in Louvain-la-Neuve by : 
   !!    * Martin Vancoppenolle (UCL-ASTR, Belgium)
   !!    * Sylvain Bouillon (UCL-ASTR, Belgium)
   !!    * Miguel Angel Morales Maqueda (NOC-L, UK)
   !! 
   !! Based on extremely valuable earlier work by
   !!    * Thierry Fichefet
   !!    * Hugues Goosse
   !!
   !! The following persons also contributed to the code in various ways
   !!    * Gurvan Madec, Claude Talandier, Christian Ethe (LOCEAN, France)
   !!    * Xavier Fettweis (UCL-ASTR), Ralph Timmermann (AWI, Germany)
   !!    * Bill Lipscomb (LANL), Cecilia Bitz (UWa) 
   !!      and Elisabeth Hunke (LANL), USA.
   !! 
   !! For more info, the interested user is kindly invited to consult the following references
   !!    For model description and validation :
   !!    * Vancoppenolle et al., Ocean Modelling, 2008a.
   !!    * Vancoppenolle et al., Ocean Modelling, 2008b.
   !!    For a specific description of EVP :
   !!    * Bouillon et al., Ocean Modelling 2009.
   !!
   !!    Or the reference manual, that should be available by 2011
   !!======================================================================
   !!                                                                     |
   !!              I C E   S T A T E   V A R I A B L E S                  |
   !!                                                                     |
   !! Introduction :                                                      |
   !! --------------                                                      |
   !! Every ice-covered grid cell is characterized by a series of state   |
   !! variables. To account for unresolved spatial variability in ice     |
   !! thickness, the ice cover in divided in ice thickness categories.    |
   !!                                                                     |
   !! Sea ice state variables depend on the ice thickness category        |
   !!                                                                     |
   !! Those variables are divided into two groups                         |
   !! * Extensive (or global) variables.                                  |
   !!   These are the variables that are transported by all means         |
   !! * Intensive (or equivalent) variables.                              |
   !!   These are the variables that are either physically more           |
   !!   meaningful and/or used in ice thermodynamics                      |
   !!                                                                     |
   !! Routines in limvar.F90 perform conversions                          |
   !!  - lim_var_glo2eqv  : from global to equivalent variables           |
   !!  - lim_var_eqv2glo  : from equivalent to global variables           |
   !!                                                                     |
   !! For various purposes, the sea ice state variables have sometimes    |
   !! to be aggregated over all ice thickness categories. This operation  |
   !! is done in :                                                        |
   !!  - lim_var_agg                                                      |
   !!                                                                     |
   !! in icestp.F90, the routines that compute the changes in the ice     |
   !! state variables are called                                          |
   !! - lim_dyn : ice dynamics                                            |
   !! - lim_trp : ice transport                                           |
   !! - lim_itd_me : mechanical redistribution (ridging and rafting)      |
   !! - lim_thd : ice halo-thermodynamics                                 |
   !! - lim_itd_th : thermodynamic changes in ice thickness distribution  |
   !!                and creation of new ice                              |
   !!                                                                     |
   !! See the associated routines for more information                    |
   !!                                                                     |
   !! List of ice state variables :                                       |
   !! -----------------------------                                       |
   !!                                                                     |
   !!-------------|-------------|---------------------------------|-------|
   !!   name in   |   name in   |              meaning            | units |
   !! 2D routines | 1D routines |                                 |       |
   !!-------------|-------------|---------------------------------|-------|
   !!                                                                     |
   !! ******************************************************************* |
   !! ***         Dynamical variables (prognostic)                    *** |
   !! ******************************************************************* |
   !!                                                                     |
   !! u_ice       |      -      |    Comp. U of the ice velocity  | m/s   |
   !! v_ice       |      -      |    Comp. V of the ice velocity  | m/s   |
   !!                                                                     |
   !! ******************************************************************* |
   !! ***         Category dependent state variables (prognostic)     *** |
   !! ******************************************************************* |
   !!                                                                     |
   !! ** Global variables                                                 |
   !!-------------|-------------|---------------------------------|-------|
   !! a_i         | a_i_1d      |    Ice concentration            |       |
   !! v_i         |      -      |    Ice volume per unit area     | m     |
   !! v_s         |      -      |    Snow volume per unit area    | m     |
   !! smv_i       |      -      |    Sea ice salt content         | ppt.m |
   !! oa_i        !      -      !    Sea ice areal age content    | day   |
   !! e_i         !      -      !    Ice enthalpy                 | J/m2  | 
   !!      -      ! q_i_1d      !    Ice enthalpy per unit vol.   | J/m3  | 
   !! e_s         !      -      !    Snow enthalpy                | J/m2  | 
   !!      -      ! q_s_1d      !    Snow enthalpy per unit vol.  | J/m3  | 
   !!                                                                     |
   !!-------------|-------------|---------------------------------|-------|
   !!                                                                     |
   !! ** Equivalent variables                                             |
   !!-------------|-------------|---------------------------------|-------|
   !!                                                                     |
   !! ht_i        | ht_i_1d     |    Ice thickness                | m     |
   !! ht_s        ! ht_s_1d     |    Snow depth                   | m     |
   !! sm_i        ! sm_i_1d     |    Sea ice bulk salinity        ! ppt   |
   !! s_i         ! s_i_1d      |    Sea ice salinity profile     ! ppt   |
   !! o_i         !      -      |    Sea ice Age                  ! days  |
   !! t_i         ! t_i_1d      |    Sea ice temperature          ! K     |
   !! t_s         ! t_s_1d      |    Snow temperature             ! K     |
   !! t_su        ! t_su_1d     |    Sea ice surface temperature  ! K     |
   !!                                                                     |
   !! notes: the ice model only sees a bulk (i.e., vertically averaged)   |
   !!        salinity, except in thermodynamic computations, for which    |
   !!        the salinity profile is computed as a function of bulk       |
   !!        salinity                                                     |
   !!                                                                     |
   !!        the sea ice surface temperature is not associated to any     |
   !!        heat content. Therefore, it is not a state variable and      |
   !!        does not have to be advected. Nevertheless, it has to be     |
   !!        computed to determine whether the ice is melting or not      |
   !!                                                                     |
   !! ******************************************************************* |
   !! ***         Category-summed state variables (diagnostic)        *** |
   !! ******************************************************************* |
   !! at_i        | at_i_1d     |    Total ice concentration      |       |
   !! vt_i        |      -      |    Total ice vol. per unit area | m     |
   !! vt_s        |      -      |    Total snow vol. per unit ar. | m     |
   !! smt_i       |      -      |    Mean sea ice salinity        | ppt   |
   !! tm_i        |      -      |    Mean sea ice temperature     | K     |
   !! ot_i        !      -      !    Sea ice areal age content    | day   |
   !! et_i        !      -      !    Total ice enthalpy           | J/m2  | 
   !! et_s        !      -      !    Total snow enthalpy          | J/m2  | 
   !! bv_i        !      -      !    Mean relative brine volume   | ???   | 
   !!=====================================================================

   LOGICAL, PUBLIC ::   con_i = .false.   ! switch for conservation test

   !!--------------------------------------------------------------------------
   !! * Share Module variables
   !!--------------------------------------------------------------------------
   INTEGER , PUBLIC ::   nstart           !: iteration number of the begining of the run 
   INTEGER , PUBLIC ::   nlast            !: iteration number of the end of the run 
   INTEGER , PUBLIC ::   nitrun           !: number of iteration
   INTEGER , PUBLIC ::   numit            !: iteration number
   REAL(wp), PUBLIC ::   rdt_ice          !: ice time step
   REAL(wp), PUBLIC ::   r1_rdtice        !: = 1. / rdt_ice

   !                                     !!** ice-thickness distribution namelist (namiceitd) **
   INTEGER , PUBLIC ::   nn_catbnd        !: categories distribution following: tanh function (1), or h^(-alpha) function (2)
   REAL(wp), PUBLIC ::   rn_himean        !: mean thickness of the domain (used to compute the distribution, nn_itdshp = 2 only)

   !                                     !!** ice-dynamics namelist (namicedyn) **
   LOGICAL , PUBLIC ::   ln_icestr_bvf    !: use brine volume to diminish ice strength
   INTEGER , PUBLIC ::   nn_icestr        !: ice strength parameterization (0=Hibler79 1=Rothrock75)
   INTEGER , PUBLIC ::   nn_nevp          !: number of iterations for subcycling
   INTEGER , PUBLIC ::   nn_ahi0          !: sea-ice hor. eddy diffusivity coeff. (3 ways of calculation)
   REAL(wp), PUBLIC ::   rn_pe_rdg        !: ridging work divided by pot. energy change in ridging, nn_icestr = 1
   REAL(wp), PUBLIC ::   rn_cio           !: drag coefficient for oceanic stress
   REAL(wp), PUBLIC ::   rn_pstar         !: determines ice strength (N/M), Hibler JPO79
   REAL(wp), PUBLIC ::   rn_crhg          !: determines changes in ice strength
   REAL(wp), PUBLIC ::   rn_creepl        !: creep limit : has to be under 1.0e-9
   REAL(wp), PUBLIC ::   rn_ecc           !: eccentricity of the elliptical yield curve
   REAL(wp), PUBLIC ::   rn_ahi0_ref      !: sea-ice hor. eddy diffusivity coeff. (m2/s)
   REAL(wp), PUBLIC ::   rn_relast        !: ratio => telast/rdt_ice (1/3 or 1/9 depending on nb of subcycling nevp) 

   !                                     !!** ice-salinity namelist (namicesal) **
   REAL(wp), PUBLIC ::   rn_simax         !: maximum ice salinity [PSU]
   REAL(wp), PUBLIC ::   rn_simin         !: minimum ice salinity [PSU]
   REAL(wp), PUBLIC ::   rn_sal_gd        !: restoring salinity for gravity drainage [PSU]
   REAL(wp), PUBLIC ::   rn_sal_fl        !: restoring salinity for flushing [PSU]
   REAL(wp), PUBLIC ::   rn_time_gd       !: restoring time constant for gravity drainage (= 20 days) [s]
   REAL(wp), PUBLIC ::   rn_time_fl       !: restoring time constant for gravity drainage (= 10 days) [s]
   REAL(wp), PUBLIC ::   rn_icesal        !: bulk salinity (ppt) in case of constant salinity

   !                                     !!** ice-salinity namelist (namicesal) **
   INTEGER , PUBLIC ::   nn_icesal           !: salinity configuration used in the model
   !                                         ! 1 - constant salinity in both space and time
   !                                         ! 2 - prognostic salinity (s(z,t))
   !                                         ! 3 - salinity profile, constant in time
   INTEGER , PUBLIC ::   nn_ice_thcon        !: thermal conductivity: =0 Untersteiner (1964) ; =1 Pringle et al (2007)
   INTEGER , PUBLIC ::   nn_monocat          !: virtual ITD mono-category parameterizations (1) or not (0)
   LOGICAL , PUBLIC ::   ln_it_qnsice        !: iterate surface flux with changing surface temperature or not (F)

   !                                     !!** ice-mechanical redistribution namelist (namiceitdme)
   REAL(wp), PUBLIC ::   rn_cs            !: fraction of shearing energy contributing to ridging            
   REAL(wp), PUBLIC ::   rn_fsnowrdg      !: fractional snow loss to the ocean during ridging
   REAL(wp), PUBLIC ::   rn_fsnowrft      !: fractional snow loss to the ocean during ridging
   REAL(wp), PUBLIC ::   rn_gstar         !: fractional area of young ice contributing to ridging
   REAL(wp), PUBLIC ::   rn_astar         !: equivalent of G* for an exponential participation function
   REAL(wp), PUBLIC ::   rn_hstar         !: thickness that determines the maximal thickness of ridged ice
   REAL(wp), PUBLIC ::   rn_hraft         !: threshold thickness (m) for rafting / ridging 
   REAL(wp), PUBLIC ::   rn_craft         !: coefficient for smoothness of the hyperbolic tangent in rafting
   REAL(wp), PUBLIC ::   rn_por_rdg       !: initial porosity of ridges (0.3 regular value)
   REAL(wp), PUBLIC ::   rn_betas         !: coef. for partitioning of snowfall between leads and sea ice
   REAL(wp), PUBLIC ::   rn_kappa_i       !: coef. for the extinction of radiation Grenfell et al. (2006) [1/m]
   REAL(wp), PUBLIC ::   rn_cdsn          !: thermal conductivity of the snow [W/m/K]
   REAL(wp), PUBLIC ::   nn_conv_dif      !: maximal number of iterations for heat diffusion
   REAL(wp), PUBLIC ::   rn_terr_dif      !: maximal tolerated error (C) for heat diffusion

   !                                     !!** ice-mechanical redistribution namelist (namiceitdme)
   LOGICAL , PUBLIC ::   ln_rafting      !: rafting of ice or not                        
   INTEGER , PUBLIC ::   nn_partfun      !: participation function: =0 Thorndike et al. (1975), =1 Lipscomb et al. (2007)

   REAL(wp), PUBLIC ::   usecc2           !:  = 1.0 / ( rn_ecc * rn_ecc )
   REAL(wp), PUBLIC ::   rhoco            !: = rau0 * cio
   REAL(wp), PUBLIC ::   r1_nlay_i        !: 1 / nlay_i
   REAL(wp), PUBLIC ::   r1_nlay_s        !: 1 / nlay_s 
   !
   !                                     !!** switch for presence of ice or not 
   REAL(wp), PUBLIC ::   rswitch
   !
   !                                     !!** define some parameters 
   REAL(wp), PUBLIC, PARAMETER ::   epsi06   = 1.e-06_wp  !: small number 
   REAL(wp), PUBLIC, PARAMETER ::   epsi10   = 1.e-10_wp  !: small number 
   REAL(wp), PUBLIC, PARAMETER ::   epsi20   = 1.e-20_wp  !: small number 

   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   u_oce, v_oce   !: surface ocean velocity used in ice dynamics
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   ahiu , ahiv    !: hor. diffusivity coeff. at U- and V-points [m2/s]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   ust2s, hicol   !: friction velocity, ice collection thickness accreted in leads
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   strp1, strp2   !: strength at previous time steps
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   strength       !: ice strength
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   stress1_i, stress2_i, stress12_i   !: 1st, 2nd & diagonal stress tensor element
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   delta_i        !: ice rheology elta factor (Flato & Hibler 95) [s-1]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   divu_i         !: Divergence of the velocity field [s-1]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   shear_i        !: Shear of the velocity field [s-1]
   !
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   sist        !: Average Sea-Ice Surface Temperature [Kelvin]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   t_bo        !: Sea-Ice bottom temperature [Kelvin]     
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   frld        !: Leads fraction = 1 - ice fraction
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   pfrld       !: Leads fraction at previous time  
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   phicif      !: Old ice thickness
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   qlead       !: heat balance of the lead (or of the open ocean)
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   fhtur       !: net downward heat flux from the ice to the ocean
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   fhld        !: heat flux from the lead used for bottom melting

   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   wfx_snw    !: snow-ocean mass exchange   [kg.m-2.s-1]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   wfx_spr    !: snow precipitation on ice  [kg.m-2.s-1]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   wfx_sub    !: snow/ice sublimation       [kg.m-2.s-1]

   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   wfx_ice    !: ice-ocean mass exchange                   [kg.m-2.s-1]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   wfx_sni    !: snow ice growth component of wfx_ice      [kg.m-2.s-1]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   wfx_opw    !: lateral ice growth component of wfx_ice   [kg.m-2.s-1]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   wfx_bog    !: bottom ice growth component of wfx_ice    [kg.m-2.s-1]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   wfx_dyn    !: dynamical ice growth component of wfx_ice [kg.m-2.s-1]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   wfx_bom    !: bottom melt component of wfx_ice          [kg.m-2.s-1]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   wfx_sum    !: surface melt component of wfx_ice         [kg.m-2.s-1]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   wfx_res    !: residual component of wfx_ice             [kg.m-2.s-1]

   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   afx_tot     !: ice concentration tendency (total)          [s-1]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   afx_thd     !: ice concentration tendency (thermodynamics) [s-1]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   afx_dyn     !: ice concentration tendency (dynamics)       [s-1]

   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   sfx_bog     !: salt flux due to ice growth/melt                      [PSU/m2/s]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   sfx_bom     !: salt flux due to ice growth/melt                      [PSU/m2/s]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   sfx_sum     !: salt flux due to ice growth/melt                      [PSU/m2/s]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   sfx_sni     !: salt flux due to ice growth/melt                      [PSU/m2/s]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   sfx_opw     !: salt flux due to ice growth/melt                      [PSU/m2/s]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   sfx_bri     !: salt flux due to brine rejection                      [PSU/m2/s]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   sfx_dyn     !: salt flux due to porous ridged ice formation          [PSU/m2/s]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   sfx_res     !: residual salt flux due to correction of ice thickness [PSU/m2/s]

   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   sfx_sub     !: salt flux due to ice sublimation

   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_bog     !: total heat flux causing bottom ice growth        [W.m-2]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_bom     !: total heat flux causing bottom ice melt          [W.m-2]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_sum     !: total heat flux causing surface ice melt         [W.m-2]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_opw     !: total heat flux causing open water ice formation [W.m-2]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_dif     !: total heat flux causing Temp change in the ice   [W.m-2]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_snw     !: heat flux for snow melt                          [W.m-2]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_err     !: heat flux error after heat diffusion             [W.m-2]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_err_dif !: heat flux remaining due to change in non-solar flux [W.m-2]
   !LOLO:REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_err_rem !: heat flux error after heat remapping             [W.m-2]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_in      !: heat flux available for thermo transformations   [W.m-2]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_out     !: heat flux remaining at the end of thermo transformations  [W.m-2]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   wfx_err_sub !: mass flux error after sublimation [kg.m-2.s-1]
   
   ! heat flux associated with ice-atmosphere mass exchange
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_sub     !: heat flux for sublimation  [W.m-2]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_spr     !: heat flux of the snow precipitation  [W.m-2]

   ! heat flux associated with ice-ocean mass exchange
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_thd     !: ice-ocean heat flux from thermo processes (limthd_dh)  [W.m-2]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_dyn     !: ice-ocean heat flux from mecanical processes (limitd_me)  [W.m-2]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   hfx_res     !: residual heat flux due to correction of ice thickness [W.m-2]

   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:) ::   ftr_ice   !: transmitted solar radiation under ice   
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:) ::   pahu3D , pahv3D
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:)   ::   rn_amax_2d  !: maximum ice concentration 2d array

   !!--------------------------------------------------------------------------
   !! * Ice global state variables
   !!--------------------------------------------------------------------------
   !! Variables defined for each ice category
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:) ::   ht_i    !: Ice thickness (m)
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:) ::   a_i     !: Ice fractional areas (concentration)
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:) ::   v_i     !: Ice volume per unit area (m)
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:) ::   v_s     !: Snow volume per unit area(m)
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:) ::   ht_s    !: Snow thickness (m)
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:) ::   t_su    !: Sea-Ice Surface Temperature (K)
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:) ::   sm_i    !: Sea-Ice Bulk salinity (ppt)
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:) ::   smv_i   !: Sea-Ice Bulk salinity times volume per area (ppt.m)
   !                                                                  !  this is an extensive variable that has to be transported
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:) ::   o_i     !: Sea-Ice Age (days)
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:) ::   oa_i    !: Sea-Ice Age times ice area (days)

   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:) ::   bv_i    !: brine volume

   !! Variables summed over all categories, or associated to all the ice in a single grid cell
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   u_ice, v_ice   !: components of the ice velocity (m/s)
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   vt_i , vt_s    !: ice and snow total volume per unit area (m)
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   at_i           !: ice total fractional area (ice concentration)
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   ato_i          !: =1-at_i ; total open water fractional area
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   et_i , et_s    !: ice and snow total heat content
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   tm_i         !: mean ice temperature over all categories
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   bvm_i        !: brine volume averaged over all categories
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   smt_i        !: mean sea ice salinity averaged over all categories [PSU]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   tm_su        !: mean surface temperature over all categories
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   htm_i        !: mean ice  thickness over all categories
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   htm_s        !: mean snow thickness over all categories
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:) ::   om_i         !: mean ice age over all categories

   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:,:) ::   t_s        !: Snow temperatures [K]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:,:) ::   e_s        !: Snow ...      
      
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:,:) ::   t_i        !: ice temperatures          [K]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:,:) ::   e_i        !: ice thermal contents    [J/m2]
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:,:) ::   s_i        !: ice salinities          [PSU]

   !!--------------------------------------------------------------------------
   !! * Moments for advection
   !!--------------------------------------------------------------------------
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:)     ::   sxopw, syopw, sxxopw, syyopw, sxyopw   !: open water in sea ice
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:)   ::   sxice, syice, sxxice, syyice, sxyice   !: ice thickness 
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:)   ::   sxsn , sysn , sxxsn , syysn , sxysn    !: snow thickness
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:)   ::   sxa  , sya  , sxxa  , syya  , sxya     !: lead fraction
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:)   ::   sxc0 , syc0 , sxxc0 , syyc0 , sxyc0    !: snow thermal content
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:)   ::   sxsal, sysal, sxxsal, syysal, sxysal   !: ice salinity
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:)   ::   sxage, syage, sxxage, syyage, sxyage   !: ice age
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:,:) ::   sxe  , sye  , sxxe  , syye  , sxye     !: ice layers heat content

   !!--------------------------------------------------------------------------
   !! * Old values of global variables
   !!--------------------------------------------------------------------------
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:)   ::   v_s_b, v_i_b               !: snow and ice volumes
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:)   ::   a_i_b, smv_i_b, oa_i_b     !:
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:,:) ::   e_s_b                      !: snow heat content
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:,:,:) ::   e_i_b                      !: ice temperatures
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:)     ::   u_ice_b, v_ice_b           !: ice velocity
            
   !!--------------------------------------------------------------------------
   !! * Ice thickness distribution variables
   !!--------------------------------------------------------------------------
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:)   ::   hi_max         !: Boundary of ice thickness categories in thickness space
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:)   ::   hi_mean        !: Mean ice thickness in catgories 

   !!--------------------------------------------------------------------------
   !! * Ice Run
   !!--------------------------------------------------------------------------
   !                                                  !!: ** Namelist namicerun read in sbc_lim_init **
   INTEGER          , PUBLIC ::   jpl             !: number of ice  categories 
   INTEGER          , PUBLIC ::   nlay_i          !: number of ice  layers 
   INTEGER          , PUBLIC ::   nlay_s          !: number of snow layers 
   CHARACTER(len=80), PUBLIC ::   cn_icerst_in    !: suffix of ice restart name (input)
   CHARACTER(len=256), PUBLIC ::   cn_icerst_indir !: ice restart input directory
   CHARACTER(len=80), PUBLIC ::   cn_icerst_out   !: suffix of ice restart name (output)
   CHARACTER(len=256), PUBLIC ::   cn_icerst_outdir!: ice restart output directory
   LOGICAL          , PUBLIC ::   ln_limdyn       !: flag for ice dynamics (T) or not (F)
   LOGICAL          , PUBLIC ::   ln_icectl       !: flag for sea-ice points output (T) or not (F)
   REAL(wp)         , PUBLIC ::   rn_amax_n       !: maximum ice concentration Northern hemisphere
   REAL(wp)         , PUBLIC ::   rn_amax_s       !: maximum ice concentration Southern hemisphere
   INTEGER          , PUBLIC ::   iiceprt         !: debug i-point
   INTEGER          , PUBLIC ::   jiceprt         !: debug j-point
   !
   !!--------------------------------------------------------------------------
   !! * Ice diagnostics
   !!--------------------------------------------------------------------------
   ! Increment of global variables
   ! thd refers to changes induced by thermodynamics
   ! trp   ''         ''     ''       advection (transport of ice)
   LOGICAL , PUBLIC                                        ::   ln_limdiahsb  !: flag for ice diag (T) or not (F)
   LOGICAL , PUBLIC                                        ::   ln_limdiaout  !: flag for ice diag (T) or not (F)
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:)     ::   diag_trp_vi   !: transport of ice volume
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:)     ::   diag_trp_vs   !: transport of snw volume
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:)     ::   diag_trp_ei   !: transport of ice enthalpy (W/m2)
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:)     ::   diag_trp_es   !: transport of snw enthalpy (W/m2)
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:)     ::   diag_trp_smv  !: transport of salt content
   !
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:)     ::   diag_heat     !: snw/ice heat content variation   [W/m2] 
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:)     ::   diag_smvi     !: ice salt content variation   [] 
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:)     ::   diag_vice     !: ice volume variation   [m/s] 
   REAL(wp), PUBLIC, ALLOCATABLE, SAVE, DIMENSION(:,:)     ::   diag_vsnw     !: snw volume variation   [m/s] 

   !
   !!----------------------------------------------------------------------
   !! NEMO/LIM3 4.0 , UCL - NEMO Consortium (2010)
   !! $Id: ice.F90 7814 2017-03-20 16:21:42Z clem $
   !! Software governed by the CeCILL licence     (NEMOGCM/NEMO_CeCILL.txt)
   !!----------------------------------------------------------------------
CONTAINS

   FUNCTION ice_alloc()
      !!-----------------------------------------------------------------
      !!               *** Routine ice_alloc ***
      !!-----------------------------------------------------------------
      INTEGER :: ice_alloc
      !
      INTEGER :: ierr(17), ii
      !!-----------------------------------------------------------------

      ierr(:) = 0

      ! What could be one huge allocate statement is broken-up to try to
      ! stay within Fortran's max-line length limit.
      ii = 1
      ALLOCATE( u_oce    (jpi,jpj) , v_oce    (jpi,jpj) ,                           &
         &      ahiu     (jpi,jpj) , ahiv     (jpi,jpj) ,                           &
         &      ust2s    (jpi,jpj) , hicol    (jpi,jpj) ,                           &
         &      strp1    (jpi,jpj) , strp2    (jpi,jpj) , strength  (jpi,jpj) ,     &
         &      stress1_i(jpi,jpj) , stress2_i(jpi,jpj) , stress12_i(jpi,jpj) ,     &
         &      delta_i  (jpi,jpj) , divu_i   (jpi,jpj) , shear_i   (jpi,jpj) , STAT=ierr(ii) )
      !LOLO:
      u_oce    (:,:) = 0.0_wp ; v_oce    (:,:) = 0.0_wp
      ahiu     (:,:) = 0.0_wp ; ahiv     (:,:) = 0.0_wp
      ust2s    (:,:) = 0.0_wp ; hicol    (:,:) = 0.0_wp
      strp1    (:,:) = 0.0_wp ; strp2    (:,:) = 0.0_wp ; strength  (:,:) = 0.0_wp
      stress1_i(:,:) = 0.0_wp ; stress2_i(:,:) = 0.0_wp ; stress12_i(:,:) = 0.0_wp
      delta_i  (:,:) = 0.0_wp ; divu_i   (:,:) = 0.0_wp ; shear_i   (:,:) = 0.0_wp
      !LOLO.
      
      ii = ii + 1
      ALLOCATE( sist   (jpi,jpj) , t_bo   (jpi,jpj) ,                        &
         &      frld   (jpi,jpj) , pfrld  (jpi,jpj) , phicif (jpi,jpj) ,                        &
         &      wfx_snw(jpi,jpj) , wfx_ice(jpi,jpj) , wfx_sub(jpi,jpj) ,                        &
         &      wfx_bog(jpi,jpj) , wfx_dyn(jpi,jpj) , wfx_bom(jpi,jpj) , wfx_sum(jpi,jpj) ,     &
         &      wfx_res(jpi,jpj) , wfx_sni(jpi,jpj) , wfx_opw(jpi,jpj) , wfx_spr(jpi,jpj) ,     &
         &      afx_tot(jpi,jpj) , afx_thd(jpi,jpj),  afx_dyn(jpi,jpj) ,                        &
         &      fhtur  (jpi,jpj) , ftr_ice(jpi,jpj,jpl), pahu3D(jpi,jpj,jpl+1), pahv3D(jpi,jpj,jpl+1),            &
         &      qlead  (jpi,jpj) , rn_amax_2d(jpi,jpj),                                         &
         &      sfx_res(jpi,jpj) , sfx_bri(jpi,jpj) , sfx_dyn(jpi,jpj) , sfx_sub(jpi,jpj),      &
         &      sfx_bog(jpi,jpj) , sfx_bom(jpi,jpj) , sfx_sum(jpi,jpj) , sfx_sni(jpi,jpj) , sfx_opw(jpi,jpj) ,    &
         &      hfx_res(jpi,jpj) , hfx_snw(jpi,jpj) , hfx_sub(jpi,jpj) , hfx_err(jpi,jpj) ,     & 
         &      hfx_err_dif(jpi,jpj) , wfx_err_sub(jpi,jpj) ,       &
         !LOLO:&      hfx_err_dif(jpi,jpj) , hfx_err_rem(jpi,jpj) , wfx_err_sub(jpi,jpj) ,       &
         &      hfx_in (jpi,jpj) , hfx_out(jpi,jpj) , fhld(jpi,jpj) ,                           &
         &      hfx_sum(jpi,jpj) , hfx_bom(jpi,jpj) , hfx_bog(jpi,jpj) , hfx_dif(jpi,jpj) , hfx_opw(jpi,jpj) ,    &
         &      hfx_thd(jpi,jpj) , hfx_dyn(jpi,jpj) , hfx_spr(jpi,jpj) ,  STAT=ierr(ii) )
      
      !LOLO:
      sist   (:,:) = 0.0_wp ; t_bo   (:,:) = 0.0_wp
      frld   (:,:) = 0.0_wp ; pfrld  (:,:) = 0.0_wp ; phicif (:,:) = 0.0_wp
      wfx_snw(:,:) = 0.0_wp ; wfx_ice(:,:) = 0.0_wp ; wfx_sub(:,:) = 0.0_wp
      wfx_bog(:,:) = 0.0_wp ; wfx_dyn(:,:) = 0.0_wp ; wfx_bom(:,:) = 0.0_wp ; wfx_sum(:,:) = 0.0_wp
      wfx_res(:,:) = 0.0_wp ; wfx_sni(:,:) = 0.0_wp ; wfx_opw(:,:) = 0.0_wp ; wfx_spr(:,:) = 0.0_wp
      afx_tot(:,:) = 0.0_wp ; afx_thd(:,:) = 0.0_wp ;  afx_dyn(:,:) = 0.0_wp
      fhtur  (:,:) = 0.0_wp ; ftr_ice(:,:,:) = 0.0_wp ; pahu3D(:,:,:) = 0.0_wp ; pahv3D(:,:,:) = 0.0_wp
      qlead  (:,:) = 0.0_wp ; rn_amax_2d(:,:) = 0.0_wp ;
      sfx_res(:,:) = 0.0_wp ; sfx_bri(:,:) = 0.0_wp ; sfx_dyn(:,:) = 0.0_wp ; sfx_sub(:,:) = 0.0_wp
      sfx_bog(:,:) = 0.0_wp ; sfx_bom(:,:) = 0.0_wp ; sfx_sum(:,:) = 0.0_wp ; sfx_sni(:,:) = 0.0_wp ; sfx_opw(:,:) = 0.0_wp
      hfx_res(:,:) = 0.0_wp ; hfx_snw(:,:) = 0.0_wp ; hfx_sub(:,:) = 0.0_wp ; hfx_err(:,:) = 0.0_wp
      hfx_err_dif(:,:) = 0.0_wp ; wfx_err_sub(:,:) = 0.0_wp
      hfx_in (:,:) = 0.0_wp ; hfx_out(:,:) = 0.0_wp ; fhld(:,:) = 0.0_wp
      hfx_sum(:,:) = 0.0_wp ; hfx_bom(:,:) = 0.0_wp ; hfx_bog(:,:) = 0.0_wp ; hfx_dif(:,:) = 0.0_wp ; hfx_opw(:,:) = 0.0_wp
      hfx_thd(:,:) = 0.0_wp ; hfx_dyn(:,:) = 0.0_wp ; hfx_spr(:,:) = 0.0_wp
      !LOLO.


      
      ! * Ice global state variables
      ii = ii + 1
      ALLOCATE( ht_i (jpi,jpj,jpl) , a_i  (jpi,jpj,jpl) , v_i  (jpi,jpj,jpl) ,     &
         &      v_s  (jpi,jpj,jpl) , ht_s (jpi,jpj,jpl) , t_su (jpi,jpj,jpl) ,     &
         &      sm_i (jpi,jpj,jpl) , smv_i(jpi,jpj,jpl) , o_i  (jpi,jpj,jpl) ,     &
         &      oa_i (jpi,jpj,jpl) , bv_i (jpi,jpj,jpl) , STAT=ierr(ii) )
      !LOLO:
      ht_i (:,:,:) = 0.0_wp ; a_i  (:,:,:) = 0.0_wp ; v_i  (:,:,:) = 0.0_wp
      v_s  (:,:,:) = 0.0_wp ; ht_s (:,:,:) = 0.0_wp ; t_su (:,:,:) = 0.0_wp
      sm_i (:,:,:) = 0.0_wp ; smv_i(:,:,:) = 0.0_wp ; o_i  (:,:,:) = 0.0_wp
      oa_i (:,:,:) = 0.0_wp ; bv_i (:,:,:) = 0.0_wp ;
      !LOLO.
      
      ii = ii + 1
      ALLOCATE( u_ice(jpi,jpj) , v_ice(jpi,jpj) ,      &
         &      vt_i (jpi,jpj) , vt_s (jpi,jpj) , at_i (jpi,jpj) , ato_i(jpi,jpj) ,     &
         &      et_i (jpi,jpj) , et_s (jpi,jpj) , tm_i (jpi,jpj) , bvm_i(jpi,jpj) ,     &
         &      smt_i(jpi,jpj) , tm_su(jpi,jpj) , htm_i(jpi,jpj) , htm_s(jpi,jpj) ,     &
         &      om_i (jpi,jpj) , STAT=ierr(ii) )
      !LOLO:
      u_ice(:,:) = 0.0_wp ; v_ice(:,:) = 0.0_wp
      vt_i (:,:) = 0.0_wp ; vt_s (:,:) = 0.0_wp ; at_i (:,:) = 0.0_wp ; ato_i(:,:) = 0.0_wp
      et_i (:,:) = 0.0_wp ; et_s (:,:) = 0.0_wp ; tm_i (:,:) = 0.0_wp ; bvm_i(:,:) = 0.0_wp
      smt_i(:,:) = 0.0_wp ; tm_su(:,:) = 0.0_wp ; htm_i(:,:) = 0.0_wp ; htm_s(:,:) = 0.0_wp
      om_i (:,:) = 0.0_wp
      !LOLO.
      
      ii = ii + 1
      ALLOCATE( t_s(jpi,jpj,nlay_s,jpl) , e_s(jpi,jpj,nlay_s,jpl) , STAT=ierr(ii) )
      !LOLO:
      t_s(:,:,:,:) = 0._wp ; e_s(:,:,:,:) = 0._wp
      !LOLO.
      
      ii = ii + 1
      ALLOCATE( t_i(jpi,jpj,nlay_i,jpl) , e_i(jpi,jpj,nlay_i,jpl) , s_i(jpi,jpj,nlay_i,jpl) , STAT=ierr(ii) )
      !LOLO:
      t_i(:,:,:,:) = 0._wp ; e_i(:,:,:,:) = 0._wp ; s_i(:,:,:,:) = 0._wp
      !LOLO.

      ! * Moments for advection
      ii = ii + 1
      ALLOCATE( sxopw(jpi,jpj) , syopw(jpi,jpj) , sxxopw(jpi,jpj) , syyopw(jpi,jpj) , sxyopw(jpi,jpj) , STAT=ierr(ii) )
      sxopw(:,:) = 0.0_wp ; syopw(:,:) = 0.0_wp ; sxxopw(:,:) = 0.0_wp ; syyopw(:,:) = 0.0_wp ; sxyopw(:,:) = 0.0_wp !LOLO
      
      ii = ii + 1
      ALLOCATE( sxice(jpi,jpj,jpl) , syice(jpi,jpj,jpl) , sxxice(jpi,jpj,jpl) , syyice(jpi,jpj,jpl) , sxyice(jpi,jpj,jpl) ,   &
         &      sxsn (jpi,jpj,jpl) , sysn (jpi,jpj,jpl) , sxxsn (jpi,jpj,jpl) , syysn (jpi,jpj,jpl) , sxysn (jpi,jpj,jpl) ,   &
         &      STAT=ierr(ii) )
      !LOLO:
      sxice(:,:,:) = 0.0_wp ; syice(:,:,:) = 0.0_wp ; sxxice(:,:,:) = 0.0_wp ; syyice(:,:,:) = 0.0_wp ; sxyice(:,:,:) = 0.0_wp
      sxsn (:,:,:) = 0.0_wp ; sysn (:,:,:) = 0.0_wp ; sxxsn (:,:,:) = 0.0_wp ; syysn (:,:,:) = 0.0_wp ; sxysn (:,:,:) = 0.0_wp
      !LOLO.

      ii = ii + 1
      ALLOCATE( sxa  (jpi,jpj,jpl) , sya  (jpi,jpj,jpl) , sxxa  (jpi,jpj,jpl) , syya  (jpi,jpj,jpl) , sxya  (jpi,jpj,jpl) ,   &
         &      sxc0 (jpi,jpj,jpl) , syc0 (jpi,jpj,jpl) , sxxc0 (jpi,jpj,jpl) , syyc0 (jpi,jpj,jpl) , sxyc0 (jpi,jpj,jpl) ,   &
         &      sxsal(jpi,jpj,jpl) , sysal(jpi,jpj,jpl) , sxxsal(jpi,jpj,jpl) , syysal(jpi,jpj,jpl) , sxysal(jpi,jpj,jpl) ,   &
         &      sxage(jpi,jpj,jpl) , syage(jpi,jpj,jpl) , sxxage(jpi,jpj,jpl) , syyage(jpi,jpj,jpl) , sxyage(jpi,jpj,jpl) ,   &
         &      STAT=ierr(ii) )
      !LOLO:
      sxa  (:,:,:) = 0.0_wp ; sya  (:,:,:) = 0.0_wp ; sxxa  (:,:,:) = 0.0_wp ; syya  (:,:,:) = 0.0_wp ; sxya  (:,:,:) = 0.0_wp
      sxc0 (:,:,:) = 0.0_wp ; syc0 (:,:,:) = 0.0_wp ; sxxc0 (:,:,:) = 0.0_wp ; syyc0 (:,:,:) = 0.0_wp ; sxyc0 (:,:,:) = 0.0_wp
      sxsal(:,:,:) = 0.0_wp ; sysal(:,:,:) = 0.0_wp ; sxxsal(:,:,:) = 0.0_wp ; syysal(:,:,:) = 0.0_wp ; sxysal(:,:,:) = 0.0_wp
      sxage(:,:,:) = 0.0_wp ; syage(:,:,:) = 0.0_wp ; sxxage(:,:,:) = 0.0_wp ; syyage(:,:,:) = 0.0_wp ; sxyage(:,:,:) = 0.0_wp
      !LOLO.
      
      ii = ii + 1
      ALLOCATE( sxe (jpi,jpj,nlay_i,jpl) , sye (jpi,jpj,nlay_i,jpl) , sxxe(jpi,jpj,nlay_i,jpl) ,     &
         &      syye(jpi,jpj,nlay_i,jpl) , sxye(jpi,jpj,nlay_i,jpl)                            , STAT=ierr(ii) )
      !LOLO:
      sxe (:,:,:,:) = 0.0_wp ; sye (:,:,:,:) = 0.0_wp ; sxxe(:,:,:,:) = 0.0_wp
      syye(:,:,:,:) = 0.0_wp ; sxye(:,:,:,:) = 0.0_wp
      !LOLO.

      ! * Old values of global variables
      ii = ii + 1
      ALLOCATE( v_s_b  (jpi,jpj,jpl) , v_i_b  (jpi,jpj,jpl) , e_s_b(jpi,jpj,nlay_s,jpl) ,     &
         &      a_i_b  (jpi,jpj,jpl) , smv_i_b(jpi,jpj,jpl) , e_i_b(jpi,jpj,nlay_i,jpl) ,     &
         &      oa_i_b (jpi,jpj,jpl) , u_ice_b(jpi,jpj)     , v_ice_b(jpi,jpj)          , STAT=ierr(ii) )
      !LOLO:
      v_s_b  (:,:,:) = 0.0_wp ; v_i_b  (:,:,:) = 0.0_wp ; e_s_b(:,:,:,:) = 0.0_wp
      a_i_b  (:,:,:) = 0.0_wp ; smv_i_b(:,:,:) = 0.0_wp ; e_i_b(:,:,:,:) = 0.0_wp
      oa_i_b (:,:,:) = 0.0_wp ; u_ice_b(:,:) = 0.0_wp ; v_ice_b(:,:) = 0.0_wp      
      !LOLO.
      
      ! * Ice thickness distribution variables
      ii = ii + 1
      ALLOCATE( hi_max(0:jpl), hi_mean(jpl),  STAT=ierr(ii) )
      hi_max(:) = 0.0_wp ; hi_mean(:) = 0.0_wp !LOLO

      ! * Ice diagnostics
      ii = ii + 1
      ALLOCATE( diag_trp_vi(jpi,jpj), diag_trp_vs (jpi,jpj), diag_trp_ei(jpi,jpj),   & 
         &      diag_trp_es(jpi,jpj), diag_trp_smv(jpi,jpj), diag_heat  (jpi,jpj),   &
         &      diag_smvi  (jpi,jpj), diag_vice   (jpi,jpj), diag_vsnw  (jpi,jpj), STAT=ierr(ii) )
      !LOLO:
      diag_trp_vi(:,:) = 0.0_wp ; diag_trp_vs (:,:) = 0.0_wp ; diag_trp_ei(:,:) = 0.0_wp
      diag_trp_es(:,:) = 0.0_wp ; diag_trp_smv(:,:) = 0.0_wp ; diag_heat  (:,:) = 0.0_wp
      diag_smvi  (:,:) = 0.0_wp ; diag_vice   (:,:) = 0.0_wp ; diag_vsnw  (:,:) = 0.0_wp      
      !LOLO.
      
      ice_alloc = MAXVAL( ierr(:) )
      IF( ice_alloc /= 0 )   CALL ctl_warn('ice_alloc: failed to allocate arrays.')
      !
   END FUNCTION ice_alloc

#else
   !!----------------------------------------------------------------------
   !!   Default option         Empty module            NO LIM sea-ice model
   !!----------------------------------------------------------------------
#endif

   !!======================================================================
END MODULE ice

