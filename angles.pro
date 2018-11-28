Function angles, inputTime
;**IMPORTANT**
;Before calling angles.pro function you need to run ucla_mag_despin.pro
;puprose: 
;               calculation of pitch angle based on the magnetic field in S/C coordinate system  
;INPUT:   
;           tarr_3D, binned time spane
;           dat3d_str, a 3-D TEAMS data structure
;           range: determinig the range of desire output, could be '0-360' or '0-180'
;OUTPUT:
;        alpha1: an array of pitch angle, (n_elememnrs(tarr_3d, 64))
;        thet: an array of magnetic field theta,  (n_elememnrs(tarr_3d, 64))
;        phip1: an array of magnetic field phi,  (n_elememnrs(tarr_3d, 64))
;        domega: differential of solid angle in space craft coordinate system  (n_elememnrs(tarr_3d, 64))
;        Btot_3Dint: the magnetude of magnetic field in S/C coordinate system, it is interpolated over tarr_3d time array, (n_elememnrs(tarr_3d, 64))
;        xmod_3D: the time array of magnetic field over determined time spane, 
;        Btot_3D: the magnetude of magnetic field in S/C coordinate system, (n_elements(xmod_3d, 64))
;--------------------------------------------------------------------------------
;	 'you need to run ucla_mag_despin procedure' 
;--------------------------------------------------------------------------------  
   time = inputTime		
   dat = get_fa_tso_sp(Time) 	    
   missing = !values.f_nan              

 ;--------------------------------------------------------------------------------

   get_data, 'Bx_sc', data= Bxsc
   nmax = n_elements(Bxsc.x)
              
	get_data, 'Bx_sc', data = Bx  ;Bx_sc, By_sc, Bz_sc are the components of B in spacecraft coordinate system
	get_data, 'By_sc', data = By
	get_data, 'Bz_sc', data = Bz
;----------Preparing for 3D
ind = value_locate(Bx.x, dat.time)

	Bx_3D = Bx.y(ind)
	By_3D = By.y(ind)
	Bz_3d = Bz.y(ind)
	Btot_3D = sqrt(Bx_3D^2 +By_3D^2+Bz_3D^2)
	Bp_3D = sqrt(Bx_3D^2 + By_3D^2)

	theta_B3D = Atan(Bz_3D,Bp_3D)                              ; alpha = Atan(y,x) ------> radian
   Phi_B3D = Atan(By_3D, Bx_3D)

      cart_to_sphere, Bx_3D, By_3D, Bz_3D, Br,thet, phip        ;original

;--------------------------------------------------------------------------------------------------------	
;A time series of pitch angle for 64 angle bins      3D-data
;--------------------------------------------------------------------------------------------------------
   theta_p = dat.theta
   phi_p = dat.phi

    hdr_mag = get_fa_tsop_hdr(dat.time)
          if hdr_mag.valid eq 0 then hdr_mag_phi= !values.f_nan $
          else hdr_mag_phi = (ishft(fix(hdr_mag.bytes(2)), -4) + $
                  ishft(fix(hdr_mag.bytes(3)), 4)) * !pi / 2048.
   mag_phi_offset = (hdr_mag_phi*!Radeg + phip) Mod 360
   phip1 = (-(mag_phi_offset - phip)mod 360) 


   pa = FltArr(64)
   pa(*) = !Values.F_NAN 
   range = '0-360' 

      For jj = 0 ,63 ,1 Do Begin         
         If range EQ '0-360' Then  pa(jj) = Call_Function('pangle1', theta_p(0,jj), phi_p(0,jj), thet, phip1)     ; original    
         If range EQ '0-180' Then  pa(jj) = Call_Function('pangle', theta_p(0,jj), phi_p(0,jj), thet, phip1)     ; original    
      EndFor
      
  pa = pa(0:63)
;--------------------------------------------------------------------------------------------------------
;loss cone angle
;--------------------------------------------------------------------------------------------------------

get_data, 'loss_cone_ang', data = losscone
lc_ind =value_locate(losscone.x, dat.time)
If lc_ind EQ -1 then losscone_angle = missing Else losscone_angle = losscone.y(lc_ind)

;---------------------------------------------------------------------------------------------------
;Angular data of ram plasma:
;-------------------------------------FAST velocity--------------------------------------------- 
;porpose: figuring out the direction of FAST motion in space craft coordinate system(SC)
;Since ilat.pro produces tplot of 'fa_vel' with different time interval from ucla_mag_despin.pro,
;I renamed 'fa_vel' from ucla_mag_despin.pro to 'fa_vel_from_ucla'.

get_data, 'fa_vel_from_ucla', data = Vel_fa_gei
 vel_fa_sc = vel_fa_gei

 get_data,'despun_to_gei', data = sc_to_gei 
vel_fa_sc.y = transform_vector(sc_to_gei.y,vel_fa_gei.y,/inverse)

	ind1 = value_locate(vel_fa_sc.x, inputTime)
	vel_fa_sc_x = vel_fa_sc.y(ind1,0)
	vel_fa_sc_y = vel_fa_sc.y(ind1,1)
	vel_fa_sc_z = vel_fa_sc.y(ind1,2)

   cart_to_sphere, -vel_fa_sc_x, -vel_fa_sc_y, -vel_fa_sc_z,  1, ram_theta_sc, ram_phi_sc, ph_0_360 = 1

;--We exclude the ram effect based on the direction of FAST SC

ram_phi_sc = (ram_phi_sc+360) MOD 360
ram_phi_tms = (-(mag_phi_offset  -ram_phi_sc)+360) mod 360

angles_data = {pa: pa,                  $
               losscone_angle: losscone_angle , $
               mag_phi_offset: mag_phi_offset,              $
               phi_B: phip1,           $
               theta_B: thet,                $
               phi_ram_tms: ram_phi_tms,        $
               theta_ram_tms: ram_theta_sc}


RETURN, angles_data
END
