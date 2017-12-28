; ===========================================
; Creates a hovmoller diagram from NCEP CFSR
; Last updated: 27 December 2017
; Created by: Alicia M. Bentley
; Email: abentley1110@gmail.com
; ===========================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"
load "~/ncl/lib/tTick.ncl"
load "~/ncl/lib/ut_string.ncl"

; ===========================================
begin

print(" ")
print("**************")
print(" START SCRIPT ")
print("**************")
print(" ")

  name = "hovmoller_diagram"    ; name of final image
	
  dir_out = "/path/to/final/hovmoller/image/"     ; path to final image

  system ("'rm' "+dir_out+name+".png")

  f = addfile ("/cfsr/data/2006/v.2006.0p5.anl.nc","r")
  fmean = addfile ("/cfsr/data/climo/mean/v.0p5.mean.climo.nc","r")
  fstdev = addfile ("/cfsr/data/climo/stdev/v.0p5.stdev.climo.nc","r")
  time = f->time
  
;-----------------------------------------------
  
  ; Set the start and end dates
  syyyy = floattoint(2006)    
  smm = floattoint(10)          
  sdd = floattoint(22)
  shh = floattoint(00)
  sdate = cd_inv_calendar(syyyy,smm,sdd,shh,00,00,time@units,0)
  
  eyyyy = floattoint(2006)    
  emm = floattoint(10)          
  edd = floattoint(30)
  ehh = floattoint(18)
  edate = cd_inv_calendar(eyyyy,emm,edd,ehh,00,00,time@units,0)
    
  print("Start Date:  "+ut_string(sdate,""))
  print("End Date:    "+ut_string(edate,""))
  print(" ")
  
  sdoy = day_of_year(syyyy,smm,sdd)
  edoy = day_of_year(eyyyy,emm,edd)
;  print("sdoy: "+sdoy)
;  print("edoy: "+edoy)
  
;------------------------------------------------
  
  v_wind_orig = f->v({sdate:edate},{250},{40:60},:) ; Get wind at 250-hPa and between (40N-60N)
  v_wind = dim_avg_n_Wrap(v_wind_orig,1)  		; Average over latitude (40N-60N)
  v_wind = lonFlip(v_wind)                     	; Flip the longitude from -180-179.5 to 0-359.5 or visa versa
  
  
  lats = v_wind_orig&lat*((355/113.)/180.)  ;;  pi/180. converts to radians
  cos_lats = cos(lats)
  
  v_wind_mean :=  dim_avg_wgt_n_Wrap(fmean->v({sdoy:edoy},:,{250},{40:60},:),cos_lats,0,2)     ; Weight by latitude
  v_wind_stdev := dim_avg_wgt_n_Wrap(fstdev->v({sdoy:edoy},:,{250},{40:60},:),cos_lats,0,2)
  
  v_wind_mean_dims = dimsizes(v_wind_mean)
  
  v_wind_mean2d = reshape(v_wind_mean, (/ v_wind_mean_dims(0)*v_wind_mean_dims(1), v_wind_mean_dims(2)/) )
  v_wind_stdev2d = reshape(v_wind_stdev, (/ v_wind_mean_dims(0)*v_wind_mean_dims(1), v_wind_mean_dims(2)/) )

  v_anom = (v_wind - v_wind_mean2d)
  v_std_anom = (v_anom/v_wind_stdev2d)

  copy_VarCoords(v_wind, v_anom)
  copy_VarCoords(v_wind, v_std_anom)

  print("Files successfully loaded and data calculated")
  print(" ")       
 
	do c=0,1
		v_wind=smth9(v_wind,.5,.09,True)				; Smooth wind and standardized anomaly fields
		v_std_anom=smth9(v_std_anom,.5,.09,True)
	end do

;=============================================
; Create hovmoller diagram itself
;=============================================
  wks_type = "png"

  wks_type@wkWidth = 2100
  wks_type@wkHeight = 2100

  wks  = gsn_open_wks (wks_type, name )            ; select file type file
  gsn_define_colormap(wks,"BlWhRe")             ; define colormap
  
;----------------------------------------------  

  res                      = True    			; Shaded standardized anomaly information           
  
  res@gsnFrame = False                                             ;DO NOT PLOT FIRST MAP
  res@gsnDraw = False

  res@cnFillOn             = True               ; turn on color fill
  res@gsnSpreadColors      = True               ; use full range of colors
  res@tiMainString         = " "  				; title and labels off
  res@gsnLeftString        = " "
  res@gsnRightString 	   = " "

  res@cnLevelSelectionMode = "ManualLevels" ; manual standardized anomaly color shading
  res@cnMinLevelValF       = -2.0	        ; min level
  res@cnMaxLevelValF       =  2.0           ; max level
  res@cnLevelSpacingF      = 0.5            ; contour level spacing
  res@lbOrientation = "Vertical"
  res@cnFillColors = (/2,20,34,39,46,55,63,70,85,102/)
  
  res@lbAutoManage = False                   ; Label Bar Information
  res@lbOrientation = "vertical"
  res@pmLabelBarOrthogonalPosF = .02  
  res@pmLabelBarHeightF = 0.70
  res@pmLabelBarWidthF = 0.08
  res@lbLabelAutoStride = True
  res@lbLabelFontHeightF = 0.017
  res@lbBoxLinesOn  = True                   
  res@lbTopMarginF = .3
  res@trYReverse = True   ; reverses y-axis
  
