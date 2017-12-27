;;***************************************************************************************
;; Calculates the total number of EWEs that are situated within a 
;; user-specified radius (km) of each gridpoint using great circle 
;; distances and outputs the total count to a netCDF file
;; Script adapted from a similar counting script created by Philippe Papin
;; Last update by Alicia M. Bentley on 27 December 2017

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"   

;;***************************************************************************************

begin

storms = 1672 - 2        ; Subtracted 2 because dummy file has two fake lines at the end of it

track_url = "/lb13/abentley/scripts/github/other/"
fileread = asciiread(track_url+"dummy_EC_track_data.csv",(/storms,9/),"float")
out_filename = "track_density_350km"

yyyy_arr := new(storms,double,0)
mm_arr := new(storms,double,0)
dd_arr := new(storms,double,0)
hh_arr := new(storms,double,0)
rlat_arr := new(storms,float,0)
rlon_arr := new(storms,float,0)
pres_arr := new(storms,double,0)
anom_arr := new(storms,double,0)
cyc_arr := new(storms,double,0)

;----------------------------------------------------------

do timestep = 0,storms-1						; Obtain track data from file

number = timestep + 1
print("Plotting line: "+number+" of "+storms)

	yyyy = flt2dble(fileread(timestep,0))
	mm = flt2dble(fileread(timestep,1))
	dd = flt2dble(fileread(timestep,2))
	hh = flt2dble(fileread(timestep,3))
	pres = decimalPlaces(flt2dble(fileread(timestep,4)),2,True)
	rlat = fileread(timestep,5)
	rlon = fileread(timestep,6)
	anom = flt2dble(fileread(timestep,7))
	cyc = flt2dble(fileread(timestep,8))

	yyyy_arr(timestep) = yyyy
	mm_arr(timestep) = mm
	dd_arr(timestep) = dd
	hh_arr(timestep) = hh
	pres_arr(timestep) = pres
	rlat_arr(timestep) = rlat
	rlon_arr(timestep) = rlon
	anom_arr(timestep) = anom
	cyc_arr(timestep) = cyc-47    ; EC numbers must start at 0 and increase by 1
								  ; Since first number was 47 in this dummy data, I subtracted 47 here

end do    ; end timestep (aka: finding lat/lons to plot)

print(" ")
print("Lat/Lons successfully collected from file")

;----------------------------------------------------------

all_lat = rlat_arr(:)
all_lat@_FillValue = 9.969209968386869e+36
all_lon = rlon_arr(:) 
all_lon@_FillValue = 9.969209968386869e+36

;;; first create lat/lon domain that is same as lat/lon domain in which EWEs are tracked
latRange = (/90,0/)  
lonRange = (/0,360/) 

;;; increments at 0.5 degree intervals
domain_lat = fspan(latRange(0),latRange(1),181)
domain_lon = fspan(lonRange(0),lonRange(1),721)

count_total = new((/dimsizes(domain_lat),dimsizes(domain_lon)/),"integer")
count_total!0 = "lat"
count_total!1 = "lon"
count_total&lat = domain_lat
count_total&lon = domain_lon
count_total = 0

count_track = new((/dimsizes(domain_lat),dimsizes(domain_lon)/),"integer")
count_track!0 = "lat"
count_track!1 = "lon"
count_track&lat = domain_lat
count_track&lon = domain_lon

;; lats and lons of domain, dimensioned same as count_total
lat_tot = conform(count_total,count_total&lat,0)
lon_tot = conform(count_total,count_total&lon,1)

nTracks = cyc_arr(storms-1)
print("There are "+nTracks+" tracks in total")
print(" ")

;***************************************************************************************

;; Loop through all of the tracks
print("nTracks: "+nTracks)


