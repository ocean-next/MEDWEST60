MODULE traldf_lap
   !!==============================================================================
   !!                       ***  MODULE  traldf_lap  ***
   !! Ocean  tracers:  horizontal component of the lateral tracer mixing trend
   !!==============================================================================
   !! History :  OPA  !  87-06  (P. Andrich, D. L Hostis)  Original code
   !!                 !  91-11  (G. Madec)
   !!                 !  95-11  (G. Madec)  suppress volumetric scale factors
   !!                 !  96-01  (G. Madec)  statement function for e3
   !!            NEMO !  02-06  (G. Madec)  F90: Free form and module
   !!            1.0  !  04-08  (C. Talandier) New trends organization
   !!                 !  05-11  (G. Madec)  add zps case
   !!            3.0  !  10-06  (C. Ethe, G. Madec) Merge TRA-TRC
   !!----------------------------------------------------------------------

   !!----------------------------------------------------------------------
   !!   tra_ldf_lap  : update the tracer trend with the horizontal diffusion
   !!                 using a iso-level harmonic (laplacien) operator.
   !!----------------------------------------------------------------------
   USE oce             ! ocean dynamics and active tracers
   USE dom_oce         ! ocean space and time domain
   USE ldftra_oce      ! ocean tracer   lateral physics
   USE in_out_manager  ! I/O manager
   USE lbclnk          ! ocean lateral boundary conditions (or mpp link) !LOLO
   USE diaptr          ! poleward transport diagnostics
   USE trc_oce         ! share passive tracers/Ocean variables
   USE lib_mpp         ! MPP library
   USE timing          ! Timing

   USE iom             ! IOM library !LOLO

   IMPLICIT NONE
   PRIVATE

   PUBLIC   tra_ldf_lap   ! routine called by step.F90

   REAL(wp), PARAMETER :: &
      & rwp0 = 0.35_wp           , & ! weight given to the point i,j in the boxcar process
      & ris2 = 1._wp/SQRT(2._wp)
   !!
   !                             !!
   !                             !! CONF-specific:
   !                             !! eNATL4:
   !                             !!& rthr_grad_sst = 0.00005_wp , & ! [K/m] | threshold value from which |grad(SST)| is considered too extreme!!
   !                             !!& ramp_aht      =  100.0_wp  , & ! multiplicative factor to ahtu,ahtv to apply where |grad(SST)| == rthr_grad_sst !
   !                             !!                             !    => can become larger where  |grad(SST)| > rthr_grad_sst !
   !                             !!& rmax_msk      = 15.0_wp  , & !    => but never larger than rmax_msk
   !                             !!& rmin_msk   = 0.001_wp     ! minimum value of the mask (background for the rest of the domain non problematic)
   !                             !!
   !                             !! eNATL60:     
   !   & rthr_grad_sst = 0.00075_wp , & ! [K/m] | threshold value from which |grad(SST)| is considered too extreme!!
   !   & ramp_aht      =  8.0_wp  , & ! multiplicative factor to ahtu,ahtv to apply where |grad(SST)| == rthr_grad_sst !
   !                             !!                             !    => can become larger where  |grad(SST)| > rthr_grad_sst !
   !   & rmax_msk      = 15.0_wp  , & !    => but never larger than rmax_msk
   !   & rmin_msk   = 0.01_wp      ! minimum value of the mask (background for the rest of the domain non problematic)
   !
   !INTEGER, PARAMETER :: &
   !   & nt_often = 45, nb_smooth_sst = 10, nb_smooth_mask = 8  ! !LOLO:  ! eNATL60 !!! 45 @40s => 30 minutes!
   !& nt_often = 2, nb_smooth_sst = 2, nb_smooth_mask = 5  ! !LOLO:  ! eNATL4 !!!      2@900s => 30 minutes!

   !! * Substitutions
#  include "domzgr_substitute.h90"
#  include "ldftra_substitute.h90"
#  include "vectopt_loop_substitute.h90"
   !!----------------------------------------------------------------------
   !! NEMO/OPA 3.3 , NEMO Consortium (2010)
   !! $Id: traldf_lap.F90 7494 2016-12-14 09:02:43Z timgraham $
   !! Software governed by the CeCILL licence     (NEMOGCM/NEMO_CeCILL.txt)
   !!----------------------------------------------------------------------
