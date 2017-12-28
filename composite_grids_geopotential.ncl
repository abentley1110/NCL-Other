; ===========================================
; Composites shifted 600-400-hPa geo. height data 
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
print(" ")

clus = (/"eastcoast"/)  ; Specify which subset of grids you're compositing
endfolder = dimsizes(clus)

do x = 0,endfolder-1      ; Loop through the subsets of grids you're compositing

folder = clus(x)

; ********************************************************
; Specify the variable you're going to shift 
; ********************************************************

layer = (/"g"/)
endvar = dimsizes(layer)

do v = 0,endvar-1

if v .gt. 0 
  delete(variable)
end if

variable = layer(v)

; ******************************************************
; Specify directory where files will be found/output to
; ******************************************************
dir_in = "/lb13/abentley/scripts/github/other/shiftgrids/"+folder+"/"

dir_out = "/lb13/abentley/scripts/github/other/compgrids/"+folder+"/"
system ("mkdir /lb13/abentley/scripts/github/other/compgrids/")
system ("mkdir /lb13/abentley/scripts/github/other/compgrids/"+folder+"/")

print(" ")
print(" ")
print("IN: "+dir_in+" ("+variable+")")
print("OUT: "+dir_out+" ("+variable+")")
print(" ")
print(" ")

; **************************************
; Only composite one variable at a time
; **************************************

; Reads in all files with same file convention so that compositing can be performed across multiple files
files := systemfunc("ls "+dir_in+variable+"_shift_*.nc")

f := addfiles(files, "r")

ListSetType (f, "join")

if variable .eq. "irro_wind" then
var := f[:]->$variable$(:,bloop,:,:)
else
var := f[:]->$variable$
end if


var!0 = "member"
;printVarSummary(var)

; Computes the average SPFH across cases (composite "members")
var_avg := dim_avg_n_Wrap(var,0)

; Creates an output file and puts the composite array in it
system ("'rm' "+dir_out+"comp_"+variable+".nc")
ofile = addfile (dir_out+"comp_"+variable+".nc", "c")

total_lags := new((/361,720/),"float")
total_lags(:,:) = var_avg
ofile->$variable$ = total_lags

;--------------------------------------------

delete(files)
delete(f)

end do       ; end variable
end do       ; end folder


print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
print(" ")

end
