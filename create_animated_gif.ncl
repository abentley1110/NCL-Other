
  ;************************************************
  ;     Creates an animated .gif of images
  ;     Created by: Alicia M. Bentley
  ;		Date: 27 December 2017 
  ;*************************************************

  ;***********************IMPORT*******************

  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

  ;***********************SCRIPTS******************* 

  begin

print(" ")
print("**************")
print(" START SCRIPT ")
print("**************")
  
  img_loc = "/nfs/lb11/abentley/www/realtime/images/pacific/mslp_jet/"
  img_url = "/nfs/lb11/abentley/www/research_images/superstorm93/"
  
  do i = 29,56,1
;  	j = 200 - i     ; If you want to reverse the older, renumber them like this

  	j = i + 100		; Renumber images so they will be displayed in order (100-->)
  	
  	system("cp "+img_loc+"mslp_jet_"+i+".gif "+img_url+"standard_"+j+".png")
  end do
  
  print("Creating animated .gif..........")
  
  gif_create = "convert -delay 15 "+img_url+"standard_*.png -loop 0 +repage -trim -resize 1000x1000 "+img_url+"animated_gif.gif" 
  system(gif_create)
  system("'rm' "+img_url+"standard_*.png")
  
  ;************************************************* 
  
print(" ")
print("**************")
print(" END SCRIPT ")
print("**************")
  
  end
  
