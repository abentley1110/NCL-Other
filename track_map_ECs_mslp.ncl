; ===========================================
; Plots tracks of ECs from dummy CFSR data
; Could easily be used to plot tracks of TCs
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
load "~/ncl/lib/addbox.ncl"
;************************************************************************

begin

print(" ")
print("**************")
print(" START SCRIPT ")
print("**************")
print(" ")

; ********************************************************
; Specify center lat/lon to use in composite and variable
; ********************************************************
name = "tracks_EWEs_OctMarch_1992_2016"

dir_in = "/lb13/abentley/scripts/github/other/"
dir_out_web = "/lb11/abentley/www/research_images/superstorm93/"
system("mkdir "+dir_out_web)

storms = 1672
endvar = storms-1 

fileread = asciiread(dir_in+"dummy_EC_track_data.csv",(/storms,9/),"float")

;---------------------------------------

outlines := new((/storms/),"string")

yyyy_arr := new(storms,double,0)
mm_arr := new(storms,double,0)
dd_arr := new(storms,double,0)
hh_arr := new(storms,double,0)
rlat_arr := new(storms,float,0)
rlon_arr := new(storms,float,0)
pres_arr := new(storms,double,0)
anom_arr := new(storms,double,0)
cyc_arr := new(storms,double,0)

; ************************************************
; Obtain data from .csv track file
; ************************************************

do timestep = 0,endvar

number = timestep + 1

print("Plotting line: "+number+" of "+storms)

yyyy = flt2dble(fileread(timestep,0))
mm = flt2dble(fileread(timestep,1))
dd = flt2dble(fileread(timestep,2))
hh = flt2dble(fileread(timestep,3))
pres = decimalPlaces(flt2dble(fileread(timestep,4)),2,True)
rlat = fileread(timestep,5)
rlon = fileread(timestep,6)
anom = decimalPlaces(flt2dble(fileread(timestep,7)),2,True)
cyc = flt2dble(fileread(timestep,8))

yyyy_arr(timestep) = yyyy
mm_arr(timestep) = mm
dd_arr(timestep) = dd
hh_arr(timestep) = hh
pres_arr(timestep) = pres
rlat_arr(timestep) = rlat
anom_arr(timestep) = anom
cyc_arr(timestep) = cyc

if rlon .lt. 359.5 then
	rlon_arr(timestep) = rlon
else if (rlon .ge. 359.5) .and. (rlon .lt. 360.0) then
	print("rlon: "+rlon)
	rlon = 0.0
	print("rlon: "+rlon)
	rlon_arr(timestep) = rlon
else if (rlon .ge. 360.0) then
	print("rlon: "+rlon)
	rlon = rlon - 360.0
	print("rlon: "+rlon)
	rlon_arr(timestep) = rlon
end if
end if
end if

end do    ; end timestep

print(" ")
print("Lat/Lons successfully collected from file")

;----------------------------------------------

fil = addfile("/cfsr/data/1979/pmsl.1979.0p5.anl.nc","r")    ; Dummy MSLP data
pmsl = fil->pmsl(1,:,:)
pmsl = pmsl/100       ; convert from Pa/s to hPa/s




;==============================================
; Create TRACK MAP of ECs leading to EWEs
;==============================================
wks_type = "png"

wks_type@wkWidth = 2500
wks_type@wkHeight = 2500

wks = gsn_open_wks(wks_type,name)
gsn_define_colormap(wks,"GMT_hot")
;**********************************************

colors = (/97,96,95,94,93,92,91,90,89,88,87,79,78,77,76,75,74,73,72,71,70,67,66,65,64,63,62,61,60,59,58,51,50,49,48,47,46,45,44,43,42,33,32,31,30,29,28,27,26,25,24,21,20,19,18,17,16,15,14,13,12,11/)

res = True

res@gsnFrame = False                                            ; DO NOT PLOT FIRST MAP
res@gsnDraw = False

