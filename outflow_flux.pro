pro outflow_flux

 LoadCT, 39
 path_ps_o = '~/fast_user/sawtooth/ps_o/'
 path_ps_h = '~/fast_user/sawtooth/ps_h/'
 path_tplot_o = '~/fast_user/sawtooth/tplot_o/'
 path_tplot_h = '~/fast_user/sawtooth/tplot_h/'

 sed_data = Read_CSV('~/fast_user/sawtooth/esa.csv')
 structure = Read_CSV('~/fast_user/sawtooth/tooth_orbit_list.csv') 

 orbit1 = StrCompress(structure.field5)
 orbit2 = StrCompress(structure.field6)
 orbit3 = StrCompress(structure.field7)  
 orbt = [[orbit1],[orbit2],[orbit3]]

 orb = Strarr(52000)
  last_orb = Fix(' ') 
  READ, last_orb, PROMPT='Enter last orbit: '
;--------------------------------------------------------------------------------
;loading magnetic field data for each individual orbit
;--------------------------------------------------------------------------------
	ucla_mag_despin,orbit = orbit, spin_axis=spin_axis,delta_phi=delta_phi,cal_version=cal_version,tw_mat=tw_mat
	get_data, 'fa_vel', data = fa_vel_from_ucla
	store_data, 'fa_vel_from_ucla', data = {x:fa_vel_from_ucla.x, y:fa_vel_from_ucla.y}, lim={YTITLE: 'fa_vel'}
;GOTO, JUMP00
;--------------------------------------------------------------------------------
;-VARIABLES
load_data = ['fa_tsp_sp', 'fa_tso_sp']
datfinal = ['fa_tsp_sp_final_ver', 'fa_tso_sp_final_ver']
dat_str = ['fa_tsp_sp_unh', 'fa_tso_sp_unh']
mass2 = ['fa_tsp_sp_mass2', 'fa_tso_sp_mass2']
unh = ['fa_tsp_sp_unh', 'fa_tso_sp_unh']
fname = ['H', 'O']
unit = 'EFLUX'
;--------------------------------------------------------------------------------
; For i = 170, 246, 1 Do begin 
 For i = 0, 246, 1 Do begin 
   For mm = 0, 2, 1 Do begin
   print,orbt(i,mm)
   orb(i) = StrCompress(orbt(i,mm),/remove_all)	  
   If orbt(i,mm) EQ 0 Then GoTo, Jump1
   check = Where(sed_data.field01 EQ orb(i),m0)
   If m0 EQ 0 Then STOP
   If sed_data.field02(check(0)) EQ 'No Data' Then Goto, Jump1 

   data = get_fa_orbit_times_db(orbt(i,mm))
      delta_time = 120 ;(S) to be sure that we use time of the selected orbit 
      s_t = data.START + delta_time 
      end_t =  data.FINISH - delta_time
      t0 = time_string(s_t)
      t1 = time_string(end_t)
      check_time_devision = what_orbit_is(s_t)

;-----

      ilat, t0, t1, invlat, mltime
		ilat = invlat

;------				
      N_ind = Where(ilat GT 0, d1)      
      S_ind= Where(ilat LT 0, d2)         
;----------------------------------     
		get_data, 'ALT', data=tmp      
	   t = tmp.x

	   t_n = t[N_ind]
	   t_s = t[S_ind]
	   
	   mintn = t_n[0]                            ;when FAST comes to northern hemisphere
	   maxtn = t_n[n_elements(t_n)-1]   ;when FAST goes from northern hemisphere

	   mints = t_s[0]                            ;when FAST comes to southern hemisphere
	   maxts = t_s[n_elements(t_s)-1]   ;when FAST goes from southern hemisphere
	   
;-------------------------------------------------------------------------------------------------------------------------------------------
;prepparing the time array    3D-data
;-------------------------------------------------------------------------------------------------------------------------------------------
      t2 = tmp.x[n_elements(tmp.x)-1]
      t1 = tmp.x[0]

;****************************EPHEMERIS******************************    
;---------------------------------------------------------------------------------
;We need to know that if FAST gives us data from both hemisphere or just 
;from one hemisphere.
;---------------------------------------------------------------------------------

  	get_en_spec, 'fa_tso_sp', t1 =t1, t2 = t2, gap_time=30, name='e_O_3D', units=unit
   	                    
   get_data, 'e_O_3D', data = E_o_3D
  
    iuse_3D = where(E_o_3D.x ge t1 and E_o_3D.x le t2, count)
    tarr_3D = E_o_3D.x[iuse_3D]

    mint = E_o_3D.x[iuse_3D[0]]

    maxt = E_o_3D.x[n_elements(iuse_3D)-1]   
    If mint GE mintn and maxt LE maxtn Then Begin 
      cc1 = 1
      cc2 = 0
    EndIf
    
    If mint GE mints and maxt LE maxts Then Begin
      cc1 =0 
      cc2 = 1
    EndIf
        
    If mint LT maxtn and maxt GT mints Then Begin
      cc1 = 1
      cc2 = 1
   EndIf
        
   hem_arr = StrArr(2)
   If cc1 NE 0 Then hem_arr(0) ='N'
   If cc2 NE 0 Then hem_arr(1) ='S'
