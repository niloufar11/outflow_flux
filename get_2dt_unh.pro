;+
;PROGRAM:	get_2dt_unh,funct,get_dat
;INPUT:	
;	funct:	function,	function that operates on structures generated 
;					by get_eesa_surv, get_eesa_burst, etc.
;				funct   = 'n_2d','j_2d','v_2d','p_2d','t_2d',
;					  'vth_2d','ec_2d', or 'je_2d'
;	get_dat:function,	function that returns 2d data structures
;				function name must be "get_"+"get_dat"  
;				get_dat = 'eesa_surv' for get_eesa_surv, 
;				get_dat = 'eesa_burst' for get_eesa_burst, etc.
;KEYWORDS
;	T1:	real or dbl	start time, seconds since 1970
;	T2:	real or dbl	end time, seconds since 1970		
;	ENERGY:	fltarr(2),	optional, min,max energy range for integration
;	ERANGE:	fltarr(2),	optional, min,max energy bin numbers for integration
;	EBINS:	bytarr(na),	optional, energy bins array for integration
;					0,1=exclude,include,  
;					na = dat.nenergy
;	ANGLE:	fltarr(2),	optional, min,max pitch angle range for integration
;	ARANGE:	fltarr(2),	optional, min,max angle bin numbers for integration
;	BINS:	bytarr(nb),	optional, angle bins array for integration
;					0,1=exclude,include,  
;					nb = dat.ntheta
;	BINS:	bytarr(na,nb),	optional, energy/angle bins array for integration
;	GAP_TIME: 		time gap big enough to signify a data gap 
;				(def 200 sec, 8 sec for FAST)
;	NO_DATA: 	returns 1 if no_data else returns 0
;	NAME:  		New name of the Data Quantity
;				Default: funct+'_'+get_dat
;	BKG:  		A 3d data structure containing the background counts.
;	FLOOR:  	Sets the minimum value of any data point to sqrt(bkg).
;	MISSING: 	value for bad data.
;					0,1=exclude,include
;	CALIB:		Calib keyword passed on to get_dat
;
;PURPOSE:
;	To generate time series data for "tplot.pro" 
;NOTES:	
;	Program names time series data to funct+"_"+get_dat if NAME keyword not set
;		See 'tplot_names.pro'.
;
;CREATED BY:
;	J.McFadden
;LAST MODIFICATION:  97/03/04
;MOD HISTORY:	
;		97/03/04	T1,T2 keywords added
;
;NOTES:	  
;	Current version only works for FAST
;-
pro get_2dt_unh,funct,get_dat, $
	T1=t1, $
	T2=t2, $
	ENERGY=en, $
	ERANGE=er, $
	EBINS=ebins, $
	ANGLE=an, $
	ARANGE=ar, $
	BINS=bins, $
	EXTRA = extra, $
	gap_time=gap_time, $ 
	no_data=no_data, $
   name  = name, $
	bkg = bkg, $
   missing = missing, $
   floor = floor, $
   CALIB = calib, $
        MASS2_CALIB = mass2_calib, $        
        EXCLUD_RAM = exclud_ram, $
        SWITCH_64_TO_16_BINS = switch_64_to_16_abins,$
        DLT_BAD_DATA = dlt_bad_data
;	Time how long the routine takes
ex_start = systime(1)

if n_params() lt 2 then begin
	print,'Wrong Format, Use: get_2dt_unh,funct,get_dat,[t1=t1,t2=t2,...]'
	return
endif

n=0
max = 30000
trat = 1.0         ; Needed for bkg sub.

routine = 'get_'+get_dat

if keyword_set(t1) then begin
	t=t1
	if routine eq 'get_fa_sebs' then dat = call_function(routine,t,/first) else dat = call_function(routine,t,CALIB=calib)
endif else begin
	t=1000		; get first sample
	dat = call_function(routine,t,/st,CALIB=calib)
endelse


if dat.valid eq 0 then begin no_data = 1 & return & end $
else no_data = 0
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    missing = !values.f_nan ; Missing data value is a NaN number    
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ytitle = funct+"_"+get_dat
last_time = (dat.time+dat.end_time)/2.

default_gap_time = 200
if dat.project_name eq 'FAST' then begin
	default_gap_time = 8.
endif
if not keyword_set(gap_time) then gap_time = default_gap_time

sum = call_function(funct,dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins, EXTRA = extra)
nargs = n_elements(sum)
time = dblarr(max)
data = fltarr(max,nargs)

if not keyword_set(missing) then missing = !values.f_nan

if keyword_set(t2) then tmax=t2 else tmax=1.e30

while (dat.valid ne 0) and (n lt max) do begin

if (dat.valid eq 1) then begin
;============================================================	
   IF KEYWORD_SET(EXTRA) Then dat = data_out_of_losscone(dat)
;============================================================	
   IF KEYWORD_SET(MASS2_CALIB) Then dat = mass2_calibration(dat)	 
;STOP
;============================================================	
   IF KEYWORD_SET(EXCLUD_RAM) Then dat = data_without_ram(dat)
;STOP
;============================================================	
   IF KEYWORD_SET(DELET_BAD_DATA) Then dat = delet_bad_data(dat)
;STOP
;============================================================	
   IF KEYWORD_SET(SWITCH_64_TO_16_BINS) Then dat = convert_64bins_solidangle_to_16bins(dat)
;============================================================	
	if abs((dat.time+dat.end_time)/2.-last_time) ge gap_time then begin
		if n ge 2 then dbadtime = time(n-1) - time(n-2) else dbadtime = gap_time/2.
		time(n) = (last_time) + dbadtime
		data(n,*) = missing
		n=n+1
		if (dat.time+dat.end_time)/2. gt time(n-1) + gap_time then begin
			time(n) = (dat.time+dat.end_time)/2. - dbadtime
			data(n,*) = missing
			n=n+1
		endif
	endif

	if keyword_set(bkg) then dat = sub3d(dat,bkg)

	sum = call_function(funct,dat,ENERGY=en,ERANGE=er,EBINS=ebins,ANGLE=an,ARANGE=ar,BINS=bins, EXTRA=extra)
	data(n,*) = sum
	time(n)   = (dat.time+dat.end_time)/2.
	last_time = time(n)
	n = n+1

endif else begin
	print,'Invalid packet, dat.valid ne 1, at: ',time_to_str(dat.time)
endelse

	dat = call_function(routine,t,/adv,CALIB=calib)
	if dat.valid ne 0 then if dat.time gt tmax then dat.valid=0

endwhile

if not keyword_set(name) then name=ytitle else ytitle=name
data = data(0:n-1,*)
time = time(0:n-1)

if keyword_set(t1) then begin
	ind=where(time ge t1)
	time=time(ind)
	data=data(ind,*)
endif
if keyword_set(t2) then begin
	ind=where(time le t2)
	time=time(ind)
	data=data(ind,*)
endif

datastr = {x:time,y:data,ytitle:ytitle}
store_data,name,data=datastr

ex_time = systime(1) - ex_start
message,string(ex_time)+' seconds execution time.',/cont,/info
print,'Number of data points = ',n

return
end

