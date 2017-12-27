; ====================================================
; Plots MSLP/thickness/jets from GFS archive/forecast
; Last updated: 27 December 2017
; Created by: Alicia M. Bentley
; Email: abentley1110@gmail.com
; ====================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/calendar_decode2.ncl"
load "~/ncl/lib/tTick.ncl"
load "~/ncl/lib/ut_string.ncl"
load "~/ncl/lib/latlon.ncl"
load "~/ncl/lib/shea_util.ncl"
; ===========================================

begin

print(" ")
print("**************")
print(" START SCRIPT ")
print("**************")

;---------------------------------------------------

datestr = systemfunc("date")			; Print current date/time
print("Current date/time:  "+datestr)

quote = inttochar(34) 
cyyyy = stringtoint(systemfunc("date "+quote+"+%Y"+quote))       ; Extract components of current date/time
cmm = stringtoint(systemfunc("date "+quote+"+%m"+quote))
cdd = stringtoint(systemfunc("date "+quote+"+%d"+quote))
chh = stringtoint(systemfunc("date "+quote+"+%H"+quote))
timeUnits = "hours since 1800-01-01 00:00:00"
cdate = cd_inv_calendar(cyyyy,cmm,cdd,chh,00,00,timeUnits,0)

archive_days = 2						; How many archive days you want to plot
bdate = cdate
bdate = bdate - archive_days*24			; Go from current date the number of archive days
dateInformation = calendar_decode2(bdate,-5)
syyyy = dateInformation(:,0)			; Start date in yyyy mm dd hh
smm = dateInformation(:,1)
sdd = dateInformation(:,2)
shh = dateInformation(:,3)

ldate = cdate							
ldate = ldate - 24						; Go back one day from current date to last day of archive
dateInformation = calendar_decode2(ldate,-5)
eyyyy = dateInformation(:,0)			; End date in yyyy mm dd hh
emm = dateInformation(:,1)
edd = dateInformation(:,2)

if shh .lt. 7 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,00,00,00,timeUnits,0) ; Convert to integers to use cd_inv_calendar function
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 00  ; Choose forecast synoptic time (e.g., 00 will plot the forecast initialized at 0000 UTC)
else if shh .ge. 7 .and. shh .lt. 16 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,06,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 06
else if shh .ge. 16 .and. shh .lt. 22 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,12,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 12
else if shh .ge. 22 then
     sdate = cd_inv_calendar(syyyy,smm,sdd,18,00,00,timeUnits,0)
     edate = cd_inv_calendar(eyyyy,emm,edd,18,00,00,timeUnits,0)
     hr = 18
end if
end if
end if
end if

print("GFS forecast used: "+hr+"Z run")
print("sdate: "+ut_string(sdate,""))
print("edate: "+ut_string(edate,""))

;;; ***Note end of analysis (edate) must ALWAYS end at 18 UTC***
;;; Grib files are packaged in .tar format, which saves daily files (00,06,12,18) 
;;; bundeling into one file. This program bridges the gap between 18 UTC and your 
;;; forecast initialization time by filling in with the forecast analysis grib files 

fcast = "yes" 	; Do you want to plot the 192 hour GFS forecast?
untar = "no"	; Do you want to untar the archived GFS grib files?	        	
  
fdate = edate  
fdate = fdate + hr + 6  ; Date/time of first forecast time to plot

print("fdate: "+ut_string(fdate,""))
print(" ")
    
imgcount = 1   	; Number of the first image to plot
  				   
name = "mslp_jet"

dir_grib = "/lb13/abentley/scripts/github/gfs/grib/"	
dir_plot = "/lb13/abentley/scripts/github/gfs/"	        

;-----------------------------------------------------
; Create archived GFS plots from sdate to fdate
;-----------------------------------------------------

