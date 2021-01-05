#!/bin/tcsh -xef

### ASSUMES BAD VOLUMES HAVE BEEN FILTERED OUT ###
###### sources newly filtered dwi_02 folder ######

#created June 8, 2018 (Catherine Cunningham). Edited by Michael Freedberg on 11-22-19.

#DIFFPREP corrects distortions caused by motion, eddy currents, and B0 inhomogeneities
#DRBUDDI performs EPI distortion correction by combining AP and PA datasets
#final output dataset is upsampled to 1.5 isotropic for smoothing

############### Set Vars ###############
### Set Base Drive (where DTI_Analyses is).
set home_dir = ENTER PATH!!!
### Select Groups
set GROUPS = ("Parietal" "Vertex")
########################################

echo
echo -----------------------------------------------------------------
echo Starting preprocessing with TORTOISE: `date`
echo -----------------------------------------------------------------
echo

foreach group ($GROUPS)
  if ( $group == "Parietal") then
    set SubList = ( ENTER SUBJECTS )
  else if ( $group == "Vertex") then
    set SubList = ( ENTER SUBJECTS )
  else
    echo WARNING: LABEL NOT FOUND, EXITING
    exit
  endif
  foreach subj ($SubList)
    # setting paths for pre-preprocessed subject dti data
    set path_P_ss = ENTER PATH!!!

    ########## DIFFPREP ##########

    echo
    echo ////// {$group} {$subj} DIFFPREP_ap //////
    echo

    # make a directory to hold 'starter' data for DIFFPREP, as well
    # as all the files it creates
    set odir = "$path_P_ss/dwi_03_ap"
    if ( ! -e $odir ) then
      mkdir $odir
    endif

    # uncompress the anatomical
    gunzip $path_P_ss/anat_01/t2w.nii.gz

    # for DIFFPREP command line, need row-vec and row-bval format
    1dDW_Grad_o_Mat++                                      \
      -in_col_matT      $path_P_ss/dwi_02/ap_matT.dat    \
      -unit_mag_out                                      \
      -out_row_vec      $odir/ap_rvec.dat                \
      -out_row_bval_sep $odir/ap_bval.dat

    # the NIFTI file must be unzipped
    3dcopy /$path_P_ss/dwi_02/ap.nii.gz $odir/ap.nii

    # finally, the main command itself
    DIFFPREP                                               \
      --dwi         $odir/ap.nii                         \
      --bvecs       $odir/ap_rvec.dat                    \
      --bvals       $odir/ap_bval.dat                    \
      --structural  $path_P_ss/anat_01/t2w.nii           \
      --phase       vertical                             \
      --will_be_drbuddied  1                             \
      --reg_settings TORTOISE_AFNI_bootcamp_DATA_registration_settings.dmc

    ###### the same for the PA Direction ######

    echo
    echo ////// {$group} {$subj} DIFFPREP_pa //////
    echo

    # make a directory to hold 'starter' data for DIFFPREP, as well
    # as all the files it creates
    set odir = "$path_P_ss/dwi_03_pa"
    if ( ! -e $odir ) then
      mkdir $odir
    endif

    # for DIFFPREP command line, need row-vec and row-bval format
    1dDW_Grad_o_Mat++                                      \
      -in_col_matT      $path_P_ss/dwi_02/pa_matT.dat    \
      -unit_mag_out                                      \
      -out_row_vec      $odir/pa_rvec.dat                \
      -out_row_bval_sep $odir/pa_bval.dat

    # the NIFTI file must be unzipped
    3dcopy $path_P_ss/dwi_02/pa.nii.gz $odir/pa.nii

    # finally, the main command itself
    DIFFPREP                                               \
      --dwi         $odir/pa.nii                         \
      --bvecs       $odir/pa_rvec.dat                    \
      --bvals       $odir/pa_bval.dat                    \
      --structural  $path_P_ss/anat_01/t2w.nii           \
      --phase       vertical                             \
      --will_be_drbuddied  1                             \
      --reg_settings TORTOISE_AFNI_bootcamp_DATA_registration_settings.dmc

    ########## DR_BUDDI ##########

    echo
    echo ////// {$group} {$subj} DRBUDDI //////
    echo

    DR_BUDDI_withoutGUI  --up_data $path_P_ss/dwi_03_ap/ap_proc.list --down_data  $path_P_ss/dwi_03_pa/pa_proc.list --structural $path_P_ss/anat_01/t2w.nii --res 1.5 1.5 1.5  --output $path_P_ss/dwi_04/buddi.list
  end # subject
end #groups

echo
echo -----------------------------------------------------------------
echo Ending preprocessing with TORTOISE: `date `
echo -----------------------------------------------------------------
echo