do iTrack=1,nTracks

  EWE_timeInds := ind(cyc_arr(:) .eq. iTrack)
  EWE_lats_all := all_lat(EWE_timeInds)
  EWE_lons_all := all_lon(EWE_timeInds) 
  print(EWE_timeInds) 
  
  count_track = 0
  ; count_track will keep track of whether or not a track has already been counted at
  ; each grid point. If a track is counted for a gridpoint, the value of count_track
  ; for that grid point is changed to 1. If the value becomes 1, then the same track 
  ; cannot be counted again for that grid point. count_track is reset to zero when
  ; we loop through the next track
  
  
  ;; Loop through all the times in the EWE track
  do iTimeTrack=0,dimsizes(EWE_timeInds)-1 

    lat_EWE = tofloat(count_total&lat) 
    lon_EWE = tofloat(count_total&lon) 

    lat_EWE = doubletofloat(EWE_lats_all(iTimeTrack)) 
    lon_EWE = doubletofloat(EWE_lons_all(iTimeTrack)) 

    ;;-----------------------------------------------------------------
    ;;Calculate Great Circle Distances between points
    ;;-----------------------------------------------------------------   

    r = 6370. ; radius of spherical Earth (km)    
    d2r = 0.0174532925199433 ; degrees to radians conversion factor
       
    lat1 = lat_tot
    lon1 = lon_tot
    lat2 = conform(count_total,lat_EWE,0)
    lon2 = conform(count_total,lon_EWE,1)  
       
    lat1 = lat1*d2r
    lon1 = lon1*d2r  
    lat2 = lat2*d2r
    lon2 = lon2*d2r    
  
  
    dlat = lat2-lat1
    dlon = lon2-lon1
    latTerm = sin(.5*dlat) 
    latTerm = latTerm*latTerm
    lonTerm = sin(.5*dlon) 
    lonTerm = lonTerm*lonTerm*cos(lat1)*cos(lat2)
    dAngle = sqrt(latTerm+lonTerm)
    dist = 2.*r*asin(dAngle)
    
    ;;-----------------------------------------------------------------  

    rad_search = 350.0 ; radius we search outward to (km)
    
    ; -If EWE is within the radius threshold of a grid point, and the same EWE has not
    ; been counted for at this grid point (i.e. count_track is still 0) then 
    ; EWE_count is assigned a value of 1 at this grid point, and will be added to
    ; count_track and count_total
    ;
    ; -count_track can only hold 0s and 1s, with 0 meaning a EWE has not been counted for
    ; a grid point yet, and 1 meaning a EWE has already been counted for a grid point
    ;
    ; -count_total will hold the total number of EWEs counted for each gridpoint when
    ; looping through all of the tracks   
    
    EWE_count = where((dist.lt.rad_search).and.(count_track.eq.0),1,0) 
    count_track = count_track + EWE_count
    count_total = count_total + EWE_count

  end do ; end iTimeTrack

end do ; end iTrack

printMinMax(count_total,True)

;;##################################################    
;;Output count to netCDF file
;;##################################################   

out_dir = track_url
out_fil = out_dir+out_filename+".nc"  ; Output filename
var = "count"

lat = domain_lat
lon = domain_lon

lat@units              = "degrees_north"
lat@long_name          = "latitude"
lat@grid_resolution    = "0.5_degrees"
lat@mapping            = "cylindrical_equidistant_projection_grid"
lat@coordinate_defines = "center"
lat@delta_y            = 0.5
lat@actual_range       = (/90,0/)

lon@units              = "degrees_east"
lon@long_name          = "longitude"
lon@grid_resolution    = "0.5_degrees"
lon@mapping            = "cylindrical_equidistant_projection_grid"
lon@coordinate_defines = "center"
lon@delta_x            = 0.5
lon@actual_range       = (/0,360/)

; File and Variable Attributes

fAtt = True

fAtt@creation_date  = systemfunc ("date")
fAtt@created_by     = "User: "+systemfunc ("whoami")
fAtt@description    = "Total EWE count within specified radius of each grid point"


vAtt = 1
vAtt@long_name  = "Total EWE count"
vAtt@_FillValue = 1000000000000000000

;--------- Output a compressed netCDF ------

setfileoption("nc","Format","NetCDF4Classic")
setfileoption("nc","CompressionLevel",1)

;--------- Initialize the netCDF file ------

system("/bin/rm -f "+out_fil)
outFile = addfile(out_fil, "c" )

fileattdef( outFile, fAtt )            ; Set file attributes

; Specify dimension coordinates

dimNames = (/ "lat", "lon" /)
dimSizes = (/dimsizes(lat), dimsizes(lon) /)
dimUnlim = (/False, False /)

chunks = (/dimsizes(lat), dimsizes(lon)  /)    ; Not as neccessary in this line but may as well force it to be user friendly.


filedimdef( outFile, dimNames, dimSizes, dimUnlim )
filechunkdimdef(outFile,dimNames,chunks,dimUnlim)


filevardef( outFile, "lat", "float", "lat" )
filevardef( outFile, "lon", "float", "lon" )
filevardef( outFile, var, "integer", (/ "lat", "lon" /) )


filevarattdef( outFile, "lat", lat )
filevarattdef( outFile, "lon", lon )
filevarattdef( outFile, var, vAtt )

; Write coordinates to record

outFile->lat = (/ lat /)
outFile->lon = (/ lon /)
outFile->$var$(:,:) = new( (/dimsizes(lat),dimsizes(lon)/), "integer")

print("netCDF file for "+var+" initialized on "+systemfunc("date"))

delete(outFile)
delete(dimNames)
delete(dimSizes)
delete(dimUnlim)
delete(chunks)


outfile = addfile(out_fil,"w")
outfile->$var$(:,:) = (/count_total/)


end