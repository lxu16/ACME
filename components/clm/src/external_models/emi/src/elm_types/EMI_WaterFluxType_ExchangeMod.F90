module EMI_WaterFluxType_ExchangeMod
  !
  use shr_kind_mod                          , only : r8 => shr_kind_r8
  use shr_log_mod                           , only : errMsg => shr_log_errMsg
  use abortutils                            , only : endrun
  use clm_varctl                            , only : iulog
  use ExternalModelInterfaceDataMod         , only : emi_data_list, emi_data
  use ExternalModelIntefaceDataDimensionMod , only : emi_data_dimension_list_type
  use WaterFluxType                         , only : waterflux_type
  use EMI_Atm2LndType_Constants
  use EMI_CanopyStateType_Constants
  use EMI_ChemStateType_Constants
  use EMI_EnergyFluxType_Constants
  use EMI_SoilHydrologyType_Constants
  use EMI_SoilStateType_Constants
  use EMI_TemperatureType_Constants
  use EMI_WaterFluxType_Constants
  use EMI_WaterStateType_Constants
  use EMI_Filter_Constants
  use EMI_ColumnType_Constants
  use EMI_Landunit_Constants
  !
  implicit none
  !
  !
  public :: EMI_Pack_WaterFluxType_at_Column_Level_for_EM
  public :: EMI_Unpack_WaterFluxType_at_Column_Level_from_EM

contains
  
!-----------------------------------------------------------------------
  subroutine EMI_Pack_WaterFluxType_at_Column_Level_for_EM(data_list, em_stage, &
        num_filter, filter, waterflux_vars)
    !
    ! !DESCRIPTION:
    ! Pack data from ALM waterflux_vars for EM
    !
    ! !USES:
    use clm_varpar             , only : nlevsoi, nlevgrnd, nlevsno
    !
    implicit none
    !
    ! !ARGUMENTS:
    class(emi_data_list)   , intent(in) :: data_list
    integer                , intent(in) :: em_stage
    integer                , intent(in) :: num_filter
    integer                , intent(in) :: filter(:)
    type(waterflux_type)   , intent(in) :: waterflux_vars
    !
    ! !LOCAL_VARIABLES:
    integer                             :: fc,c,j
    class(emi_data), pointer            :: cur_data
    logical                             :: need_to_pack
    integer                             :: istage
    integer                             :: count

    associate(& 
         mflx_infl            => waterflux_vars%mflx_infl_col            , &
         mflx_et              => waterflux_vars%mflx_et_col              , &
         mflx_dew             => waterflux_vars%mflx_dew_col             , &
         mflx_sub_snow        => waterflux_vars%mflx_sub_snow_col        , &
         mflx_snowlyr_disp    => waterflux_vars%mflx_snowlyr_disp_col    , &
         mflx_snowlyr         => waterflux_vars%mflx_snowlyr_col         , &
         mflx_drain           => waterflux_vars%mflx_drain_col           , &
         qflx_infl            => waterflux_vars%qflx_infl_col            , &
         qflx_totdrain        => waterflux_vars%qflx_totdrain_col        , &
         qflx_gross_evap_soil => waterflux_vars%qflx_gross_evap_soil_col , &
         qflx_gross_infl_soil => waterflux_vars%qflx_gross_infl_soil_col , &
         qflx_surf            => waterflux_vars%qflx_surf_col            , &
         qflx_dew_grnd        => waterflux_vars%qflx_dew_grnd_col        , &
         qflx_dew_snow        => waterflux_vars%qflx_dew_snow_col        , &
         qflx_h2osfc2topsoi   => waterflux_vars%qflx_h2osfc2topsoi_col   , &
         qflx_sub_snow        => waterflux_vars%qflx_sub_snow_col        , &
         qflx_snow2topsoi     => waterflux_vars%qflx_snow2topsoi_col     , &
         qflx_rootsoi         => waterflux_vars%qflx_rootsoi_col         , &
         qflx_adv             => waterflux_vars%qflx_adv_col             , &
         qflx_drain_vr        => waterflux_vars%qflx_drain_vr_col        , &
         qflx_tran_veg        => waterflux_vars%qflx_tran_veg_col        , &
         qflx_rootsoi_frac  => waterflux_vars%qflx_rootsoi_frac_patch    &
         )

    count = 0
    cur_data => data_list%first
    do
       if (.not.associated(cur_data)) exit
       count = count + 1

       need_to_pack = .false.
       do istage = 1, cur_data%num_em_stages
          if (cur_data%em_stage_ids(istage) == em_stage) then
             need_to_pack = .true.
             exit
          endif
       enddo

       if (need_to_pack) then

          select case (cur_data%id)

          case (L2E_FLUX_INFIL_MASS_FLUX)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = mflx_infl(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_VERTICAL_ET_MASS_FLUX)
             do fc = 1, num_filter
                c = filter(fc)
                do j = 1, nlevgrnd
                   cur_data%data_real_2d(c,j) = mflx_et(c,j)
                enddo
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_DEW_MASS_FLUX)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = mflx_dew(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_SNOW_SUBLIMATION_MASS_FLUX)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = mflx_sub_snow(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_SNOW_LYR_DISAPPERANCE_MASS_FLUX)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = mflx_snowlyr_disp(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_RESTART_SNOW_LYR_DISAPPERANCE_MASS_FLUX)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = mflx_snowlyr(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_DRAINAGE_MASS_FLUX)
             do fc = 1, num_filter
                c = filter(fc)
                do j = 1, nlevgrnd
                   cur_data%data_real_2d(c,j) = mflx_drain(c,j)
                enddo
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_INFL)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = qflx_infl(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_TOTDRAIN)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = qflx_totdrain(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_GROSS_EVAP_SOIL)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = qflx_gross_evap_soil(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_GROSS_INFL_SOIL)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = qflx_gross_infl_soil(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_SURF)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = qflx_surf(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_DEW_GRND)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = qflx_dew_grnd(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_DEW_SNOW)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = qflx_dew_snow(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_SUB_SNOW_VOL)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = qflx_h2osfc2topsoi(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_SUB_SNOW)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = qflx_sub_snow(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_H2OSFC2TOPSOI)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = qflx_h2osfc2topsoi(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_SNOW2TOPSOI)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = qflx_snow2topsoi(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_ROOTSOI)
             do fc = 1, num_filter
                c = filter(fc)
                do j = 1, nlevgrnd
                   cur_data%data_real_2d(c,j) = qflx_rootsoi(c,j)
                enddo
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_ADV)
             do fc = 1, num_filter
                c = filter(fc)
                do j = 0, nlevgrnd
                   cur_data%data_real_2d(c,j) = qflx_adv(c,j)
                enddo
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_DRAIN_VR)
             do fc = 1, num_filter
                c = filter(fc)
                do j = 1, nlevgrnd
                   cur_data%data_real_2d(c,j) = qflx_drain_vr(c,j)
                enddo
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_TRAN_VEG)
             do fc = 1, num_filter
                c = filter(fc)
                cur_data%data_real_1d(c) = qflx_tran_veg(c)
             enddo
             cur_data%is_set = .true.

          case (L2E_FLUX_ROOTSOI_FRAC)
             do fc = 1, num_filter
                c = filter(fc)
                do j = 1, nlevsoi
                   cur_data%data_real_2d(c,j) = qflx_rootsoi_frac(c,j)
                enddo
             enddo
             cur_data%is_set = .true.

          end select

       endif

       cur_data => cur_data%next
    enddo

    end associate

  end subroutine EMI_Pack_WaterFluxType_at_Column_Level_for_EM

