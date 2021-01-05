#!/bin/tcsh -xef

# created June 18, 2018, last modified July 20, 2018 (Catherine Cunningham). Edited by Michael Freedberg on September 2nd, 2019.

# this script runs through a QC pipeline for diffusion data - separately from, but in parallel with, FATCAT pre-preprocessing - solely for QC purposes

# 1 imports raw dwi dicoms and generates tortoise compatible file types 
# 2 converts new list files into old format to be used in tortoise GUI
# 3 performs rough tensor fitting from raw imported DWI volumes 
# 4 generates DEC maps for QC
################# Input Variables ######################
### Enter base drive (where DTI_Analyses is).
set home_dir = ENTER PATH!!!
### Enter subjects for processing.
set Sublist = ("S01")
### Enter path to raw data.
set InDrive = ENTER PATH!!!
### Enter output drive.
set OutDrive = ENTER PATH!!!
########################################################

foreach subj ($Sublist)
    ############ 1 ############
    set path_raw = {$InDrive}/{$subj}
    set path_proc = {$OutDrive}/{$subj}
    ### Setup and cleanup
    rm -r {$path_proc}/dti_ap_proc
    rm -r {$path_proc}/dti_pa_proc
    mkdir -p {$path_proc}/dti_ap_proc
    mkdir -p {$path_proc}/dti_pa_proc
    ########################
    echo
    echo ////// import {$subj} AP //////
    echo
    mkdir -p {$path_proc}/dti_ap_proc
    ImportDICOM -i $path_raw/dti_ap -o $path_proc/dti_ap_proc
    echo
    echo ////// import {$subj} PA //////
    echo
    ImportDICOM -i $path_raw/dti_pa -o $path_proc/dti_pa_proc
    ############ 2 ############
    set path_AP = {$path_proc}/dti_ap_proc
    set path_PA = {$path_proc}/dti_pa_proc
    echo
    echo ////// convert to old //////
    echo
    ConvertNewListfileToOld $path_AP/dti_ap.list
    ConvertNewListfileToOld $path_PA/dti_pa.list
    ############ 3 ############
    echo
    echo ////// estimating tensors for {$subj} //////
    echo
    #ap
    EstimateTensorWLLS -i $path_AP/dti_ap.list
    #pa
    EstimateTensorWLLS -i $path_PA/dti_pa.list
    ############ 4 ############
    echo
    echo ////// computing DEC maps for {$subj} //////
    echo
    #ap
    ComputeDECMap $path_AP/dti_ap_L0_DT.nii
    ExtractPNGFromNIFTI $path_AP/dti_ap_L0_DT_DEC.nii
    ComputeNSDECMap $path_AP/dti_ap_L0_DT.nii
    ExtractPNGFromNIFTI $path_AP/dti_ap_L0_DT_DECNS.nii
    #pa
    ComputeDECMap $path_PA/dti_pa_L0_DT.nii
    ExtractPNGFromNIFTI $path_PA/dti_pa_L0_DT_DEC.nii
    ComputeNSDECMap $path_PA/dti_pa_L0_DT.nii
    ExtractPNGFromNIFTI $path_PA/dti_pa_L0_DT_DECNS.nii
end #subj

# now check raw list files with tortoise GUI for bad volumes and artifacts
# now check DEC maps for importing errors and artifacts
# also run tort_glyphs script in bash and check associated maps