do tim = sdate,fdate,6
        tim@units = "hours since 1800-01-01 00:00:00"   ;define units for tim
        if (tim .eq. sdate) then
             print("Time to Plot = Start Date")
             print("Plotting archived GFS analyses")
        end if
         
        ; Make a few date strings from the current time to plot (yymmdd) and (hh)
        str_time = ut_string(tim,"%y%N%D")
        str_hr = ut_string(tim,"%H")
        print(" ")
        print("tim: "+ut_string(tim,""))
        print("str_time: "+str_time+" str_hr: "+str_hr)
  
        ; Gets the tar file and opens the grib files
    	if (tim .le. edate) then
         	if (str_hr .eq. "00") .and. (untar .eq. "yes") then
  	        	system("cp /nfs/nmc2/grib/gfs255_anl_"+str_time+".grb2.tar "+dir_grib)
  	        	system("tar -xvf "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar -C "+dir_grib)
  	        	system("rm -f "+dir_grib+"*.grb2.tar")
             end if
             	
             ; Read in files that don't start at 00 UTC
             if( (tim .eq. sdate) .and. (str_hr .ne. "00") .and. (untar .eq. "yes")) then
                system("cp /nfs/nmc2/grib/gfs255_anl_"+str_time+".grb2.tar "+dir_grib)
  	            system("tar -xvf "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar -C "+dir_grib)
  	            system("rm -f "+dir_grib+"*.grb2.tar")
             end if 

            filename = dir_grib+"GFS_"+str_time+"_"+str_hr+"_000.grb2"
			if (isfilepresent(filename)) then
;				 print("File is present!")
			else
				filename = dir_grib+"GFS_"+dne_time+"_"+dne_hr+"_000.grb2"
				print("File does not exist. Using last file that did...")
            end if
            dne_time = ut_string(tim,"%y%N%D")
			dne_hr = ut_string(tim,"%H")
			fhr_cur = 0
			spot = 0
        end if

          
        if (tim .gt. edate) .and. (tim .lt. fdate) then    ; Fill in data between edate and fdate
             	f = spot
             	fhr  := (/0/)
                 	if (fhr(f) .lt. 10) then
                      	filefhr = "00"+fhr(f)
                 	else if ((fhr(f) .lt. 100) .and. (fhr(f) .gt. 10)) then
                      	filefhr = "0"+fhr(f)
                 	else if (fhr(f) .gt. 100) then
                      	filefhr = fhr(f)
                 	end if 
                 	end if
                 	end if
            	filename = "/nfs/cas2/unidata/GRIB/gfs0p5deg/GFS_"+str_time+"_"+str_hr+"_"+filefhr+".grb2"
            	fhr_cur = fhr(f)
       	 end if
       	 	

;**********************************************************************************************************
; Download data from GFS files
;**********************************************************************************************************

if (tim .ne. fdate) then

  print("filename: "+filename)
  a = addfile(filename,"r")

  levs = (/100000,50000/) ; Needs to be in Pa
;  levs_wind  = (/20000,25000,30000/)
  levs_wind  = (/25000/)

  mslp = a->PRMSL_P0_L101_GLL0(::-1,:)
  mslp = mslp * .01

  g = a->HGT_P0_L100_GLL0({levs},::-1,:)
  thick = g(0,:,:)
  thick = g({min(levs)},:,:)-g({max(levs)},:,:)
  thick = thick * .1

	do d=0,1
		thick=smth9(thick,.5,.25,True)
	end do

  u_all = a->UGRD_P0_L100_GLL0({levs_wind},::-1,:)
  v_all = a->VGRD_P0_L100_GLL0({levs_wind},::-1,:)

  if(dimsizes(levs_wind).eq.1) then
    u = u_all
    v = v_all
  else
    u = dim_avg_n_Wrap(u_all,0)
    v = dim_avg_n_Wrap(v_all,0)
  end if

  jet = u
  jet = ((u^2)+(v^2))^0.5

;  print("Successfully got data from files!")

;--------------------------------------------------------------
; Specify domain(s) to plot and loop through at each time step
;--------------------------------------------------------------
  
folder = (/"northamer","pacific"/)  
enddomain = dimsizes(folder)

do x = 0,enddomain-1

	domain = folder(x)
	dir_out = "/lb11/abentley/www/research_images/superstorm93/"+domain+"/forecast/"+name+"/"
;	system("mkdir "+dir_out)

;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,dir_plot+name+"_"+imgcount)
gsn_define_colormap(wks,"alicia")
;**********************************************

res = True

res@gsnFrame = False                                             ;DO NOT PLOT FIRST MAP
res@gsnDraw = False

res@mpDataBaseVersion = "MediumRes"                              ; Country Outlines
res@mpDataSetName = "Earth..4"
res@mpOutlineBoundarySets = "National"
res@mpFillOn = True
res@mpOutlineOn = True

res@cnFillOn = True                                              
res@cnFillMode = "AreaFill"
res@cnRasterSmoothingOn = True
res@cnLevelSelectionMode = "ExplicitLevels"			; Shade 250-hPa jet information
res@cnLinesOn = False                               
res@cnLevelSpacingF = 1                            
res@cnLevels = (/30,40,50,60,70,80,90,100,110/)
res@cnFillColors = (/-1,13,12,11,31,32,33,43,25,24/)

;**********************************************

res@lbAutoManage = False                   ; Label Bar Information
res@pmLabelBarOrthogonalPosF = .02  
res@pmLabelBarHeightF = 0.08
res@pmLabelBarWidthF = 0.73
res@lbLabelAutoStride = True
res@lbLabelFontHeightF = 0.0124
res@lbBoxLinesOn  = True                   
res@lbTopMarginF = .3

;**********************************************

res@tiMainString = " "						; Image label information
res@tiMainJust = "CenterCenter"
res@tiMainPosition = "Center" 
res@tiMainOffsetYF = .02
res@tiXAxisFontHeightF = .015

res@gsnLeftString = "MSLP; 250-hPa jet; 1000~F15~-~F21~500-hPa thickness"
res@gsnLeftStringOrthogonalPosF = .012
res@gsnLeftStringFontHeightF = .008

  curdate = tim + fhr_cur
  curdate@units = "hours since 1800-01-01 00:00:00"

  if (fhr_cur .gt. 0) then
     res@gsnRightString = "("+fhr_cur+" h fcst) "+ut_string(curdate,"")
     res@gsnLeftStringFontColor = "red"
     res@gsnRightStringFontColor = "red"
  else
     res@gsnRightString = "(Analysis) "+ut_string(curdate,"")
     res@gsnLeftStringFontColor = "black"
     res@gsnRightStringFontColor = "black"
  end if

; *********************************************

res@mpGeophysicalLineThicknessF = 2.0		; Map information
res@mpNationalLineThicknessF = 2.0
res@mpUSStateLineThicknessF = 2.0
res@mpOutlineSpecifiers = (/"United States"/)+" : States"

res@mpGeophysicalLineColor = "grey29"
res@mpNationalLineColor = "grey29"
res@mpUSStateLineColor = "grey29"

; *********************************************

res@mpGridAndLimbOn = True					; Grid lines and tick mark information
res@mpGridLineDashPattern = 5
res@mpGridLatSpacingF = 20.
res@mpGridLonSpacingF = 20.
res@mpGridLineThicknessF = 3
res@mpGridLineColor = "grey12"
res@pmTickMarkDisplayMode = "Always"

tmres = True
tmres@tmYLValues = ispan(-80,80,20)
tmres@tmYRValues = ispan(-80,80,20)
tmres@tmXBValues = ispan(-180,179,40)
tmres@tmXBLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013

tmres@tmXBMajorLengthF = .01
tmres@tmXBMinorLengthF = .006

tmres@tmYRMinorValues = (/-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,45,50,55,65/)
tmres@tmYLMinorValues = (/-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,45,50,55,65/)
tmres@tmXBMinorValues = ispan(-180,179,5)

; *************************************************************

if domain .eq. "northamer"						; Domain information
	res@mpProjection = "LambertConformal"
	res@mpLambertParallel2F = 31
	res@mpLambertParallel1F = 11
	res@mpLambertMeridianF = -100
	res@mpLimitMode = "LatLon"
	res@mpMinLatF = 8
	res@mpMaxLatF = 69
	res@mpMinLonF = -151
	res@mpMaxLonF = -49
end if


if domain .eq. "pacific"
	res@mpProjection = "LambertConformal"
  	westlon = 118.
  	eastlon = -118.
  	centerlon = 180. 
	if(westlon.gt.eastlon)then
    	useflip = True
    	westlon = westlon
    	eastlon = eastlon+360.
    	if (centerlon.lt.0)then
      		centerlon = centerlon+360.
    	end if
  	end if
	res@mpLambertParallel2F := 28
	res@mpLambertParallel1F := 7
	res@mpLambertMeridianF := centerlon
	res@mpLimitMode = "LatLon"
	res@mpMinLatF := -15
	res@mpMaxLatF := 71
	res@mpMinLonF := westlon
	res@mpMaxLonF := eastlon
end if

; *************************************************************

mres = True								; MSLP contour information

mres@gsnFrame = False                                        
mres@gsnDraw = False

mres@gsnLeftString = " "
mres@gsnRightString = " "

mres@cnInfoLabelOn = False                    
mres@cnFillOn = False
mres@cnLineLabelsOn = True
mres@cnLinesOn = True
mres@cnLabelMasking = True
mres@cnLineThicknessF = 4                    
mres@cnLevelSelectionMode = "ManualLevels"
mres@cnLevelSpacingF = 4
mres@cnMinLevelValF = 800
mres@cnMaxLevelValF = 1200  
mres@cnLineLabelAngleF = 0.0
mres@cnLineLabelInterval = 2
mres@cnLineLabelDensityF = 1.4
mres@cnLineLabelBackgroundColor = -1
mres@cnLineLabelFontHeightF = 0.008
mres@gsnAddCyclic =  True

; *************************************************************

thres = True								; Red thickness line information

thres@gsnFrame = False                                        
thres@gsnDraw = False

thres@gsnLeftString = " "
thres@gsnRightString = " "
thres@cnInfoLabelOn = False                   
thres@cnFillOn = False
thres@cnLinesOn = True
thres@cnLabelMasking = True
thres@cnLineThicknessF = 4
thres@cnLineColor = "red"
thres@cnLineLabelFontColor = "red"
thres@cnLevelSelectionMode = "ManualLevels"
thres@cnLevelSpacingF = 6
thres@cnMinLevelValF = 546
thres@cnMaxLevelValF = 594 
thres@cnLineLabelAngleF = 0.0
thres@cnLineLabelInterval = 3
thres@cnLineLabelDensityF = .90
thres@cnLineLabelBackgroundColor = -1
thres@cnLineLabelFontHeightF = 0.008
thres@cnLineDashPattern = 5
thres@gsnAddCyclic =  True


; *************************************************************


th2res = True								; Blue thickness line information

th2res@gsnFrame = False                                        
th2res@gsnDraw = False

th2res@gsnLeftString = " "
th2res@gsnRightString = " "
th2res@cnInfoLabelOn = False                    
th2res@cnFillOn = False
th2res@cnLinesOn = True
th2res@cnLabelMasking = True
th2res@cnLineThicknessF = 4
th2res@cnLineColor = "blue"
th2res@cnLineLabelFontColor = "blue"
th2res@cnLevelSelectionMode = "ManualLevels"
th2res@cnLevelSpacingF = 6
th2res@cnMinLevelValF = 444
th2res@cnMaxLevelValF = 540 
th2res@cnLineLabelAngleF = 0.0
th2res@cnLineLabelInterval = 3
th2res@cnLineLabelDensityF = .90
th2res@cnLineLabelBackgroundColor = -1
th2res@cnLineLabelFontHeightF = 0.008
th2res@cnLineDashPattern = 5
th2res@gsnAddCyclic =  True


; *************************************************************
res@mpFillDrawOrder = "PreDraw"				; Draw order information
res@cnFillDrawOrder = "PreDraw"
mres@cnLineDrawOrder ="Draw"
thres@cnLineDrawOrder ="Draw"
th2res@cnLineDrawOrder ="Draw" 
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, jet, res)          	; Plot filled 250-hPa jet map
contours = gsn_csm_contour(wks, mslp, mres)			; Plot mslp contours
other = gsn_csm_contour(wks, thick, thres)			; Plot red thickness contours
other2 = gsn_csm_contour(wks, thick, th2res)		; Plot blue thickness contours
plot = add_map_tickmarks(wks,plot,tmres)			; Plot tickmarks

