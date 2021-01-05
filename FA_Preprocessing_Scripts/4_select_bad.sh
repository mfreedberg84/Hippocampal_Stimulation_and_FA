#!/bin/tcsh -xef

#created June 2018 (Catherine Cunningham)

# after running through the tortoise QC pipeline, and inspecting volumes and QC images for bad volumes, you should have a list of volumes to be thrown out
# activates AFNI GUI to select bad dwi volumes
# this script only needs to be run if there are volumes to throw out

### set base drive (Where DTI_Analyses is).
set home_dir = ENTER PATH!!!
### set path to Subjects data in Subjects_proc. 
set path_P_ss = ENTER PATH!!!

echo
echo ////// select ap baddies //////
echo

fat_proc_select_vols					     \
    -in_dwi  $path_P_ss/dwi_00/ap.nii.gz                     \
    -in_img  $path_P_ss/dwi_00/QC/ap_qc_sepscl.sag.png       \
    -prefix  $path_P_ss/dwi_01/dwi_sel_ap

echo
echo ////// select pa baddies //////
echo

fat_proc_select_vols  					     \
    -in_dwi  $path_P_ss/dwi_00/pa.nii.gz                     \
    -in_img  $path_P_ss/dwi_00/QC/pa_qc_sepscl.sag.png       \
    -in_bads $path_P_ss/dwi_01/dwi_sel_ap_bads.txt           \
    -prefix  $path_P_ss/dwi_01/dwi_sel_both