;-------------------------------------------------------------------

  resTick = True                 ; Specifying the time labels on the left side of image           
  resTick@Format = "%d %c %Y"
  resTick@TickAxis = "YL"
  resTick@MajorStride = 8
  res@cnLinesOn = True
  tTick( v_wind&time,  res, resTick )

  res@tmXBMode      = "Explicit"      ; Define own tick mark labels
  res@tmXBValues    = (/80,100,120,140,160,180,200,220,240/)
  res@tmXBLabels    = (/"80~F34~0~F~E","100~F34~0~F~E","120~F34~0~F~E","140~F34~0~F~E","160~F34~0~F~E","180~F34~0","160~F34~0~F~W","140~F34~0~F~W","120~F34~0~F~W"/)
  res@tmXBMinorOn = True
  res@tmXBMinorValues = (/110,130,150,170,190,210,230,250,270/)
  res@tmXTOn = False
  res@tmYROn = False
  res@tmXBLabelFontHeightF = .014

  res@trYMaxF = edate - 18
 
 ;***********************************************
 
vres = True 				; V-wind contour information

vres@gsnFrame = False                                        
vres@gsnDraw = False

vres@tiMainString = " "  ; title
vres@gsnLeftString = "250-hPa v-wind averaged over 40N-60N"
vres@gsnLeftStringFontHeightF = .012
vres@gsnRightString = "(NCEP CFSR)"
vres@gsnRightStringFontHeightF = .012

vres@cnInfoLabelOn = False                    ; Removes descriptive box in lower right corner

vres@cnFillOn = False			
vres@cnLineLabelsOn = True
vres@cnLinesOn = True
vres@cnLabelMasking = True
vres@cnLineThicknessF = 5                      ; Changes thickness of v-wind black contours
vres@cnLevelSelectionMode = "ManualLevels"     ; manual contour levels
vres@cnMinLevelValF       = -50.	           ; min level
vres@cnMaxLevelValF       =  50.               ; max level
vres@cnLevelSpacingF      = 10.                ; contour level spacing
vres@cnLineLabelAngleF = 0.0
vres@cnLineLabelInterval = 1
vres@cnLineLabelDensityF = .5
vres@cnLineLabelBackgroundColor = -1
vres@cnLineLabelFontHeightF = 0.017
vres@cnSmoothingOn = True
vres@cnSmoothingDistanceF = 0.0001

vresTick = True                                ; Specifying the time labels on LHS           
vresTick@Format = "%d %c %Y"
vresTick@TickAxis = "YL"
vresTick@MajorStride = 8
vres@cnLinesOn = True
tTick( v_wind&time,  vres, vresTick )

vres@tmXBMode      = "Explicit"                             ; Define own tick mark labels.
vres@tmXBValues    = (/80,100,120,140,160,180,200,220,240/)
vres@tmXBLabels    = (/"80~F34~0~F~E","100~F34~0~F~E","120~F34~0~F~E","140~F34~0~F~E","160~F34~0~F~E","180~F34~0","160~F34~0~F~W","140~F34~0~F~W","120~F34~0~F~W"/)
vres@tmXBMinorOn = True
vres@tmXBMinorValues = (/110,130,150,170,190,210,230,250,270/)
vres@tmXTOn = False
vres@tmYROn = False
vres@tmXBLabelFontHeightF = .014
  
vres@trYReverse               = True   ; reverses y-axis

vres@cnSmoothingOn = True
vres@cnSmoothingDistanceF = 0.0001

 ;************************************************
 
res@cnFillDrawOrder = "PreDraw"
vres@cnLineDrawOrder ="Draw"

plot = gsn_csm_hov(wks, v_std_anom(:,{80:240}), res)          ; Plot the hovmoller
contours = gsn_csm_contour(wks, v_wind(:,{80:240}), vres)
  
overlay(plot,contours)

;********************************************

draw(plot)
frame(wks)
  
;************************************************

  system("convert -trim "+name+".png "+name+".png")
  system ("mv "+name+".png "+dir_out+name+".png")

  print("**************")
  print(" END SCRIPT ")
  print("**************")
  print(" ")

end
