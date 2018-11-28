FUNCTION convert_64bins_solidangle_to_16bins, dat 

 ;%%%%%%%%%%%%%%%%% make the routine of convert_64bins_solidangle_to_16bins begins from here
   missing = !values.f_nan     
   paBin = 22.50 ; Set the pitch angle bin width You can experiment with 11.25 as well
   PaRange = 360.0 ; Set the pitch angle range
   nmax = PaRange / paBin ; Get the number of pitch angle bins
   ; Calculate the start and end pitch angle for each pitch angle bin
   BinStartStop = 0.
   
   FOR ss = 1, nmax DO BinStartStop = [BinStartStop, ss*paBin]

   ; Calculate the start and end pitch angle for each pitch angle bin
   BinCenter = 0.
   FOR ss = 1, (nmax*2)-1,2 DO BinCenter = [BinCenter, ss*(PaBin/2.)]
   BinCenter = BinCenter(1:*)
 	n = N_ELEMENTS(tarr_3d)-1
	J_O = FLTARR(48, nmax)
	J_Z = FLTARR( nmax) 
	data_16bins = FLTARR(48, nmax)
	angle = FLTARR(48, nmax)
	energy_16bins = FLTARR(48, nmax) 
	denergy_16bins = FLTARR(48, nmax) 

   convert_tms_units, dat, 'EFLUX' 

	tmpdata   = REFORM(dat.data)
   tmpvar    = REFORM(dat.pa)
   J_Z(*) = BinCenter ; Set the pitch angle bin center values for all time steps      
;STOP
   FOR  dd = 0, 47, 1 DO BEGIN ; Loop over all pitch angle bins
      For jj = 0, nmax-1 Do begin
      ; Find the angular bins that have pitch angles that fall 
      ; within the particular pitch angle bin. The variable pabinind
      ; will contain that indices of the 64 anglular bins that have
      ; pitch angle that falls in this particular pitch angle bin
      pabin_ind = WHERE(tmpvar GE BinStartStop(jj) AND tmpvar LT BinStartStop(jj + 1), c_pabin_ind)

	   IF c_pabin_ind GT 0 THEN BEGIN ; If data for this particular pitch angle bin were found
	      xx = -1
	      For zz = 0, c_pabin_ind-1, 1 Do begin	         
	         If FINITE(tmpdata(dd, pabin_ind(zz))) EQ 1 Then Begin
	            xx = xx+1
	            pabin_ind(xx) = pabin_ind(zz)
	         EndIf  
	      EndFor 
	      If xx GT -1 Then pabin_ind = pabin_ind(0:xx)
	      aweight = dat.domega(pabin_ind)
	      J_O(dd, jj) = TOTAL((tmpdata(dd, pabin_ind) * aweight), /NaN) / TOTAL(aweight, /NaN)
      ENDIF ELSE BEGIN ; If data for the particular pitch angle bin were not found then give this bin a NaN value
         J_O(dd, jj) = missing
      ENDELSE
      data_16bins(dd, jj) = J_O(dd, jj)
      ENDFOR
   ENDFOR
    
   For 	jj = 0, nmax-1 Do angle(*,jj) = Replicate(J_Z(jj), 48) 
   
   ;dangle = Replicate(22.5, 16)
		dangle = Replicate(paBin, nmax)

   For yy = 0,47, 1 Do Begin 
      energy_16bins(yy,*) = Replicate(dat.energy(yy, 0), nmax)
      denergy_16bins(yy,*) = Replicate(dat.denergy(yy, 0), nmax)
   EndFor
    ;%%%%%%%%%%%%%%%%% make the routine of convert_64bins_solidangle_to_16bins ENDS from here
 ;STOP
 ;%%%%%%%%%%%%%%%%% 
 	      RETURN, {DATA_NAME: dat.data_name, $
                  VALID: 1, $
                  PROJECT_NAME: 'FAST', $
                  UNITS_NAME: 'EFLUX', $
                  UNITS_PROCEDURE: 'convert_tms_units', $
                  TIME: dat.time, $
                  END_TIME: dat.end_time, $
                  INTEG_T: dat.integ_t, $
                  NBINS: 16, $
                  NENERGY: 48, $
                  DATA: data_16bins, $
                  ENERGY: energy_16bins, $
                  THETA: angle, $
                  DENERGY: denergy_16bins, $
                  DTHETA: dangle, $
                  PT_LIMITS: dat.pt_limits, $
                  MASS: dat.mass, $
                  GEOMFACTOR: dat.geomfactor, $
                  HEADER_BYTES: dat.header_bytes, $
                  EFF_VERSION: dat.eff_version}  
END
