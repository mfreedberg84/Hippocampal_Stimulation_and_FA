#!/bin/tcsh -xef

#created June 2018 (Catherine Cunningham). Edited by Michael Freedberg on 11-20-19.

# requires list of bad volumes created from ‘select_bad’ script
# creates new diffusion files, now free of bad volumes
################ Set Vars #######################
### Select Group (Parietal or Vertex
set GROUP = ("Parietal")
### Set base drive (where DTI_Analyses is).
set home_dir = ENTER PATH!!!
##########################################################
# filter from both AP and PA dwi sets, both vols and b-matrices

echo
echo  ---------------------------------------------------
echo Beginning volume keepage: `date`
echo  ---------------------------------------------------
echo

foreach group ($GROUP)
  if ( $group == "Parietal") then
      set SubList = ( ENTER SUBJECTS )
      #set SubList = ( S01 )
    else if ( $group == "Vertex") then
      set SubList = ( ENTER SUBJECTS )
  else
    echo WARNING: LABEL NOT FOUND, EXITING
    exit
  endif
  foreach subj ($SubList)
    echo
    echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    echo Keeping good volumes for $subj $group
    echo xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    echo
    set path_P_ss = ENTER PATH!!!
    # the string of *good* volumes after selecting *bads*
    set selstr = `cat {$path_P_ss}/dwi_01/dwi_sel_both_goods.txt`
    ### Clean previous attempt
    if ( ! -e $path_P_ss/dwi_02) then
      echo Creating new drive...
    else
      echo Making Room...
      rm -r $path_P_ss/dwi_02
    endif

    echo
    echo ////// filter ap //////
    echo

    fat_proc_filter_dwis                                 \
      -in_dwi        $path_P_ss/dwi_00/ap.nii.gz       \
      -in_col_matT   $path_P_ss/dwi_00/ap_matT.dat     \
      -select        "$selstr"                         \
      -prefix        $path_P_ss/dwi_02/ap

    echo
    echo ////// filter pa //////
    echo

    fat_proc_filter_dwis                                 \
      -in_dwi        $path_P_ss/dwi_00/pa.nii.gz       \
      -in_col_matT   $path_P_ss/dwi_00/pa_matT.dat     \
      -select        "$selstr"                         \
      -prefix        $path_P_ss/dwi_02/pa
  end # Subject
end # Group

echo
echo  ---------------------------------------------------
echo Ending volume keepage: `date`
echo  ---------------------------------------------------
echo