res@tiMainString = " "    ; Specify Title						; Image labels
res@tiMainJust = "CenterCenter"
res@tiMainPosition = "Center" 
res@tiMainOffsetYF = -0.03
res@tiXAxisFontHeightF = .015
res@gsnStringFontHeightF = .013

res@gsnLeftString = "ECs leading to EWEs (October-March 1992-2016)"
res@gsnLeftStringOrthogonalPosF = .0075 
res@gsnLeftStringFontHeightF = .008
res@gsnRightString = "1) First 48+ h inside box, 2) 925-hPa wind speed >=1-sigma for 36+ h"
res@gsnRightStringOrthogonalPosF = .0075
res@gsnRightStringFontHeightF = .008

;------------------------------------------

res@mpFillOn = True									; Map Information
res@mpLandFillColor = "gray75"  ;"grey75"
res@mpInlandWaterFillColor = "white"
res@mpOceanFillColor = "white"
res@mpDataBaseVersion = "MediumRes"                              
res@mpDataSetName = "Earth..4"
res@mpOutlineBoundarySets = "National"
res@mpOutlineSpecifiers = (/"United States"/)+" : States"
res@mpFillOn = True
res@mpOutlineOn = True
res@mpGeophysicalLineColor = "grey32"
res@mpNationalLineColor = "grey32"
res@mpUSStateLineColor = "grey32"
res@mpGeophysicalLineThicknessF = 3
res@mpNationalLineThicknessF = 3
res@mpUSStateLineThicknessF = 3

res@mpGridAndLimbOn        = True					; Grid lines information
res@mpGridLineDashPattern  = 5                  
res@mpGridLatSpacingF      = 20
res@mpGridLonSpacingF      = 20
res@mpGridLineColor = "grey25"
res@mpGridLineThicknessF = 3

res@mpProjection = "CylindricalEquidistant"			; Domain information
res@mpMinLatF = 15
res@mpMaxLatF = 90
res@mpMinLonF = -130
res@mpMaxLonF = 40

res@tmXBOn = True									; Tick mark information
res@tmXBLabelsOn = True
res@tmXBMode = "Explicit" 
res@tmXBValues = ispan(-120,40,20)
res@tmXBLabels = (/"120~F34~0~F~W","100~F34~0~F~W","80~F34~0~F~W","60~F34~0~F~W","40~F34~0~F~W","20~F34~0~F~W","0~F34~0","20~F34~0~F~E","40~F34~0~F~E"/)
res@tmXBLabelFontHeightF = .011
res@tmXBMajorLengthF = .01

res@tmYLOn = True
res@tmYLLabelsOn = True
res@tmYLMode = "Explicit" 
res@tmYLValues = ispan(20,80,20)
res@tmYLLabels = (/"20~F34~0~F~N","40~F34~0~F~N","60~F34~0~F~N","80~F34~0~F~N"/)
res@tmYLLabelFontHeightF = .011

res@tmYROn = False
res@tmXTOn = False

;------------------------------------------

res@cnFillOn = True   					; Dummy MSLP data information
res@cnFillMode = "AreaFill"
res@cnRasterSmoothingOn = True
res@cnLevelSelectionMode = "ManualLevels"
res@cnLinesOn = False                              
res@cnLevelSpacingF = 1
res@cnMinLevelValF = 940
res@cnMaxLevelValF = 1000  
res@cnFillColors = colors

;-------------------------------------------

res@lbAutoManage = False                ; Label Bar Information
res@pmLabelBarOrthogonalPosF = .02  
res@pmLabelBarHeightF = 0.08
res@pmLabelBarWidthF = 0.69
res@lbLabelAutoStride = True
res@lbLabelFontHeightF = .011
res@lbBoxLinesOn  = True                    
res@lbTopMarginF = .3
res@cnInfoLabelOn = False 
res@lbLabelStride = 5 


;********************************************

res@cnFillDrawOrder = "PreDraw"			; Draw order
res@mpFillDrawOrder = "Draw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, pmsl, res) 		; Dummy MSLP map

