Function excld_ram, spec, inputTime

   inputTime = inputTime
   If spec EQ 3 Then Begin
      dat = get_fa_tso_sp(inputTime, START = start, EN = en, ADVANCE = advance, RETREAT=retreat)  
	EndIf

   If spec EQ 0 Then Begin
      dat = get_fa_tsp_sp(inputTime, START = start, EN = en, ADVANCE = advance, RETREAT=retreat)  
	EndIf
;   IF NOT dat.valid THEN       RETURN, {data_name: 'Null', valid: 0}
	 dat.data(*,0) = !VALUES.F_NAN
   angles = angles(inputTime)
   phi_ram_tms = angles.phi_ram_tms
   theta_ram_tms = angles.theta_ram_tms

;-------------------------------------FAST velocity--------------------------------------------- 
;porpose: figuring out the direction of FAST motion in space craft coordinate system(SC)
;Since ilat.pro produces tplot of 'fa_vel' with different time interval from ucla_mag_despin.pro,
;I renamed 'fa_vel' from ucla_mag_despin.pro to 'fa_vel_from_ucla'.
   get_data,'fa_vel_from_ucla', data = Vel_fa_gei
   vel_fa_sc = vel_fa_gei
   get_data,'despun_to_gei', data = sc_to_gei 
   
   vel_fa_sc.y = transform_vector(sc_to_gei.y, vel_fa_gei.y, /inverse)   


	ind1 = value_locate(vel_fa_sc.x, inputTime)
	vel_fa_sc_x = vel_fa_sc.y(ind1,0)
	vel_fa_sc_y = vel_fa_sc.y(ind1,1)
	vel_fa_sc_z = vel_fa_sc.y(ind1,2)
   
   If dat.valid GT 0 Then Begin
      RightEdge = dat.phi(0,*) -11.25  
      PF1 = [8, 40, 24, 56]
      PF2 = PF1 + 1
      PF3 = [ 2, 10, 34, 42, 18, 26, 50, 58]
      PF4 = [0, 3, 6, 11, 32, 35, 38, 43, 16, 19, 22, 27, 48, 51, 54, 59]
      PF5 = PF4 + 1 
      PF6 = PF3 + 3
      PF7 = PF1 + 6
      PF8 = PF1 + 7
   
      low_edge = Reform(dat.theta(0,*) - 11.25)
      up_edge = Reform(dat.theta(0,*) + 11.25)
      right_edge = Replicate(0.0, 64)
      left_edge = Replicate(0.0, 64)
    
      ForEach jj, PF4 Do left_edge(jj) = dat.phi(0,jj) - 11.25
      ForEach jj, PF5 Do left_edge(jj) = dat.phi(0,jj) - 11.25 
      ForEach jj, PF3 Do left_edge(jj) = dat.phi(0,jj) - 22.5     
      ForEach jj, PF6 Do left_edge(jj) = dat.phi(0,jj) - 22.5      
      ForEach jj, PF2 Do left_edge(jj) = dat.phi(0,jj) - 45
      ForEach jj, PF1 Do left_edge(jj) = dat.phi(0,jj) - 45        
      ForEach jj, PF7 Do left_edge(jj) = dat.phi(0,jj) - 45
      ForEach jj, PF8 Do left_edge(jj) = dat.phi(0,jj) - 45   
 
      ForEach jj, PF4 Do right_edge(jj) = dat.phi(0,jj) + 11.25
      ForEach jj, PF5 Do right_edge(jj) = dat.phi(0,jj) + 11.25 
      ForEach jj, PF3 Do right_edge(jj) = dat.phi(0,jj) + 22.5     
      ForEach jj, PF6 Do right_edge(jj) = dat.phi(0,jj) + 22.5      
      ForEach jj, PF2 Do right_edge(jj) = dat.phi(0,jj) + 45
      ForEach jj, PF1 Do right_edge(jj) = dat.phi(0,jj) + 45        
      ForEach jj, PF7 Do right_edge(jj) = dat.phi(0,jj) + 45
      ForEach jj, PF8 Do right_edge(jj) = dat.phi(0,jj) + 45   

      ram_bin_vel  = Where(phi_ram_tms  GT left_edge AND phi_ram_tms LE right_edge AND theta_ram_tms GE low_edge AND theta_ram_tms LT up_edge, c_vel)
      ram_energy  =  0.5*dat.mass*((vel_fa_sc_x )^2 + (vel_fa_sc_y )^2 + (vel_fa_sc_z )^2)
      If c_vel EQ 0 Then stop
   EndIf Else Begin
      ram_bin_vel  = !values.f_NAN
      ram_energy  = !values.f_NAN
   EndElse
   ram_bin_vel = ram_bin_vel(0)
;STOP
   Ebin = MAX(Where(dat.energy(*,0) GE ram_energy),/nan)
   ram_bin = Where(dat.data(Ebin, *) GT 0 AND  dat.data(Ebin, *) EQ max(dat.data(Ebin, *)), c)
   ram_bin1 = ram_bin
   If c GT 1 Then  Begin
   bin_min = min(ABS(dat.phi(Ebin,ram_bin1) - dat.phi(Ebin, ram_bin_vel)))
   ram_bin = ram_bin1(Where(ABS(dat.phi(Ebin,ram_bin1) - dat.phi(Ebin, ram_bin_vel)) EQ bin_min))
   ram_bin = ram_bin(0)
;   stimate_ind = value_locate(dat.phi(Ebin,ram_bin1), dat.phi(Ebin, ram_bin_vel))
;   if stimate_ind NE -1 then ram_bin = ram_bin(stimate_ind) Else ram_bin = ram_bin
;    ram_bin = ram_bin(value_locate(dat.phi(Ebin,ram_bin1), dat.phi(Ebin, ram_bin_vel))) 

    EndIf Else Begin 
      If c EQ 1 Then ram_bin = ram_bin(0)
      If c EQ 0 Then ram_bin = ram_bin_vel
   EndElse

ram_bin = ram_bin_vel
;--------------------------------------------------------------------------------------------------
;- A width for ram_bin
;--------------------------------------------------------------------------------------------------

r = (dat.phi(0,ram_bin) - 45 + 360) Mod 360
If r EQ 0 Then r = 360
l = (dat.phi(0,ram_bin) + 45 + 360) Mod 360
If dat.phi(0,ram_bin) LE 303.75 AND dat.phi(0,ram_bin) GE 56.25 Then $ 
   ram_stretched_data  = Where(dat.phi(0,*) GE r AND dat.phi(0,*) LE l)   $
Else Begin
   ram_stretched_data  = Where(dat.phi(0,*) GE r OR  dat.phi(0,*) LE l)   
EndElse

;---------------------------------------------------------------------------------------------   

   ram_bin= ram_bin
   ram_data = {ram_bin_number: ram_bin,           $
                     ram_energy: ram_energy,             $
                     ram_stretched_data :ram_stretched_data                     $
                     }
Return, ram_data

End
