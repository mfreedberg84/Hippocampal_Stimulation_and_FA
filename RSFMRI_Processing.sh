#!/bin/tcsh -xef
### Preprocessing RSFMRI Data. Four paths need to be set in order to run this script on lines 22,24,26,and 28.
# SubList = Subject (e.g. S01, S02)
# CONDITION = "Pre_Stimulation_Real" or "Post_Stimulation_Real"
# ARM = "Parietal" or "Vertex"
set SubList = ("S22")
set Condition = ("Post_Stimulation_Real")
set arm = "Vertex"
set res = 2.0 	# post-processing resolution
set m = 0.3     # motion censoring threshold
set o = 97
set slices = 36
set ndcm = 206
set TR = 2000.0
# Do you want to bandpass filter? 1 for yes, 0 for no.
set BP = 0
set firstcond = "Pre_Stimulation_Real"
########################################################################

echo
echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
echo Begin Preprocessing: `date`
echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
echo

foreach ID ($SubList)
    # This is where your Raw Data are.
    set ss_dir = ENTER PATH!!!
    # This is where your created MPRAGE file will be in the Subject's folder
    set mprage_dir = ENTER PATH!!!
    # This is where your Subjects functional data is going to end up.
    set SubDrive = ENTER PATH!!!
    # This is where your TT_N27+tlrc file is
    set Templates_Dir = ENTER PATH!!!
    mkdir {$SubDrive}
    mkdir -p {$mprage_dir}
    if ($Condition == $firstcond) then
        cd {$mprage_dir}
        echo
        echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        echo Creating Anatomical Image for Pre_Stimulation_Real
        echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        echo
        rm -r {$mprage_dir}
        if (-d {$ss_dir}/MPRAGE/ss_afni) then
             rm -r {$ss_dir}/MPRAGE/ss_afni
        endif
        echo MPRAGE
        mkdir {$ss_dir}/MPRAGE/ss_afni
        mkdir {$mprage_dir}
        cd {$ss_dir}/MPRAGE/ss_afni
        Dimon -infile_pattern '../*.dcm' -dicom_org -gert_create_dataset -gert_to3d_prefix rm.oMPRAGE
        3dWarp -deoblique -prefix {$ID}.MPRAGE_Skin rm.oMPRAGE+orig.
        3dUnifize -prefix afni.MPRAGE {$ID}.MPRAGE_Skin+orig
        3dcopy afni.MPRAGE+orig MPRAGE
        3dSkullStrip -input afni.MPRAGE+orig -avoid_vent -touchup -touchup -push_to_edge \
        -init_radius 100 -ld 30 -niter 250 -shrink_fac 0.6 -shrink_fac_bot_lim 0.65 \
        -smooth_final 30 -max_inter_iter 2 -fill_hole 15 -mask_vol -prefix ss.mask
        3dcalc -a ss.mask+orig -expr "step(a-4)" -prefix rm.ss.brainmask+orig
        3dmask_tool -input rm.ss.brainmask+orig -dilate_input 6 -6 -prefix rm.ss.brain
        3dcalc -a afni.MPRAGE+orig -b rm.ss.brain+orig -expr "a*step(b)" -prefix ss

        ### tlrc
        cd $mprage_dir
        3dcopy $ss_dir/MPRAGE/ss_afni/ss+orig. ${ID}_MPRAGE
        3dcopy $ss_dir/MPRAGE/ss_afni/{$ID}.MPRAGE_Skin+orig. {$ID}.MPRAGE_Skin+orig.
        @auto_tlrc -base {$Templates_Dir}/AFNI_Masks_and_Atlases/TT_N27+tlrc -input ${ID}_MPRAGE+orig. -no_ss
        ### remove temporary files
        rm -f rm.*
    else
        echo
        echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        echo Skipped building Anatomical image for Post_Stimulation_Real
        echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
        echo
    endif

    # Process Functional Data
    # HouseKeeping
    echo
    echo --- Cleaning Functional Folder ---
    echo
    rm -r {$SubDrive}
    mkdir -p {$SubDrive}
    mkdir -p {$SubDrive}/{$arm}/{$ID}/Seed_Finder/{$Condition}
    echo
    echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    echo Creating Functional Image for {$Condition}
    echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    echo
    # ============================ to3d ============================
    cd $ss_dir/RSFMRI
    rm OutBrick*
    to3d -prefix OutBrick -time:zt $slices $ndcm $TR alt+z2 *.dcm
    3dcopy OutBrick+orig. {$SubDrive}/OutBrick+orig.
    cd $SubDrive
    touch Condition_param.txt
    echo " slices = $slices | TR = $TR | ndcm = $ndcm" >> Condition_param.txt

    # ============================ auto block: tcat ============================
    # apply 3dTcat to copy input dsets to results dir, while removing the first N TRs
    3dTcat -prefix pb00.$ID.$Condition.tcat OutBrick+orig.'[5..$]'
    3dinfo -verb -slice_timing pb00.$ID.$Condition.tcat+orig > slice_timing.txt

    # ========================== auto block: outcount ==========================
    # data check: compute outlier fraction for each volume
    touch out.pre_ss_warn.txt
    3dToutcount -automask -fraction -polort 3 -legendre pb00.$ID.$Condition.tcat+orig > outcount.$Condition.1D
    # outliers at TR 0 might suggest pre-steady state TRs
    if ( `1deval -a outcount.$Condition.1D"{0}" -expr "step(a-0.4)"` ) then
        echo "** TR #0 outliers: possible pre-steady state TRs in  $Condition" >> out.pre_ss_warn.txt
    else
    endif

    # ================================ despike =================================
    # apply 3dDespike to each run
    3dDespike -NEW -nomask -prefix pb00.$ID.$Condition.despike pb00.$ID.$Condition.tcat+orig

    # ================================= tshift =================================
    # time shift data so all slice timing is the same
    3dTshift -tzero 0 -quintic -prefix pb00.$ID.$Condition.tshift pb00.$ID.$Condition.despike+orig
    3dWarp -deoblique -prefix pb01.$ID.$Condition.tshift pb00.$ID.$Condition.tshift+orig

    # ================================= volreg =================================
    # align each dset to base volume, align to anat, warp to tlrc space
    3dvolreg -verbose -zpad 1 -cubic -base pb01.$ID.$Condition.tshift+orig'[2]'    \
    -1Dfile dfile.$Condition.1D -1Dmatrix_save mat.$Condition.vr.aff12.1D             \
    -prefix rm.epi.volreg.$Condition pb01.$ID.$Condition.tshift+orig
    # make a single file of registration params
    cat dfile.$Condition.1D > dfile_rall.1D

    # ================================= align ==================================
    # for e2a: compute anat alignment transformation to EPI registration base
    align_epi_anat.py -anat2epi -anat $mprage_dir/${ID}_MPRAGE+orig. -anat_has_skull no \
    -epi pb01.$ID.$Condition.tshift+orig -epi_base 2 -epi_strip 3dAutomask \
    -suffix _al_junk -check_flip -volreg off -tshift off \
    -ginormous_move -cost lpc+ZZ
    # store forward transformation matrix in a text file
    cat_matvec $mprage_dir/${ID}_MPRAGE+tlrc::WARP_DATA -I > warp.anat.Xat.1D
    # verify that we have a +tlrc warp dataset
    if ( ! -f $mprage_dir/${ID}_MPRAGE+tlrc.HEAD ) then
        echo "** missing +tlrc warp dataset: ${ID}_MPRAGE+tlrc.HEAD"
    exit
    else
    endif

    # create an all-1 dataset to mask the extents of the warp
    3dcalc -overwrite -a pb01.$ID.$Condition.tshift+orig -expr 1 -prefix rm.epi.all1
    # catenate volreg, epi2anat and tlrc transformations
    cat_matvec -ONELINE $mprage_dir/${ID}_MPRAGE+tlrc::WARP_DATA -I ${ID}_MPRAGE_al_junk_mat.aff12.1D -I mat.$Condition.vr.aff12.1D > mat.$Condition.warp.aff12.1D
    # apply catenated xform : volreg, epi2anat and tlrc
    3dAllineate -base $mprage_dir/${ID}_MPRAGE+tlrc -input pb01.$ID.$Condition.tshift+orig -1Dmatrix_apply mat.$Condition.warp.aff12.1D -mast_dxyz $res -prefix rm.epi.nomask.$Condition
    # warp the all-1 dataset for extents masking
    3dAllineate -base $mprage_dir/${ID}_MPRAGE+tlrc -input rm.epi.all1+orig -1Dmatrix_apply mat.$Condition.warp.aff12.1D -mast_dxyz $res -final NN -quiet -prefix rm.epi.1.$Condition
    # make an extents intersection mask of this run
    3dTstat -min -prefix rm.epi.min.$Condition rm.epi.1.$Condition+tlrc
    # create the extents mask: mask_epi_extents+tlrc (this is a mask of voxels that have valid data at every TR)
    3dcopy rm.epi.min.$Condition+tlrc mask_epi_extents
    # and apply the extents mask to the EPI data (delete any time series with missing data)
    3dcalc -a rm.epi.nomask.$Condition+tlrc -b mask_epi_extents+tlrc -expr 'a*b' -prefix pb02.$ID.$Condition.volreg
    # create an anat_final dataset, aligned with stats
    3dcopy $mprage_dir/${ID}_MPRAGE+tlrc anat_final.$ID
    3dcopy $mprage_dir/${ID}_MPRAGE+orig anat_final.$ID

    # ================================== blur ==================================
    # blur each volume of each run | Jane also used 4.0
    3dmerge -1blur_fwhm 4.0 -doall -prefix pb03.$ID.$Condition.blur pb02.$ID.$Condition.volreg+tlrc

    # ================================== mask ==================================
    # create 'full_mask' dataset (union mask)
    3dAutomask -dilate 1 -prefix rm.mask_$Condition pb03.$ID.$Condition.blur+tlrc
    # create union of inputs, output type is byte
    3dmask_tool -inputs rm.mask_$Condition+tlrc.HEAD -union -prefix full_mask.$ID
    # create IDect anatomy mask, mask_anat.$ID+tlrc (resampled from tlrc anat)
    3dresample -master full_mask.$ID+tlrc -input $mprage_dir/${ID}_MPRAGE+tlrc -prefix rm.resam.anat
    # convert to binary anat mask; fill gaps and holes
    3dmask_tool -dilate_input 5 -5 -fill_holes -input rm.resam.anat+tlrc -prefix mask_anat.$ID
    # compute overlaps between anat and EPI masks
    3dABoverlap -no_automask full_mask.$ID+tlrc mask_anat.$ID+tlrc |& tee out.mask_ae_overlap.txt
    # note Dice coefficient of masks, as well
    3ddot -dodice full_mask.$ID+tlrc mask_anat.$ID+tlrc |& tee out.mask_ae_dice.txt

    # ================================= scale ==================================
    # scale each voxel time series to have a mean of 100 (no negatives; range of [0,200])
    3dTstat -prefix rm.mean_$Condition pb03.$ID.$Condition.blur+tlrc
    3dcalc -a pb03.$ID.$Condition.blur+tlrc -b rm.mean_$Condition+tlrc -c mask_epi_extents+tlrc -expr 'c * min(200, a/b*100)*step(a)*step(b)' -prefix pb04.$ID.$Condition.scale

    # ================================ regress =================================
    # compute de-meaned motion parameters (for use in regression)
    1d_tool.py -infile dfile.$Condition.1D -set_nruns 1 -demean -write motion_demean.1D
    # compute motion parameter derivatives
    1d_tool.py -infile dfile.$Condition.1D -set_nruns 1 -derivative -demean -write motion_deriv.1D
    1d_tool.py -show_mmms -infile motion_deriv.1D > motion_deriv.$ID.mmms.txt
    # create censor file motion_${ID}_censor.1D, for censoring motion
    1d_tool.py -infile dfile.$Condition.1D -set_nruns 1 -show_censor_count -censor_prev_TR -censor_motion $m motion_${ID}
    1d_tool.py -infile dfile.$Condition.1D -set_nruns 1 -quick_censor_count $m > TRs_out.$ID.$Condition.txt
    # count total TRs
    1d_tool.py -infile motion_${ID}_enorm.1D -show_tr_run_counts trs > out.TRs.txt
    set nTRs = `cat out.TRs.txt`
    set nTRs_out = `cat TRs_out.$ID.$Condition.txt`
    touch regress_param.txt
    echo "total TRs = $nTRs | censored TRs = $nTRs_out | censor threshold = $m" > regress_param.txt
    # create bandpass regressors
    1dBport -nodata $nTRs $TR -band 0.01 0.1 -invert -nozero > bandpass_$Condition.1D
    # create regression matrix
    if ($nTRs_out < $o ) then
        if ($BP == 1) then
            echo
            echo - BANDPASS Commencing -
            echo
            3dDeconvolve -input pb04.$ID.$Condition.scale+tlrc.HEAD                       \
            -censor motion_${ID}_censor.1D                                       \
            -ortvec bandpass_{$Condition}.1D bandpass                                     \
            -polort A -float                                                       \
            -num_stimts 12                                                         \
            -stim_file 1 motion_demean.1D'[0]' -stim_base 1 -stim_label 1 roll_01  \
            -stim_file 2 motion_demean.1D'[1]' -stim_base 2 -stim_label 2 pitch_01 \
            -stim_file 3 motion_demean.1D'[2]' -stim_base 3 -stim_label 3 yaw_01   \
            -stim_file 4 motion_demean.1D'[3]' -stim_base 4 -stim_label 4 dS_01    \
            -stim_file 5 motion_demean.1D'[4]' -stim_base 5 -stim_label 5 dL_01    \
            -stim_file 6 motion_demean.1D'[5]' -stim_base 6 -stim_label 6 dP_01    \
            -stim_file 7 motion_deriv.1D'[0]' -stim_base 7 -stim_label 7 roll_02   \
            -stim_file 8 motion_deriv.1D'[1]' -stim_base 8 -stim_label 8 pitch_02  \
            -stim_file 9 motion_deriv.1D'[2]' -stim_base 9 -stim_label 9 yaw_02    \
            -stim_file 10 motion_deriv.1D'[3]' -stim_base 10 -stim_label 10 dS_02  \
            -stim_file 11 motion_deriv.1D'[4]' -stim_base 11 -stim_label 11 dL_02  \
            -stim_file 12 motion_deriv.1D'[5]' -stim_base 12 -stim_label 12 dP_02  \
            -fout -tout -x1D X.xmat.1D -xjpeg X.jpg                                \
            -x1D_uncensored X.nocensor.xmat.1D                                     \
            -fitts fitts.${ID}                                                   \
            -errts errts.${ID}                                                   \
            -x1D_stop                                                              \
            -bucket stats.${ID}
        else
            echo
            echo - NO BANDPASS -
            echo
            3dDeconvolve -input pb04.$ID.$Condition.scale+tlrc.HEAD                       \
            -censor motion_${ID}_censor.1D                                       \
            -polort A -float                                                       \
            -num_stimts 12                                                         \
            -stim_file 1 motion_demean.1D'[0]' -stim_base 1 -stim_label 1 roll_01  \
            -stim_file 2 motion_demean.1D'[1]' -stim_base 2 -stim_label 2 pitch_01 \
            -stim_file 3 motion_demean.1D'[2]' -stim_base 3 -stim_label 3 yaw_01   \
            -stim_file 4 motion_demean.1D'[3]' -stim_base 4 -stim_label 4 dS_01    \
            -stim_file 5 motion_demean.1D'[4]' -stim_base 5 -stim_label 5 dL_01    \
            -stim_file 6 motion_demean.1D'[5]' -stim_base 6 -stim_label 6 dP_01    \
            -stim_file 7 motion_deriv.1D'[0]' -stim_base 7 -stim_label 7 roll_02   \
            -stim_file 8 motion_deriv.1D'[1]' -stim_base 8 -stim_label 8 pitch_02  \
            -stim_file 9 motion_deriv.1D'[2]' -stim_base 9 -stim_label 9 yaw_02    \
            -stim_file 10 motion_deriv.1D'[3]' -stim_base 10 -stim_label 10 dS_02  \
            -stim_file 11 motion_deriv.1D'[4]' -stim_base 11 -stim_label 11 dL_02  \
            -stim_file 12 motion_deriv.1D'[5]' -stim_base 12 -stim_label 12 dP_02  \
            -fout -tout -x1D X.xmat.1D -xjpeg X.jpg                                \
            -x1D_uncensored X.nocensor.xmat.1D                                     \
            -fitts fitts.${ID}                                                   \
            -errts errts.${ID}                                                   \
            -x1D_stop                                                              \
            -bucket stats.${ID}
        endif # Bandpass
        # detrend model out of data to get error time series
        3dTproject -polort 0 -input pb04.$ID.$Condition.scale+tlrc.HEAD -censor motion_${ID}_censor.1D -cenmode ZERO -ort X.nocensor.xmat.1D -prefix errts.$ID.$Condition.tproject
        # mask out final data
        3dcalc -a errts.$ID.$Condition.tproject+tlrc -b full_mask.$ID+tlrc -prefix errts.$ID.$Condition -expr 'a*step(b)'
    else
        echo "too many TRs censored; cannot run 3dDeconvolve"
    endif
end #sub

echo
echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
echo Ended Preprocessing: `date`
echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
echo
