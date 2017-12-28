; ===========================================
; Shifts 600-400-hPa geo. height data prior to compositing
; Last updated: 27 December 2017
; Created by: Alicia M. Bentley
; Email: abentley1110@gmail.com
; ===========================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"
;************************************************************************

begin

print(" ")
print("**************")
print(" START SCRIPT ")
print("**************")

cluster = (/"eastcoast"/) 			; Specify which subset of grids you're shifting
endcluster = dimsizes(cluster)

do x = 0,endcluster-1

folder = cluster(x)

if (x .gt. 0) then 
  delete(variable)
  delete(time)
end if

; ********************************************************
; Specify the variable you're going to shift 
; ********************************************************

layer = (/"g"/)    				
endvar = dimsizes(layer)

do v = 0,endvar-1

if v .gt.0 
  delete(variable)
  delete(time)
end if

variable = layer(v)

; ********************************************************
; Specify center lat/lon to use in composite 
; ********************************************************

storms = 13
time_start = 0
time_end = storms-1
fileread := asciiread("/lb13/abentley/scripts/github/other/dummy_EC_tmax_positions.csv",(/storms,12/),"float")
c_lat = 43.1
c_lon = -62.9

clat = round(2*c_lat,0)/2
clon = round(2*c_lon,0)/2

print(" ")
print("Center Lat/Lon: "+clat+","+clon)

; ************************************************
; Loop through data and shift grids
; ************************************************

do timestep = time_start,time_end

print(" ")
print("Starting line "+timestep+" of "+time_end+" ("+variable+")")

syyyy = floattoint(fileread(timestep,0))    ; r = real date
smm = floattoint(fileread(timestep,1))          
sdd = floattoint(fileread(timestep,2))
shh = floattoint(fileread(timestep,3))

rlat = round(2*fileread(timestep,5),0)/2
rlon = round(2*fileread(timestep,6),0)/2

print("Lat: "+rlat+" Lon: "+rlon)

; *******************************************************************
; Make new file for writing new shifted array
; Compositing function in comp.ncl will read across 
; these multiple files (pv_isen_1_shift.nc, pv_isen_2_shift.nc, etc).
; *******************************************************************

case = timestep + 1

number = 0

dir_out = "/lb13/abentley/scripts/github/other/shiftgrids/"+folder+"/"
system ("mkdir /lb13/abentley/scripts/github/other/shiftgrids/")
system ("mkdir /lb13/abentley/scripts/github/other/shiftgrids/"+folder+"/")

system ("'rm' "+dir_out+variable+"_shift_"+case+".nc")
ncdf = addfile(dir_out+variable+"_shift_"+case+".nc" , "c")     

; Specify file from which to extract data
FILE = "/cfsr/data/"+syyyy+"/"+variable+"."+syyyy+".0p5.anl.nc"
f = addfile(FILE,"r")

; Load time in order to recognize "time@units" next
time := f->time

; Set the real date
sdate = cd_inv_calendar(syyyy,smm,sdd,shh,00,00,time@units,0)
print("Date:  "+ut_string(sdate,""))

; Extract variable array and coordinates (lev x lat x lon) from grib2 file
var_temp = f->$variable$({sdate},{600:400},:,:)
var = dim_avg_n_Wrap(var_temp,0)
lat = f->lat
lon = f->lon

;************************************************
; Interpolate to new shifted grid
;***********************************************

; Determine how much to shift the grids latitudinally (del_lat) and longitudinally (del_lon) based on the feature position 
; (in this case, rlat, rlon) minus the composite feature position (in this case, clat, clon).  If geographical 
; reference doesn't matter, it might make sense to have the composite feature lat/lon be 0,0)

del_lat = rlat-clat
del_lon = rlon-clon


; Define the lat/lon grid to extract (global)                  
newlat = fspan( -90  + del_lat , 90    + del_lat , 361 )       
newlon = fspan( -180 + del_lon , 179.5 + del_lon , 720 )      
newlat@units = "degrees_lat"
newlon@units = "degrees_lon"


; Assigns meta data to new array SPFH_new from SPFH
var_new  = var


; Regrid the data using linint2 
var_new  = linint2(lon,lat,var,True,newlon,newlat,0)


; Reassign the coordinates from the shifted lat/lon's back to the normal lat lons (90S to 90N, 0 to 360 lon)
var_new!0 = "lat"
var_new!1 = "lon"

var_new&lat = lat
var_new&lon = lon

;************************************************
; Put pv_isen_new into file as pv_isen
;***********************************************
ncdf->$variable$ = var_new

end do     ; end timestep
end do     ; end variable
end do     ; end cluster

print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")
   
end