!-----------------------------------------------------------------------
  subroutine EMI_Unpack_WaterFluxType_at_Column_Level_from_EM(data_list, em_stage, &
        num_filter, filter, waterflux_vars)
    !
    ! !DESCRIPTION:
    ! Unpack data for ALM waterflux_vars from EM
    !
    ! !USES:
    use clm_varpar             , only : nlevsoi, nlevgrnd, nlevsno
    !
    implicit none
    !
    ! !ARGUMENTS:
    class(emi_data_list)   , intent(in) :: data_list
    integer                , intent(in) :: em_stage
    integer                , intent(in) :: num_filter
    integer                , intent(in) :: filter(:)
    type(waterflux_type)   , intent(in) :: waterflux_vars
    !
    ! !LOCAL_VARIABLES:
    integer                             :: fc,c,j
    class(emi_data), pointer            :: cur_data
    logical                             :: need_to_pack
    integer                             :: istage
    integer                             :: count

    associate(& 
         mflx_snowlyr => waterflux_vars%mflx_snowlyr_col   &
         )

    count = 0
    cur_data => data_list%first
    do
       if (.not.associated(cur_data)) exit
       count = count + 1

       need_to_pack = .false.
       do istage = 1, cur_data%num_em_stages
          if (cur_data%em_stage_ids(istage) == em_stage) then
             need_to_pack = .true.
             exit
          endif
       enddo

       if (need_to_pack) then

          select case (cur_data%id)

          case (E2L_FLUX_SNOW_LYR_DISAPPERANCE_MASS_FLUX)
             do fc = 1, num_filter
                c = filter(fc)
                mflx_snowlyr(c) = cur_data%data_real_1d(c)
             enddo
             cur_data%is_set = .true.

          end select

       endif

       cur_data => cur_data%next
    enddo

    end associate

  end subroutine EMI_Unpack_WaterFluxType_at_Column_Level_from_EM


end module EMI_WaterFluxType_ExchangeMod