;********************************************

overlay(plot,other)					; Overlay information
overlay(plot,other2)
overlay(plot,contours)

;********************************************

draw(plot)			; Create final plot
frame(wks)	

;********************************************

system("convert "+dir_plot+name+"_"+imgcount+".png -trim +repage "+dir_out+name+"_"+imgcount+".gif")
system ("'rm' "+dir_plot+name+"_*.png") 

print("Image = "+imgcount+" created in: "+dir_out)

	if (x .eq. enddomain-1) then
	    imgcount = imgcount + 1
	end if

	if (tim .eq. fdate) then
		spot = spot + 1
	end if

	; remove the grb2 file to save space
	if(tim .le. edate) then
	    system("rm -f "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar") ; now remove the tar file (only have to do this once)
	end if

end do
	
end if ; tim .ne. fdate








;**********************************************************************************************************
; Obtaining analysis and forecast hours from specified forecast run of GFS
;**********************************************************************************************************    

if (tim .eq. fdate) then    

print("Plotting from forecast grib files")
fhr  := (/0,6,12,18,24,30,36,42,48,54,60,66,72,78,84,90,96,102,108,114,120,126,132,138,144,150,156,162,168,174,180,186,192/)
nfhr := dimsizes(fhr)

do f = 0,nfhr-1
    if (fhr(f).lt.10) then
        filefhr = "00"+fhr(f)
    else if ((fhr(f).lt.100).and.(fhr(f).gt.10)) then
        filefhr = "0"+fhr(f)
    else if (fhr(f).gt.100) then
        filefhr = fhr(f)
    end if 
    end if
    end if
                 
    filename = "/nfs/cas2/unidata/GRIB/gfs0p5deg/GFS_"+str_time+"_"+str_hr+"_"+filefhr+".grb2"
    fhr_cur = fhr(f)
    print("fhr_cur: "+fhr_cur)
  
;**********************************************************************************************************
; Download data from GFS files
;**********************************************************************************************************

  print("filename: "+filename)
  a = addfile(filename,"r")

  levs = (/100000,50000/) ; Needs to be in Pa
;  levs_wind  = (/20000,25000,30000/)
  levs_wind  = (/25000/)

  mslp = a->PRMSL_P0_L101_GLL0(::-1,:)
  mslp = mslp * .01

  g = a->HGT_P0_L100_GLL0({levs},::-1,:)
  thick = g(0,:,:)
  thick = g({min(levs)},:,:)-g({max(levs)},:,:)
  thick = thick * .1

	do d=0,1
		thick=smth9(thick,.5,.25,True)
	end do

  u_all = a->UGRD_P0_L100_GLL0({levs_wind},::-1,:)
  v_all = a->VGRD_P0_L100_GLL0({levs_wind},::-1,:)

  if(dimsizes(levs_wind).eq.1) then
    u = u_all
    v = v_all
  else
    u = dim_avg_n_Wrap(u_all,0)
    v = dim_avg_n_Wrap(v_all,0)
  end if

  jet = u
  jet = ((u^2)+(v^2))^0.5

;  print("Successfully got data from files!")

;--------------------------------------------------------------
; Specify domain(s) to plot and loop through at each time step
;--------------------------------------------------------------
  
folder = (/"northamer","pacific"/)  
enddomain = dimsizes(folder)

do x = 0,enddomain-1

	domain = folder(x)
	dir_out = "/lb11/abentley/www/research_images/superstorm93/"+domain+"/forecast/"+name+"/"
;	system("mkdir "+dir_out)

;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,dir_plot+name+"_"+imgcount)
gsn_define_colormap(wks,"alicia")
;**********************************************

