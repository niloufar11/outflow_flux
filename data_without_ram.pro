FUNCTION data_without_ram, dat

   A_exclud = dat.ram_stretched_data
   E_exclud = Where(dat.energy(*,0) LE 6*dat.ram_energy)
 ;%%%%%%%%%%%%%%%%%%
   missing = !values.f_nan ; Missing data value is a NaN number    
    ForEach jj, E_exclud Do begin
         ForEach kk, A_exclud Do Begin
            dat.data(jj,kk) = missing
         EndForEach
      EndForEach
      dat.data(*,0) = missing          ;eliminating bin zero
RETURN, dat
;    	      RETURN,  {data_name:	dat.data_name, 				      $
;                 valid: 	1, 					      $
;                 project_name:	'FAST',					      $
;                 units_name: 	dat.units_name, 				      $
;                 units_procedure: dat.units_procedure,			      $
;                 time: 		dat.Time,				      $
;                 end_time: 	dat.END_TIME,				      $
;                 integ_t: 	dat.INTEG_T,     $
;                 nbins: 	dat.NBINS, 			      $
;                 nenergy: 	dat.NENERGY, 			      $
;                 data: 		dat.data,					      $
;                 energy: 	dat.energy, 				      $
;                 theta: 	dat.theta,                                        $
;                 phi:   	dat.phi,                                          $
;                 geom: 		dat.geom, 	       				      $
;                 denergy: 	dat.denergy,       				      $
;                 dtheta: 	dat.dtheta, 				      $
;                 dphi:   	dat.dphi,   				      $
;                 domega:	dat.domega,	 				      $
;                 pt_limits:	dat.pt_limits,				      $
;                 eff: 		dat.eff,					      $
;		           spin_fract:	dat.spin_fract,				      $
;                 mass: 		dat.mass,					      $
;                 geomfactor: 	dat.geomfactor,				      $
;                 header_bytes: 	dat.header_bytes, 				      $
;		           eff_version:   dat.eff_version,                   $
;		            pa: dat.pa,                        $
;		            mag_phi_offset: dat.mag_phi_offset,                 $		
;		            ram_bin_number: dat.ram_bin_number,                          $
;		            ram_energy: dat.ram_energy,                                  $
;		            ram_stretched_data: dat.ram_stretched_data }  
END