;--------------------------------------------------------------------------------
For ss = 0,1, 1 Do Begin

   If hem_arr[ss] NE '' Then hem = hem_arr[ss] Else Goto, Jump2
   result_out = File_test('./ps_o/'+'o_'+orb(i)+'_'+hem+'.ps')
   If result_out EQ 1 Then GoTo, Jump2  

   If ss EQ 0 Then t = t_n
   If ss EQ 1 Then t = t_s
 loss_cone, t[0], t[n_elements(t)-1]
For qq = 0, 1, 1 Do Begin
t(0) = time_double('1996-10-30/13:15:00')
 ;----------------------------------------------------------------------------   
;loading mass2 calibration:
;----------------------------------------------------------------------------   

load_calibration_datasets_mass2_calfrac, t1 = t(0), data_str = load_data(qq)         ;species dependent   

 ;----------------------------------------------------------------------------  
 ;-------------------------------energy spectrogram----------------------

  	get_en_spec, datfinal(qq), t1 =t[0], t2 = t[n_elements(t)-1], gap_time=30, name='en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, units=unit

    get_data, 'en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, data = en_final_data
    iuse_3D = where(en_final_data.x ge t(0) and en_final_data.x le t(n_elements(t)-1), count)
    tarr_3D = en_final_data.x(iuse_3D)
    
      options, 'en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'spec',1 
      options,'en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'ztitle', ztitle
   	options,'en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'xthick', 1      
      options,'en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'xticklen', -0.05
   	options,'en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'ythick', 1     
      options,'en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'yticklen', -0.015            
   	options,'en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'zthick', 2      
      options,'en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'zticklen', -0.5
      ylim,'en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 1, 12000, 1
	   options,'en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'x_no_interp', 1
	   options,'en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'y_no_interp', 1
	   options,'en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem,'ytitle', fname(qq)+'!U+!N'+' ,(ev)!C!C calib'
      If qq EQ 0 Then zlim, 'en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 1e3, 1e7, 1 ;1, 1e4, 1 
      If qq EQ 1 Then zlim, 'en_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 1e3, 1e7, 1 ;1, 1e4, 1 
;---------------------------------------------------------------------------------- 
;-------------------------------pitch angle spectrogram----------------------    

    get_pa_spec, datfinal(qq), t1 =t[0], t2 = t[n_elements(t)-1], gap_time=50, energy= [1, 12000],$
     name='pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, units=unit, /shift90
    
;-set tplot options    
		
   options,'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'spec',1
	options, 'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'ztitle', 'eV/cm!U2!N!N-s-sr-eV'
   ylim, 'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, -90, 270, 0
   options, 'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem,  'xthick', 1
   options, 'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'xticklen', -0.05   
   options, 'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem,  'ythick', 1
   options, 'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'yticklen', -0.015
   options, 'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem,  'zthick', 2
   options, 'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'zticklen', -0.5
   options,'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem,  'yticks', 5
   options,'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'ytickv', [-90, 0, 90, 180, 270]
	options, 'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'x_no_interp', 1
	options, 'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'y_no_interp', 1
	options, 'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 'ytitle', fname(qq) +' ,PA!C!C'+'1-1k (ev)!C!C calib'
If qq EQ 0 Then zlim, 'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 1e3, 1e7, 1
If qq EQ 1 Then zlim, 'pa_spec_'+fname(qq)+'_'+orb(i)+'_'+hem, 1e3, 1e7, 1 
;---------------------------------------------------------------------------------- 
;-------------------------------outflow flux-------------------------------------       
;   get_2dt_unh, 'j_2d_unh', datfinal(qq), t1 =t[0], t2 = t[n_elements(t)-1], $
;    name = 'j2d_'+fname(qq)+'_'+orb(i)+'_'+hem, gap_time = 50, ENERGY = [1, 12000];, EXTRA = 1, $
 ;   MASS2_CALIB = 1, EXCLUD_RAM = 1, DLT_BAD_DATA = 1, SWITCH_64_TO_16_BINS = 1
;      get_data, 'j2d_16bins', data = j2dAE_16pa
EndFor

popen, 'first_plot',/port
   tplot, ['en_spec_H_758_S', 'en_spec_O_758_S', 'pa_spec_H_758_S', 'pa_spec_O_758_S']
pclose

STOP
END