res = True

res@gsnFrame = False                                             ;DO NOT PLOT FIRST MAP
res@gsnDraw = False

res@mpDataBaseVersion = "MediumRes"                              ; Country Outlines
res@mpDataSetName = "Earth..4"
res@mpOutlineBoundarySets = "National"
res@mpFillOn = True
res@mpOutlineOn = True

res@cnFillOn = True                                              
res@cnFillMode = "AreaFill"
res@cnRasterSmoothingOn = True
res@cnLevelSelectionMode = "ExplicitLevels"			; Shade 250-hPa jet information
res@cnLinesOn = False                               
res@cnLevelSpacingF = 1                            
res@cnLevels = (/30,40,50,60,70,80,90,100,110/)
res@cnFillColors = (/-1,13,12,11,31,32,33,43,25,24/)

;**********************************************

res@lbAutoManage = False                   ; Label Bar Information
res@pmLabelBarOrthogonalPosF = .02  
res@pmLabelBarHeightF = 0.08
res@pmLabelBarWidthF = 0.73
res@lbLabelAutoStride = True
res@lbLabelFontHeightF = 0.0124
res@lbBoxLinesOn  = True                   
res@lbTopMarginF = .3

;**********************************************

res@tiMainString = " "						; Image label information
res@tiMainJust = "CenterCenter"
res@tiMainPosition = "Center" 
res@tiMainOffsetYF = .02
res@tiXAxisFontHeightF = .015

