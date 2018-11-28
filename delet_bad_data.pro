;+
; FUNCTION:
; 	 delet_bad_data
;
; DESCRIPTION:
;
;
;	function to get EFLUX of FAST Teams survey H+ species 3D data from 
;	GET_FA_tsp.PRO  routine, calculate pitch angles and add efficiency 
;	to the returned data. This routine uses 
;	GET_FA_tsp.PRO that this routine generates one spin 
;	resolution data when in TEAMS mode 6 and 7.
;
;GET_FA_tsp_SP_16pa works with all 2-d routines like get_pa_spec, get_en_spec, j_2d, ...
;
;Note:
; The data of magnetic field is used in this routine so before calling this routuine it is necessary to call ucla_mag_despin.pro:
;$ucla_mag_despin,orbit = orbit, spin_axis=spin_axis,delta_phi=delta_phi,cal_version=cal_version,tw_mat=tw_mat
;
;	A structure of the following format is returned:
;
;	   DATA_NAME     STRING    'Tms Survey Proton' ; Data Quantity name
;	   VALID         INT       1                   ; Data valid flag
; 	   PROJECT_NAME  STRING    'FAST'              ; project name
; 	   UNITS_NAME    STRING    'EFLUX'            ; Units of this data
; 	   UNITS_PROCEDURE  STRING 'proc'              ; Units conversion proc
;	   TIME          DOUBLE    8.0118726e+08       ; Start Time of sample
;	   END_TIME      DOUBLE    7.9850884e+08       ; End time of sample
;	   INTEG_T       DOUBLE    3.0000000           ; Integration time
;	   NBINS         INT       nbins               ; Number of angle bins, 16
;	   NENERGY       INT       nnrgs               ; Number of energy bins, 48
;	   DATA          FLOAT     Array(nnrgs, nbins) ; Data qauantities
;	   ENERGY        FLOAT     Array(nnrgs, nbins) ; Energy steps
;	   THETA         FLOAT     Array(nnrgs, nbins) ; Pitch angle for bins
;	   DENERGY       FLOAT     Array(nnrgs, nbins) ; Energies for bins
;	   DTHETA        FLOAT     Array(nbins)        ; Delta Theta
;	   PT_LIMITS     FLOAT     Array(2)            ; Angle min/max limits
;	   EFF           FLOAT     Array(nnrgs, nbins) ; Efficiency (GF)                    ;ASK about this array from Lynn and Eric
;	   MASS          DOUBLE    0.0104389            ; Mass eV/(km/sec)^2
;	   GEOMFACTOR    DOUBLE    0.0015              ; Bin GF
;	   HEADER_BYTES  BYTE      Array(86)	       ; Header bytes
;	   EFF_VERSION   FLOAT     1.00		       ; Calibration version
;	
; CALLING SEQUENCE:
;
; 	data = get_fa_tsp_sp (time, [START=start | EN=en | ADVANCE=advance |
;				RETREAT=retreat])
;
; ARGUMENTS:
;
;	time 			This argument gives a time handle from which
;				to take data from.  It may be either a string
;				with the following possible formats:
;					'YY-MM-DD/HH:MM:SS.MSC'  or
;					'HH:MM:SS'     (use reference date)
;				or a number, which will represent seconds
;				since 1970 (must be a double > 94608000.D), or
;				a hours from a reference time, if set.
;
;				time will always be returned as a double
;				representing the actual data time found in
;				seconds since 1970.
;
; KEYWORDS:
;
;	START			If non-zero, get data from the start time
;				of the data instance in the SDT buffers
;
;	EN			If non-zero, get data at the end time
;				of the data instance in the SDT buffers
;
;	ADVANCE			If non-zero, advance to the next data point
;				following the time input
;
;	RETREAT			If non-zero, retreat (reverse) to the previous
;				data point before the time input
;
;
; RETURN VALUE:
;
;	Upon success, the above structure is returned, with the valid tag
;	set to 1.  Upon failure, the valid tag will be 0.
;
; REVISION HISTORY:
;
;       Created By:     Niloufar Nowrouzi 2018-07-10    University of New Hampshire,
;                                               Space Physics Lab
;       Based On:       get_fa_tsp_eq_sp by Li Tang
;-
;--------------------------------------------------------------------------------
FUNCTION delet_bad_data, dat
;============================================================	
   missing = !values.f_nan ; Missing data value is a NaN number
;============================================================	 
;If dat.time GT str_to_time('1998-02-07/00:00:00') Then dat.data(*,0) = missing          ;eliminating bin zero            >>>>>Find the exact time of bad data
;If dat.time GT str_to_time('1999-03-01/17:30:00') Then   dat.data(*,6) = missing          ;eliminating bin six               >>>>>Find the exact time of bad data 

;----anodes
 anodes2 = [2, 10, 34, 42, 18, 26, 50, 58]
 anode3 = [0, 3, 6, 11, 32, 35, 38, 43, 16, 19, 22, 27, 48, 51, 54, 59] 
 anode4 = anode3 +1

  If dat.time  LT time_double('1999-01-01/00:00') Then            RETURN, dat
  If dat.time  GT time_double('1999-01-01/00:00') And dat.time  LT time_double('2000-01-01/00:00') Then anodes = [anode3]
  If dat.time  GT time_double('2000-01-01/00:00') AND dat.time  LT time_double('2002-01-01/00:00') Then anodes = [anode3, anode4]
  If dat.time  GT time_double('2001-01-01/00:00') AND dat.time  LT time_double('2003-01-01/00:00')Then anodes = [anode2, anode3, anode4]
;============================================================

   For jj = 0, 47, 1 Do begin
      ForEach kk, anodes Do Begin
         IF (dat.pa(kk) GT 22.5-11.25 And dat.pa(kk) LT 157.5+11.25) OR (dat.pa(kk) GT 202.5-11.25 AND dat.pa(kk) LT 337.5+11.25) Then dat.data(*,kk) = missing 
      EndForEach
   EndFor
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