CONTAINS

   SUBROUTINE tra_ldf_lap( kt, kit000, cdtype, pgu , pgv ,    &
      &                                        pgui, pgvi,    &
      &                                ptb, pta, kjpt )
      !!----------------------------------------------------------------------
      !!                  ***  ROUTINE tra_ldf_lap  ***
      !!
      !! ** Purpose :   Compute the before horizontal tracer (t & s) diffusive
      !!      trend and add it to the general trend of tracer equation.
      !!
      !! ** Method  :   Second order diffusive operator evaluated using before
      !!      fields (forward time scheme). The horizontal diffusive trends of
      !!      the tracer is given by:
      !!          difft = 1/(e1t*e2t*e3t) {  di-1[ aht e2u*e3u/e1u di(tb) ]
      !!                                   + dj-1[ aht e1v*e3v/e2v dj(tb) ] }
      !!      Add this trend to the general tracer trend pta :
      !!          pta = pta + difft
      !!
      !! ** Action  : - Update pta arrays with the before iso-level
      !!                harmonic mixing trend.
      !!----------------------------------------------------------------------
      USE oce, ONLY:   ztu => ua , ztv => va  ! (ua,va) used as workspace
      !
      INTEGER                              , INTENT(in   ) ::   kt         ! ocean time-step index
      INTEGER                              , INTENT(in   ) ::   kit000          ! first time step index
      CHARACTER(len=3)                     , INTENT(in   ) ::   cdtype     ! =TRA or TRC (tracer indicator)
      INTEGER                              , INTENT(in   ) ::   kjpt       ! number of tracers
      REAL(wp), DIMENSION(jpi,jpj    ,kjpt), INTENT(in   ) ::   pgu, pgv   ! tracer gradient at pstep levels
      REAL(wp), DIMENSION(jpi,jpj,    kjpt), INTENT(in   ) ::   pgui, pgvi ! tracer gradient at top levels
      REAL(wp), DIMENSION(jpi,jpj,jpk,kjpt), INTENT(in   ) ::   ptb        ! before and now tracer fields
      REAL(wp), DIMENSION(jpi,jpj,jpk,kjpt), INTENT(inout) ::   pta        ! tracer trend
      !
      INTEGER  ::   ji, jj, jk, jn       ! dummy loop indices
      INTEGER  ::   iku, ikv, ierr       ! local integers
      REAL(wp) ::   zabe1, zabe2, zbtr   ! local scalars
      !
      REAL(wp), DIMENSION(:,:),   ALLOCATABLE ::  zsst, zx, zy, zgrad, mask_hdiff !LOLO
      !!----------------------------------------------------------------------
      !
      IF( nn_timing == 1 ) CALL timing_start('tra_ldf_lap')
      !
      IF( kt == kit000 )  THEN
         IF(lwp) WRITE(numout,*)
         IF(lwp) WRITE(numout,*) 'tra_ldf_lap : iso-level laplacian diffusion on ', cdtype
         IF(lwp) WRITE(numout,*) '~~~~~~~~~~~ '
      ENDIF


      !LOLO:
      !! Chantier: put some horizontal diffusion only where SST gradient is too abrupt !!!

      
      IF ( (kt == kit000).OR.(MOD(kt,nt_often) == 0) ) THEN
         
         IF(lwp) WRITE(numout,*) 'LOLO: traldf_lap => time to update the masks for ahtu and ahtv! kt=', kt
         
         ALLOCATE ( zsst(jpi,jpj), zx(jpi,jpj), zy(jpi,jpj), zgrad(jpi,jpj), mask_hdiff(jpi,jpj) ) !LOLO
         zmu_lolo(:,:,:) = rmin_msk ; zmv_lolo(:,:,:) = rmin_msk

         DO jk = 1, jpkm1                                            ! slab loop

            zx(:,:) = 0.0_wp ; zy(:,:) = 0.0_wp ; zgrad(:,:) = 0.0_wp ; mask_hdiff(:,:) = rmin_msk

            !## Smoothing SST at level jk:
            zsst(:,:) = tsn(:,:,jk,jp_tem)
            CALL SMOOTHER( zsst, tmask(:,:,jk), nb_smooth_sst )

            !## Zonal gradient of SST on T-points:
            zx(2:jpi-1,:) = ( zsst(3:jpi,:) - zsst(1:jpi-2,:) ) / ( e1u(2:jpi-1,:) + e1u(1:jpi-2,:) ) * umask(2:jpi-1,:,jk) * umask(1:jpi-2,:,jk)
            zx(:,:) = tmask(:,:,jk) * zx(:,:)
            IF(jk==1) CALL iom_put( "grad_sst_x", zx ) !LOLO: to check !

            !## Meridional gradient of SST on T-points:
            zy(:,2:jpj-1) = ( zsst(:,3:jpj) - zsst(:,1:jpj-2) ) / ( e2v(:,2:jpj-1) + e2v(:,1:jpj-2) ) * vmask(:,2:jpj-1,jk) * vmask(:,1:jpj-2,jk)
            zy(:,:) = tmask(:,:,jk) * zy(:,:)
            IF(jk==1) CALL iom_put( "grad_sst_y", zy ) !LOLO: to check !

            !## Modulus of vector gradient of SST:
            zgrad(:,:) = SQRT( zx(:,:)*zx(:,:) + zy(:,:)*zy(:,:) ) * tmask(:,:,jk)
            IF(jk==1) CALL iom_put( "grad_sst_m", zgrad )

            !## Mask for aht we want to be close to factor 10 (to apply to aht_0) where gradient is too strong!!!
            WHERE( zgrad(:,:) >= rthr_grad_sst ) mask_hdiff(:,:) = ramp_aht * 1.0_wp/rthr_grad_sst * zgrad(:,:)

            !## Smoothing Mask:
            mask_hdiff(:,:) = MAX( mask_hdiff(:,:) , rmin_msk )
            mask_hdiff(:,:) = MIN( mask_hdiff(:,:) , 1.2_wp*rmax_msk )
            CALL lbc_lnk( mask_hdiff, 'T', 1._wp )
            CALL SMOOTHER( mask_hdiff(:,:), tmask(:,:,jk), nb_smooth_mask )
            mask_hdiff(:,:) = MAX( mask_hdiff(:,:) , rmin_msk )
            mask_hdiff(:,:) = MIN( mask_hdiff(:,:) , rmax_msk )
            IF(jk==1) CALL iom_put( "mask_hdiff", mask_hdiff(:,:) )

            !! Need mask at U and V points
            zmu_lolo(1:jpi-1,:,jk) = 0.5_wp * (mask_hdiff(1:jpi-1,:) + mask_hdiff(2:jpi,:))
            !CALL lbc_lnk( zmu_lolo(:,:,jk), 'U', 1._wp )
            !!
            zmv_lolo(:,1:jpj-1,jk) = 0.5_wp * (mask_hdiff(:,1:jpj-1) + mask_hdiff(:,2:jpj))
            !CALL lbc_lnk( zmv_lolo(:,:,jk), 'V', 1._wp )
            !!
         END DO

         DEALLOCATE ( zsst, zx, zy, zgrad, mask_hdiff )
         
      END IF !IF ( (kt == kit000).OR.(MOD(kt,nt_often) == 0) )

      CALL lbc_lnk( zmu_lolo, 'U', 1._wp )
      CALL lbc_lnk( zmv_lolo, 'V', 1._wp )

      CALL iom_put( "mask_hdiff_u", zmu_lolo(:,:,:) )
      CALL iom_put( "mask_hdiff_v", zmv_lolo(:,:,:) )

      CALL iom_put( "ahtu", zmu_lolo(:,:,1)*ahtu )
      CALL iom_put( "ahtv", zmv_lolo(:,:,1)*ahtv )


      !LOLO.




      !                                                          ! =========== !
      DO jn = 1, kjpt                                            ! tracer loop !
         !                                                       ! =========== !
         DO jk = 1, jpkm1                                            ! slab loop
            !
            !LOLO:
            IF ( jn == 1 ) THEN





               !
            END IF


            ! 1. First derivative (gradient)
            ! -------------------
            DO jj = 1, jpjm1
               DO ji = 1, fs_jpim1   ! vector opt.
                  zabe1 = zmu_lolo(ji,jj,jk)*fsahtu(ji,jj,jk) * umask(ji,jj,jk) * re2u_e1u(ji,jj) * fse3u_n(ji,jj,jk) !LOLO
                  zabe2 = zmv_lolo(ji,jj,jk)*fsahtv(ji,jj,jk) * vmask(ji,jj,jk) * re1v_e2v(ji,jj) * fse3v_n(ji,jj,jk) !LOLO
                  ztu(ji,jj,jk) = zabe1 * ( ptb(ji+1,jj  ,jk,jn) - ptb(ji,jj,jk,jn) )
                  ztv(ji,jj,jk) = zabe2 * ( ptb(ji  ,jj+1,jk,jn) - ptb(ji,jj,jk,jn) )
               END DO
            END DO
            IF( ln_zps ) THEN      ! set gradient at partial step level for the last ocean cell
               DO jj = 1, jpjm1
                  DO ji = 1, fs_jpim1   ! vector opt.
                     ! last level
                     iku = mbku(ji,jj)
                     ikv = mbkv(ji,jj)
                     IF( iku == jk ) THEN
                        zabe1 = zmu_lolo(ji,jj,iku)*fsahtu(ji,jj,iku) * umask(ji,jj,iku) * re2u_e1u(ji,jj) * fse3u_n(ji,jj,iku)
                        ztu(ji,jj,jk) = zabe1 * pgu(ji,jj,jn)
                     ENDIF
                     IF( ikv == jk ) THEN
                        zabe2 = zmv_lolo(ji,jj,ikv)*fsahtv(ji,jj,ikv) * vmask(ji,jj,ikv) * re1v_e2v(ji,jj) * fse3v_n(ji,jj,ikv)
                        ztv(ji,jj,jk) = zabe2 * pgv(ji,jj,jn)
                     ENDIF
                  END DO
               END DO
            ENDIF


            ! 2. Second derivative (divergence) added to the general tracer trends
            ! ---------------------------------------------------------------------
            DO jj = 2, jpjm1
               DO ji = fs_2, fs_jpim1   ! vector opt.
                  zbtr = 1._wp / ( e12t(ji,jj) * fse3t_n(ji,jj,jk) )
                  ! horizontal diffusive trends added to the general tracer trends
                  pta(ji,jj,jk,jn) = pta(ji,jj,jk,jn) + zbtr * (  ztu(ji,jj,jk) - ztu(ji-1,jj,jk)   &
                     &                                          + ztv(ji,jj,jk) - ztv(ji,jj-1,jk)  )
               END DO
            END DO
            !
         END DO                                             !  End of slab
         !
         ! "Poleward" diffusive heat or salt transports
         IF( cdtype == 'TRA' .AND. ln_diaptr )    CALL dia_ptr_ohst_components( jn, 'ldf', ztv(:,:,:) )
         !                                                  ! ==================
      END DO                                                ! end of tracer loop
      !                                                     ! ==================
      IF( nn_timing == 1 ) CALL timing_stop('tra_ldf_lap')
      !
   END SUBROUTINE tra_ldf_lap


   SUBROUTINE SMOOTHER( X2D, XM, nbs )

      REAL(wp), DIMENSION(jpi,jpj), INTENT(inout) :: X2D  ! Field to be smoothed
      REAL(wp), DIMENSION(jpi,jpj), INTENT(in)    :: XM   ! Mask
      INTEGER,                      INTENT(in)    :: nbs

      INTEGER :: jo
      REAL(wp), DIMENSION(:,:), ALLOCATABLE :: xt

      ALLOCATE ( xt(jpi,jpj) )

      DO jo = 1, nbs
         xt(:,:) = X2D(:,:) * XM(:,:)
         ! Denominateur:
         X2D(2:jpi-1,2:jpj-1) = 1._wp / MAX(  &
            &         XM(2:jpi-1,3:jpj) + XM(3:jpi,2:jpj-1) + XM(2:jpi-1,1:jpj-2) + XM(1:jpi-2,2:jpj-1)  &
            & + ris2*(XM(3:jpi,3:jpj  ) + XM(3:jpi,1:jpj-2) + XM(1:jpi-2,1:jpj-2) + XM(1:jpi-2,3:jpj  )) &
            &                                , 1.E-6 )
         !!
         X2D(2:jpi-1,2:jpj-1) = rwp0*xt(2:jpi-1,2:jpj-1) &
            & + (1._wp-rwp0)*( xt(2:jpi-1,3:jpj) + xt(3:jpi,2:jpj-1) + xt(2:jpi-1,1:jpj-2) + xt(1:jpi-2,2:jpj-1)  &
            &          + ris2*(xt(3:jpi,3:jpj)   + xt(3:jpi,1:jpj-2) + xt(1:jpi-2,1:jpj-2) + xt(1:jpi-2,3:jpj)) ) &
            &  * X2D(2:jpi-1,2:jpj-1) * XM(2:jpi-1,2:jpj-1)
         !!
         CALL lbc_lnk( X2D, 'T', 1._wp )
      END DO
      DEALLOCATE ( xt )
   END SUBROUTINE SMOOTHER



   !!==============================================================================
END MODULE traldf_lap