res@gsnLeftString = "MSLP; 250-hPa jet; 1000~F15~-~F21~500-hPa thickness"
res@gsnLeftStringOrthogonalPosF = .012
res@gsnLeftStringFontHeightF = .008

  curdate = tim + fhr_cur
  curdate@units = "hours since 1800-01-01 00:00:00"

  if (fhr_cur .gt. 0) then
     res@gsnRightString = "("+fhr_cur+" h fcst) "+ut_string(curdate,"")
     res@gsnLeftStringFontColor = "red"
     res@gsnRightStringFontColor = "red"
  else
     res@gsnRightString = "(Analysis) "+ut_string(curdate,"")
     res@gsnLeftStringFontColor = "black"
     res@gsnRightStringFontColor = "black"
  end if

; *********************************************

res@mpGeophysicalLineThicknessF = 2.0		; Map information
res@mpNationalLineThicknessF = 2.0
res@mpUSStateLineThicknessF = 2.0
res@mpOutlineSpecifiers = (/"United States"/)+" : States"

res@mpGeophysicalLineColor = "grey29"
res@mpNationalLineColor = "grey29"
res@mpUSStateLineColor = "grey29"

; *********************************************

res@mpGridAndLimbOn = True					; Grid lines and tick mark information
res@mpGridLineDashPattern = 5
res@mpGridLatSpacingF = 20.
res@mpGridLonSpacingF = 20.
res@mpGridLineThicknessF = 3
res@mpGridLineColor = "grey12"
res@pmTickMarkDisplayMode = "Always"

