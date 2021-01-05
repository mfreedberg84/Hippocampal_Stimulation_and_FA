#!/bin/tcsh -xef

#created June 8, 2018 (Catherine Cunningham). Edited by Michael Freedberg August 30th, 2019.
#performs pre-preprocessing of DWI and associated structural images using FATCAT commands
#prepares data for TORTOISE preprocessing steps. 

########### Input Variables #######################
### Enter base drive (where DTI_Analyses is)
set home_dir = ENTER PATH!!!
### Input Subject List
set Sublist = ("S01")
### Set Drive to Raw Data(dti_ap, dti_pa, t1w, t2w).
set InDrive = ENTER PATH!!!
### Set Output drive.
set OutDrive = ENTER PATH!!!
### Set path to fatcat_proc_mni_ref folder
set refdrive = ENTER PATH!!!
###################################################

echo
echo ------------------------------------------------------------------------
echo Starting preprocessing fatcat: `date`
echo -----------------------------------------------------------------------
echo

foreach subj ($Sublist)
    set c=`ls -a {$InDrive}/{$subj}/t2w | wc | awk '{print $1}'`
    if ( "${c}" == 2 ) then 
  	echo No t2w...skipping {$subj}...
        sleep 20
        continue
    endif		
    echo
    echo ---------------------------------------------------------------------
    echo Started DTI preprocessing $subj `date`
    echo ---------------------------------------------------------------------
    echo
	### Setup and cleanup
	rm -r {$InDrive}/{$subj}/dti_pa/*proc
	rm -r {$InDrive}/{$subj}/dti_ap/*proc
	mkdir {$OutDrive}/{$subj}
	# set paths for subject raw data and output data folders 
    set path_S_ss = {$InDrive}/{$subj}
    set path_P_ss = {$OutDrive}/{$subj}
    ###################################
    # convert DWIs from raw DICOMs to usable formats
    # for data acquired in two phase-encoded directions, this step is performed twice
    echo
    echo //////{$subj} convert DWIs//////
    echo
    mkdir -p {$path_P_ss}/dwi_00

    fat_proc_convert_dcm_dwis -indir "{$path_S_ss}/dti_ap/DTI*" -prefix {$path_P_ss}/dwi_00/ap

    fat_proc_convert_dcm_dwis -indir  "$path_S_ss/dti_pa/DTI*" -prefix $path_P_ss/dwi_00/pa

    ###################################
    # convert anatomical from raw DICOMs to usable formats
    # performed for both t1-weighted and t2-weighted anatomical volumes
    echo
    echo //////{$subj} convert anatomical//////
    echo
    mkdir -p {$path_P_ss}/anat_00/

    fat_proc_convert_dcm_anat              \
        -indir  $path_S_ss/t1w     \
        -prefix $path_P_ss/anat_00/t1w

    fat_proc_convert_dcm_anat              \
        -indir  $path_S_ss/t2w     \
        -prefix $path_P_ss/anat_00/t2w

    ###################################
    # axialize T2 using reference volumes and resample to 1mm isotropic
    echo
    echo //////{$subj} axialize//////
    echo
    # paths to axialized reference volumes
    set ref_t2w    = {$refdrive}/fatcat_proc_mni_ref/mni_icbm152_t2_relx_tal_nlin_sym_09a_ACPCE.nii.gz
    set ref_t2w_wt = {$refdrive}/fatcat_proc_mni_ref/mni_icbm152_t2_relx_tal_nlin_sym_09a_ACPCE_wtell.nii.gz

    mkdir -p {$path_P_ss}/anat_01

    fat_proc_axialize_anat                       \
        -inset  $path_P_ss/anat_00/t2w.nii.gz    \
        -prefix $path_P_ss/anat_01/t2w           \
        -mode_t2w                                \
        -refset          $ref_t2w                \
        -extra_al_wtmask $ref_t2w_wt             \
        -extra_al_opts "-newgrid 1.0".           \
        -out_match_ref

    ###################################
    # align T1w -> T2w - to bring T1 into already axialized T2 space
    echo
    echo //////{$subj} align//////
    echo

    fat_proc_align_anat_pair                     \
        -in_t1w    $path_P_ss/anat_00/t1w.nii.gz \
        -in_t2w    $path_P_ss/anat_01/t2w.nii.gz \
        -prefix    $path_P_ss/anat_01/t1w        \
        -out_t2w_grid			     \
        -do_ss_tmp_t1w

    echo
    echo -----------------------------------------------------------------
    echo Ended DTI preprocessing $subj `date`
    echo -----------------------------------------------------------------
    echo
end #subj 

echo
echo ------------------------------------------------------------------------
echo Finished preprocessing fatcat: `date`
echo -----------------------------------------------------------------------
echo
