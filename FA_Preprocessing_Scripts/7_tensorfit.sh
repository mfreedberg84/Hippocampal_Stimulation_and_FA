#!/bin/tcsh -xef

#created July 2018 (Catherine Cunningham). Edited by Michael Freedberg on 11-22-19.

# estimates tensors and associated parameters
# generates files to check that the right gradient flip was used (CHECK THESE!)
# produces color maps to check output

################ Set Vars ############################
### Select Groups
set GROUPS = ("Parietal" "Vertex")
### Set Base Drive (where DTI_Analyses is).
set home_dir = ENTER PATH!!!!
######################################################

echo
echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
echo Beginning Tensor Fit: `date`
echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
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
        echo
        echo ------------------------------------
        echo Tensor fitting $group $subj
        echo ------------------------------------
        echo
        set path_P_ss = ENTER PATH!!!

        ##################################

        # estimate tensors and test flip

        echo
        echo //////gradient flip test for {$subj}//////
        echo

        # shortcut names for what will be our input (-> from TORT proc)
        # and output (-> another dwi_* directory)
        set itort = $path_P_ss/dwi_04
        set odir  = $path_P_ss/dwi_05

        if ( ! -e $odir ) then
            mkdir $odir
        endif

        # A) do autoflip check: not ideal to need this, but such is life
        @GradFlipTest \
            -in_dwi       $itort/buddi.nii                \
            -in_col_matT  $itort/buddi.bmtxt              \
            -prefix       $itort/GradFlipTest_rec.txt

        # get the 'recommended' flip; still should verify visually!!
        set my_flip = `cat $itort/GradFlipTest_rec.txt`

        echo
        echo //////estimating tensors for {$subj}//////
        echo

        # B) DT+parameter estimates, with flip chosen from @GradFlipTest
        fat_proc_dwi_to_dt \
            -in_dwi       $itort/buddi.nii                    \
            -in_col_matT  $itort/buddi.bmtxt                  \
            -in_struc_res $itort/structural.nii               \
            -in_ref_orig  $path_P_ss/anat_01/t2w.nii          \
            -prefix       $odir/dwi                           \
            -mask_from_struc                                  \
            $my_flip

        ##################################

        # generating directionally-encoded color maps

        echo
        echo //////generate DEC map for {$subj}//////
        echo

        fat_proc_decmap                                     \
            -in_fa       $path_P_ss/dwi_05/dt_FA.nii.gz     \
            -in_v1       $path_P_ss/dwi_05/dt_V1.nii.gz     \
            -mask        $path_P_ss/dwi_05/dwi_mask.nii.gz  \
            -prefix      $path_P_ss/dwi_05/DEC
    end # subject
end #group

echo
echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
echo Ending Tensor Fit: `date`
echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
echo