tmres = True
tmres@tmYLValues = ispan(-80,80,20)
tmres@tmYRValues = ispan(-80,80,20)
tmres@tmXBValues = ispan(-180,179,40)
tmres@tmXBLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013

tmres@tmXBMajorLengthF = .01
tmres@tmXBMinorLengthF = .006

tmres@tmYRMinorValues = (/-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,45,50,55,65/)
tmres@tmYLMinorValues = (/-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,45,50,55,65/)
tmres@tmXBMinorValues = ispan(-180,179,5)

; *************************************************************

if domain .eq. "northamer"						; Domain information
	res@mpProjection = "LambertConformal"
	res@mpLambertParallel2F = 31
	res@mpLambertParallel1F = 11
	res@mpLambertMeridianF = -100
	res@mpLimitMode = "LatLon"
	res@mpMinLatF = 8
	res@mpMaxLatF = 69
	res@mpMinLonF = -151
	res@mpMaxLonF = -49
end if


if domain .eq. "pacific"
	res@mpProjection = "LambertConformal"
  	westlon = 118.
  	eastlon = -118.
  	centerlon = 180. 
	if(westlon.gt.eastlon)then
    	useflip = True
    	westlon = westlon
    	eastlon = eastlon+360.
    	if (centerlon.lt.0)then
      		centerlon = centerlon+360.
    	end if
  	end if
	res@mpLambertParallel2F := 28
	res@mpLambertParallel1F := 7
	res@mpLambertMeridianF := centerlon
	res@mpLimitMode = "LatLon"
	res@mpMinLatF := -15
	res@mpMaxLatF := 71
	res@mpMinLonF := westlon
	res@mpMaxLonF := eastlon
end if

; *************************************************************

mres = True								; MSLP contour information

mres@gsnFrame = False                                        
mres@gsnDraw = False

mres@gsnLeftString = " "
mres@gsnRightString = " "

