; ===========================================
; Plots composited 600-400-hPa geo. height data
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
load "~/ncl/lib/latlon.ncl"
; ===========================================

begin

print(" ")
print("**************")
print(" START SCRIPT ")
print("**************")
print(" ")

;---------------------------------------------

name = "composite_geo_height"				; Name of final image

folder = (/"eastcoast"/)
endcluster = dimsizes(folder)

do x = 0,endcluster-1
cluster = folder(x)

print("Plotting: "+cluster)

dir_in = "/lb13/abentley/scripts/github/other/compgrids/"+cluster+"/"
dir_out = "/lb11/abentley/www/research_images/superstorm93/"

; ********************************
; Load composited files
; ********************************
g_file = addfile(dir_in+"comp_g.nc","r")
g = g_file->g(:,:)
g = g/10.

do d=0,1
	g=smth9(g,.5,.25,True)
end do

if cluster .eq. "eastcoast"
   howmany = 13
end if

;==============================================
; Create Shaded Map
;==============================================

wks_type = "png"

wks_type@wkWidth = 1600
wks_type@wkHeight = 1600

wks = gsn_open_wks(wks_type,name)
gsn_define_colormap(wks,"BkBlAqGrYeOrReViWh200")
;**********************************************

res = True

res@gsnFrame = False                                             ;DO NOT PLOT FIRST MAP
res@gsnDraw = False

res@mpDataBaseVersion = "MediumRes"                              ; Country Outlines
res@mpDataSetName = "Earth..4"
res@mpOutlineBoundarySets = "National"

res@cnFillOn = True                                              
res@cnFillMode = "AreaFill"
res@cnRasterSmoothingOn = True
res@cnLevelSelectionMode = "ManualLevels"
res@cnLinesOn = False                               ; Shaded geo. height information
res@cnLevelSpacingF = 5
res@cnMinLevelValF = 510
res@cnMaxLevelValF = 590
;res@cnFillColors = (/0,21,32,36,42,47,58,66,74,90,110,120,130,138,154,162,170,186,192,196,199/)
res@cnFillColors = (/0,21,31,35,42,47,55,62,71,80,90,110,120,130,138,154,162,170,186,192,196,199/)
res@cnSmoothingOn = True
res@cnSmoothingDistanceF = 0.001

;--------------------------------------------------

res@lbAutoManage = False                   	; Label Bar Information
res@pmLabelBarOrthogonalPosF = .02  
res@pmLabelBarHeightF = 0.08
res@pmLabelBarWidthF = 0.73
res@lbLabelAutoStride = True
res@lbLabelFontHeightF = 0.0124
res@lbBoxLinesOn  = True                   
res@lbTopMarginF = .3

;--------------------------------------------------

res@tiMainString = " "						; Create image labels
res@tiMainJust = "CenterCenter"
res@tiMainPosition = "Center" 
res@tiMainOffsetYF = .02
res@tiXAxisFontHeightF = .015

res@gsnLeftString = "Composite of 600~F15~-~F21~400-hPa geopotential height"
res@gsnLeftStringOrthogonalPosF = .012
res@gsnLeftStringFontHeightF = .008
res@gsnRightString = "(CFSR Analyses)"
res@gsnRightStringOrthogonalPosF = .0075
res@gsnRightStringFontHeightF = .013

;--------------------------------------------------

if cluster .eq. "eastcoast" then					; Domain information
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

;--------------------------------------------------

res@mpGeophysicalLineThicknessF = 2.0		; Map Information
res@mpNationalLineThicknessF = 2.0
res@mpUSStateLineThicknessF = 2.0
res@mpOutlineSpecifiers = (/"Canada : Provinces","United States : States"/) 

res@mpGridAndLimbOn = True
res@mpGridLineDashPattern = 5
res@mpGridLatSpacingF = 20.
res@mpGridLonSpacingF = 20.
res@mpGridLineThicknessF = 3
res@mpGridLineColor = "grey29"

res@mpGeophysicalLineColor = "grey29"
res@mpNationalLineColor = "grey29"
res@mpUSStateLineColor = "grey29"

;--------------------------------------------------

res@pmTickMarkDisplayMode = "Always"				; Tick mark information

tmres = True
tmres@tmXBValues := ispan(-180,179,40)
tmres@tmYLValues := ispan(0,80,20)
tmres@tmYRValues := ispan(0,80,20)
tmres@tmXBLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013
tmres@tmYLLabelFontHeightF = .013

tmres@tmXBMajorLengthF = .01
tmres@tmXBMinorLengthF = .006

tmres@tmYRMinorValues = (/-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,45,50,55,65/)
tmres@tmYLMinorValues = (/-75,-70,-65,-55,-50,-45,-35,-30,-25,-15,-10,-5,5,10,15,25,30,35,45,50,55,65/)
;tmres@tmXBMinorValues = (/-175,-170,-165,-160,-155,-150,-145,-135,-130,-125,-120,-115,-110,-105,-95,-90,-85,-80,-75,-70,-65,-55,-50,-45,-40,-35,-30,-25,-15,-10,-5,0,5,10,15,25,30,35,40,45,50,55,60,65,70,75,80,85,90,95,100,105,110,115,120,125,130,135,145,150,155,160,165,170,175/)
tmres@tmXBMinorValues = ispan(-180,179,5)

; *************************************************************
res@mpFillOn = True
res@mpOutlineOn = True
res@mpFillDrawOrder = "PreDraw"
res@cnFillDrawOrder = "PreDraw"
res@mpOutlineDrawOrder = "Draw"
res@mpGridAndLimbDrawOrder = "PostDraw"

plot = gsn_csm_contour_map(wks, g, res)          	; Plot filled contour map
;contours = gsn_csm_contour(wks, pmsl, cnres)		; Plot MSLP contours
plot = add_map_tickmarks(wks,plot,tmres)			; Plot tick marks

;********************************************

;overlay(plot,contours)

;********************************************

draw(plot)
frame(wks)

;********************************************

system("convert -trim "+name+".png "+name+".png")
system ("mv "+name+".png "+dir_out+name+".png")

print("Created in: "+dir_out)  

end do     ; end cluster

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end