;************************************************************************
; Plot EC tracks, shaded according to MSLP
;************************************************************************

tkres = True
tkres@gsLineColor = "black"
tkres@gsLineThicknessF = 8

length = doubletoint(cyc_arr(endvar))
line = new(storms,graphic)
l_lat = new(storms,double,0)
l_lon = new(storms,double,0)
previous_cyc = todouble(-1)

start_position = 0
count = 0
good_cyclones = 0
cyc_num = 1
array2check = ispan(940,1000,1)

;***********************************************************

startpoint = 0
goodbox = 0
toolong = 0

do i = 1,endvar-1
  previous2_cyc = todouble(-2)
  previous_cyc = cyc_arr(i-1)
  current_cyc = cyc_arr(i)
  next_cyc = cyc_arr(i+1)
  l_lat(i-1) = rlat_arr(i-1)
  l_lon(i-1) = rlon_arr(i-1)
  l_lat(i) = rlat_arr(i)
  l_lon(i) = rlon_arr(i)
  
	if (current_cyc .ne. previous_cyc) then
		print(" ")
   		print("******Starting cyclone "+previous_cyc+"******")
   		cyc_num = cyc_num + 1
   		endpoint = i-1
   		
   		print("startpoint: "+startpoint)
   		print("endpoint: "+endpoint) 

  		do h = startpoint,endpoint-1
  	  		count = count + 1
  			print("Line Drawn: "+count)
  			l_lat_plot := (/l_lat(h),l_lat(h+1)/)
    		l_lon_plot := (/l_lon(h),l_lon(h+1)/)
    	
    		value2check := pres_arr(h)
    		index = closest_val(value2check,array2check)
    		tkres@gsLineColor = colors(index)
			line(count-1) = gsn_add_polyline(wks,plot,l_lon_plot,l_lat_plot,tkres)
			
		end do ; end h
		
		startpoint = i
	end if
	
	previous_cyc = cyc_arr(i)
	previous2_cyc = cyc_arr(i-1)
end do  ; end plot tracks 

;********************************************
boxres = True										; Draw the polygon within which ECs must pass
boxres@txFontHeightF = 0.018
boxres@txJust = "CenterLeft"
boxres@gsLineThicknessF = 25
boxres@gsLineColor = "black"

box1 = gsn_add_polyline(wks,plot,(/-100,-125/),(/20,60/),boxres)
box2 = gsn_add_polyline(wks,plot,(/-125,-40/),(/60,60/),boxres)
box3 = gsn_add_polyline(wks,plot,(/-40,-40/),(/50,60/),boxres)
box40 = gsn_add_polyline(wks,plot,(/-40,-44.44446/),(/50,46.66667/),boxres)
box41 = gsn_add_polyline(wks,plot,(/-44.44446,-48.88889/),(/46.66667,43.33333/),boxres)
box42 = gsn_add_polyline(wks,plot,(/-48.88889,-53.33334/),(/43.33333,40/),boxres)
box43 = gsn_add_polyline(wks,plot,(/-53.33334,-57.77777/),(/40,36.66667/),boxres)
box44 = gsn_add_polyline(wks,plot,(/-57.77777,-62.22223/),(/36.66667,33.33333/),boxres)
box45 = gsn_add_polyline(wks,plot,(/-62.22223,-66.66666/),(/33.33333,30/),boxres)
box46 = gsn_add_polyline(wks,plot,(/-66.66666,-71.11111/),(/30,26.66667/),boxres)
box47 = gsn_add_polyline(wks,plot,(/-71.11111,-75.55554/),(/26.66667,23.33333/),boxres)
box48 = gsn_add_polyline(wks,plot,(/-75.55554,-80/),(/23.33333,20/),boxres)
box5 = gsn_add_polyline(wks,plot,(/-100,-80/),(/20,20/),boxres)

;********************************************

draw(plot)
frame(wks)

;********************************************

system("convert -trim "+name+".png "+name+".png")
system ("mv "+name+".png "+dir_out_web+name+".png")

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end