mres@cnInfoLabelOn = False                    
mres@cnFillOn = False
mres@cnLineLabelsOn = True
mres@cnLinesOn = True
mres@cnLabelMasking = True
mres@cnLineThicknessF = 4                    
mres@cnLevelSelectionMode = "ManualLevels"
mres@cnLevelSpacingF = 4
mres@cnMinLevelValF = 800
mres@cnMaxLevelValF = 1200  
mres@cnLineLabelAngleF = 0.0
mres@cnLineLabelInterval = 2
mres@cnLineLabelDensityF = 1.4
mres@cnLineLabelBackgroundColor = -1
mres@cnLineLabelFontHeightF = 0.008
mres@gsnAddCyclic =  True

; *************************************************************

thres = True								; Red thickness line information

thres@gsnFrame = False                                        
thres@gsnDraw = False

thres@gsnLeftString = " "
thres@gsnRightString = " "
thres@cnInfoLabelOn = False                   
thres@cnFillOn = False
thres@cnLinesOn = True
thres@cnLabelMasking = True
thres@cnLineThicknessF = 4
thres@cnLineColor = "red"
thres@cnLineLabelFontColor = "red"
thres@cnLevelSelectionMode = "ManualLevels"
thres@cnLevelSpacingF = 6
thres@cnMinLevelValF = 546
thres@cnMaxLevelValF = 594 
thres@cnLineLabelAngleF = 0.0
thres@cnLineLabelInterval = 3
thres@cnLineLabelDensityF = .90
thres@cnLineLabelBackgroundColor = -1
thres@cnLineLabelFontHeightF = 0.008
thres@cnLineDashPattern = 5
thres@gsnAddCyclic =  True


; *************************************************************


th2res = True								; Blue thickness line information

th2res@gsnFrame = False                                        
th2res@gsnDraw = False

th2res@gsnLeftString = " "
th2res@gsnRightString = " "
th2res@cnInfoLabelOn = False                    
th2res@cnFillOn = False
th2res@cnLinesOn = True
th2res@cnLabelMasking = True
th2res@cnLineThicknessF = 4
th2res@cnLineColor = "blue"
th2res@cnLineLabelFontColor = "blue"
th2res@cnLevelSelectionMode = "ManualLevels"
th2res@cnLevelSpacingF = 6
th2res@cnMinLevelValF = 444
th2res@cnMaxLevelValF = 540 
th2res@cnLineLabelAngleF = 0.0
th2res@cnLineLabelInterval = 3
th2res@cnLineLabelDensityF = .90
th2res@cnLineLabelBackgroundColor = -1
th2res@cnLineLabelFontHeightF = 0.008
th2res@cnLineDashPattern = 5
th2res@gsnAddCyclic =  True


; *************************************************************
res@mpFillDrawOrder = "PreDraw"				; Draw order information
res@cnFillDrawOrder = "PreDraw"
mres@cnLineDrawOrder ="Draw"
thres@cnLineDrawOrder ="Draw"
th2res@cnLineDrawOrder ="Draw" 
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, jet, res)          	; Plot filled 250-hPa jet map
contours = gsn_csm_contour(wks, mslp, mres)			; Plot mslp contours
other = gsn_csm_contour(wks, thick, thres)			; Plot red thickness contours
other2 = gsn_csm_contour(wks, thick, th2res)		; Plot blue thickness contours
plot = add_map_tickmarks(wks,plot,tmres)			; Plot tickmarks

;********************************************

overlay(plot,other)					; Overlay information
overlay(plot,other2)
overlay(plot,contours)

;********************************************

draw(plot)			; Create final plot
frame(wks)	

;********************************************

system("convert "+dir_plot+name+"_"+imgcount+".png -trim +repage "+dir_out+name+"_"+imgcount+".gif")
system ("'rm' "+dir_plot+name+"_*.png") 

print("Image = "+imgcount+" created in: "+dir_out)

	if (x .eq. enddomain-1) then
	    imgcount = imgcount + 1
	end if

	if (tim .eq. fdate) then
		spot = spot + 1
	end if

	; remove the grb2 file to save space
	if(tim .le. edate) then
	    system("rm -f "+dir_grib+"gfs255_anl_"+str_time+".grb2.tar") ; now remove the tar file (only have to do this once)
	end if
	
end do
print(" ")
end do

end if ; tim .eq. fdate

end do
	
system("rm -f "+dir_grib+"*.grb2.tar")

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end