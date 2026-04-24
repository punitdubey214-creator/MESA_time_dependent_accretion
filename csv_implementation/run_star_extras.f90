module run_star_extras

   use star_lib
   use star_def
   use const_def
   use math_lib

   implicit none

   !==================================================
   ! STORAGE
   !==================================================
   integer, parameter :: max_pts = 500000
   integer :: n_pts = 0

   real(dp), dimension(max_pts) :: t_tab, mdot_tab
   real(dp) :: period   ! cycle period (years)

contains

!==================================================
! CONTROLS
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
! STARTUP: READ CSV (DAYS → YEARS)
!==================================================
subroutine extras_startup(id, restart, ierr)

   integer, intent(in)  :: id
   logical, intent(in)  :: restart
   integer, intent(out) :: ierr
   type(star_info), pointer :: s

   integer :: ios
   real(dp) :: t_day, md

   ierr = 0
   call star_ptr(id, s, ierr)
   if (ierr /= 0) return

   n_pts = 0

   open(unit=10, file='data_one_cycle_days.csv', status='old', action='read')

   do
      read(10, *, iostat=ios) t_day, md
      if (ios /= 0) exit

      n_pts = n_pts + 1
      if (n_pts > max_pts) then
         ierr = 1
         close(10)
         return
      end if

      !----------------------------------------
      ! Convert DAYS → YEARS
      !----------------------------------------
      t_tab(n_pts)    = t_day / 365.25d0
      mdot_tab(n_pts) = md

   end do

   close(10)

   if (n_pts < 2) then
      ierr = 1
      return
   end if

   !----------------------------------------
   ! DEFINE PERIOD
   !----------------------------------------
   period = t_tab(n_pts)

end subroutine extras_startup

!==================================================
! PERIODIC MDOT(age)
!==================================================
real(dp) function mdot_of_age(age)

   real(dp), intent(in) :: age
   real(dp) :: t_eff
   integer :: i

   !----------------------------------------
   ! PERIODIC WRAP
   !----------------------------------------
   t_eff = mod(age, period)

   !----------------------------------------
   ! BOUNDARIES
   !----------------------------------------
   if (t_eff <= t_tab(1)) then
      mdot_of_age = mdot_tab(1)
      return
   end if

   if (t_eff >= t_tab(n_pts)) then
      mdot_of_age = mdot_tab(n_pts)
      return
   end if

   !----------------------------------------
   ! INTERPOLATION
   !----------------------------------------
   do i = 1, n_pts - 1
      if (t_eff >= t_tab(i) .and. t_eff < t_tab(i+1)) then
         mdot_of_age = mdot_tab(i) + &
            (mdot_tab(i+1) - mdot_tab(i)) * &
            (t_eff - t_tab(i)) / (t_tab(i+1) - t_tab(i))
         return
      end if
   end do

   mdot_of_age = mdot_tab(n_pts)

end function mdot_of_age

!==================================================
! APPLY ACCRETION
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

   !----------------------------------------
   ! SETUP PHASE → NO ACCRETION
   !----------------------------------------
   if (.not. s% x_logical_ctrl(1)) then
      s% mass_change = 0d0
      return
   end if

   !----------------------------------------
   ! PERIODIC ACCRETION
   !----------------------------------------
   mdot = mdot_of_age(s% star_age)

   if (mdot < 0d0) mdot = 0d0

   s% mass_change = mdot

end function extras_finish_step

!==================================================
! STOP CONDITION
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

   if (.not. s% x_logical_ctrl(1)) return

   if (s% model_number < 20) return

   !----------------------------------------
   ! RUN UNTIL 2000 YEARS
   !----------------------------------------
   if (s% star_age >= 2000d0) then
      extras_check_model = terminate
      s% termination_code = t_extras_check_model
   end if

end function extras_check_model

end module run_star_extras
