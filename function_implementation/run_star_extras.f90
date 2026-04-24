module run_star_extras

   use star_lib
   use star_def
   use const_def
   use math_lib

   implicit none

contains

!==================================================
! extras_controls
!==================================================
subroutine extras_controls(id, ierr)

   integer, intent(in)  :: id
   integer, intent(out) :: ierr
   type(star_info), pointer :: s

   ierr = 0
   call star_ptr(id, s, ierr)
   if (ierr /= 0) return

   s% extras_startup     => extras_startup
   s% extras_finish_step => extras_finish_step
   s% extras_check_model => extras_check_model

end subroutine extras_controls

!==================================================
! extras_startup 
!==================================================
subroutine extras_startup(id, restart, ierr)

   integer, intent(in)  :: id
   logical, intent(in)  :: restart
   integer, intent(out) :: ierr
   type(star_info), pointer :: s

   ierr = 0
   call star_ptr(id, s, ierr)
   if (ierr /= 0) return

end subroutine extras_startup

!==================================================
! Analytic accretion law: mdot(age)
! age in YEARS
!==================================================
real(dp) function mdot_of_age(age)

   real(dp), intent(in) :: age

! ---- parameters (match python script) ----
   real(dp), parameter :: t_switch = 100d0      ! years
   real(dp), parameter :: period   = 1d0      ! years

   real(dp), parameter :: mdot_max = 1.900d-7     ! Msun / yr
   real(dp), parameter :: mdot_min = 1.727d-7     ! Msun / yr

   real(dp), parameter :: pi = 3.141592653589793d0

   real(dp) :: mdot_mean, mdot_amp

   mdot_mean = 0.5d0 * (mdot_max + mdot_min)
   mdot_amp  = 0.5d0 * (mdot_max - mdot_min)

   if (age < t_switch) then

      mdot_of_age = mdot_max

   else

      mdot_of_age = mdot_mean + mdot_amp * &
                    sin(2.d0 * pi * (age - t_switch) / period)

   end if
end function mdot_of_age

!==================================================
! extras_finish_step
!==================================================
integer function extras_finish_step(id)

   integer, intent(in) :: id
   type(star_info), pointer :: s
   integer :: ierr
   real(dp) :: mdot

   extras_finish_step = keep_going
   call star_ptr(id, s, ierr)
   if (ierr /= 0) then
      extras_finish_step = terminate
      return
   end if

   !----------------------------------------------
   ! SETUP RUN → no accretion
   !----------------------------------------------
   if (.not. s% x_logical_ctrl(1)) then
      s% mass_change = 0d0
      return
   end if

   !----------------------------------------------
   ! NOVA RUN → analytic accretion
   !----------------------------------------------
   mdot = mdot_of_age(s% star_age)

   if (mdot < 0d0) mdot = 0d0

   s% mass_change = mdot

end function extras_finish_step

!==================================================
! extras_check_model
!==================================================
integer function extras_check_model(id)

   integer, intent(in) :: id
   type(star_info), pointer :: s
   integer :: ierr

   extras_check_model = keep_going
   call star_ptr(id, s, ierr)
   if (ierr /= 0) then
      extras_check_model = terminate
      return
   end if

   ! SETUP RUN → never terminate here
   if (.not. s% x_logical_ctrl(1)) return

   ! HEADER PHASE
   if (s% model_number < 10) return

   ! STOP AFTER 500 YEARS
   if (s% star_age >= 500d0) then
      extras_check_model = terminate
      s% termination_code = t_extras_check_model
   end if

end function extras_check_model

end module run_star_extras

