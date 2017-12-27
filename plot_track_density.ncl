; ===========================================
; Plots EC track density from dummy track data
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
dist = "350"
name = "track_density_"+dist+"km"

dir_in = "/path/to/track/density/file/"
dir_out_web = "/path/to/location/of/track/density/map/"

fil = addfile(dir_in+"track_density_"+dist+"km.nc","r")
count2 = fil->count(:,:)

count = todouble(count2 - 0)

do d=0,2
 count = smth9(count,.5,.25,False)
end do

copy_VarCoords(count2,count)

;==============================================
; Create Shaded Map
;==============================================
wks_type = "png"

wks_type@wkWidth = 2500
wks_type@wkHeight = 2500

wks = gsn_open_wks(wks_type,name)
gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")
;**********************************************
colors = (/-1,18,31,45,58,72,97,122,132,147,159,175,200,235,1/)

res = True

res@gsnFrame = False                            ; DO NOT PLOT FIRST MAP
res@gsnDraw = False

res@tiMainString = " "    						; Image labels
res@tiMainJust = "CenterCenter"
res@tiMainPosition = "Center" 
res@tiMainOffsetYF = -0.03
res@tiXAxisFontHeightF = .015
res@gsnStringFontHeightF = .013

res@gsnLeftString = "Track Density of ECs leading to EWEs within "+dist+" km (October-March 1992-2016)"
res@gsnLeftStringOrthogonalPosF = .0075 
res@gsnLeftStringFontHeightF = .008
res@gsnRightString = "1) First 48+ h inside box, 2) 925-hPa wind speed >=1-sigma for 36+ h"
res@gsnRightStringOrthogonalPosF = .0075
res@gsnRightStringFontHeightF = .008

;---------------------------------------------------------

res@mpFillOn = True								; Map Information
res@mpLandFillColor = "gray75"  
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

res@mpGridAndLimbOn        = True
res@mpGridLineDashPattern  = 5                  
res@mpGridLatSpacingF      = 20
res@mpGridLonSpacingF      = 20
res@mpGridLineColor = "grey25"
res@mpGridLineThicknessF = 3

res@mpProjection = "CylindricalEquidistant"    ; Domain information
res@mpMinLatF = 15
res@mpMaxLatF = 90
res@mpMinLonF = -130
res@mpMaxLonF = 40

;-----------------------------------------------------------

res@cnFillOn = True   							; Track density shading information
res@cnFillMode = "AreaFill"
res@cnRasterSmoothingOn = True
res@cnLevelSelectionMode = "ExplicitLevels"
res@cnLinesOn = False                               
res@cnLevelSpacingF = 5
res@cnMinLevelValF = 0
res@cnMaxLevelValF = 70 
res@cnLevels = (/1,3,5,7,9,11,13,15,17,19,22,25,28/)
res@cnFillColors = colors
res@gsnSpreadColors      = False

res@lbAutoManage = False                   		; Label Bar Information
res@pmLabelBarOrthogonalPosF = .02  
res@pmLabelBarHeightF = 0.08
res@pmLabelBarWidthF = 0.69
res@lbLabelAutoStride = True
res@lbLabelFontHeightF = .011
res@lbBoxLinesOn  = True                   
res@lbTopMarginF = .3
res@cnInfoLabelOn = False 
res@lbLabelStride = 1 

;------------------------------------------------------

res@tmXBOn = True								; Tick mark information
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

;********************************************
res@cnFillDrawOrder = "PreDraw"
res@mpFillDrawOrder = "PreDraw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, count, res) 

;********************************************
boxres = True
boxres@txFontHeightF = 0.018				; Outline the polygon in which ECs leading to EWEs need to occur
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

