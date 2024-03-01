#!/bin/bash
# This is a wrapper to run Synb0-DISCO locally and is based on pipeline.sh
# It expects a local_paths.sh file to be present in the same directory containing 
# the paths to the tools (Freesurfer, FSL, ANTS, C3D). See example_local_paths.sh for an example.
#
# Usage: synb0-disco_local.sh -t T1.nii.gz -b b0.nii.gz -a acqparams.txt -o outdir -i -s
#
# -t T1.nii.gz: path to the T1-weighted image (either raw or skull-stripped, see [Flags](#flags))
# -b b0.nii.gz: path to the the non-diffusion weighted image(s)
# -a acqparams.txt: path to the acqusition parameters (see [Inputs](#Inputs), not required if -s is used)
# -o outdir: path to specified output directory
# 
# Flags:
# -i : if set, topup is not run
# -s : if set, the 1mm T1 atlas is stripped


#-------------------------------------------------#
## Set path for executable
Synb0_path=$(dirname "$0")
Synb0_path=${Synb0_path%/local}
export Synb0_SRC=${Synb0_path}/src
export Synb0_PROC=${Synb0_path}/data_processing
export Synb0_ATLAS=${Synb0_path}/atlases
export Synb0_LOCAL=${Synb0_path}/local
export PATH=$PATH:$Synb0_SRC:$Synb0_PROC:$Synb0_ATLAS:$Synb0_LOCAL

# Set paths for local tools (FreeSurfer, FSL, ANTs, c3d, PyTorch, NumPy, SciPy, and NiBabel)
if [ -f $Synb0_LOCAL/local_paths.sh ]; then
    source $Synb0_LOCAL/local_paths.sh
else
    echo "local_paths.sh not found. Please check local_paths_example.sh."
    exit 1
fi

#-------------------------------------------------#
## Arguments
# Set default values
TOPUP=1
MNI_T1_1_MM_FILE=$Synb0_ATLAS/mni_icbm152_t1_tal_nlin_asym_09c.nii.gz

# Check if no arguments were provided
if [ $# -eq 0 ]; then
  echo "No arguments provided"
  echo "Usage: synb0-disco_local.sh -t T1.nii.gz -b b0.nii.gz -a acqparams.txt -o outdir -i -s"
  exit 1
fi

# Parse arguments
while getopts ":t:b:a:o:is" opt; do
  case $opt in
    t) T1="$OPTARG"
    ;;
    b) b0="$OPTARG"
    ;;
    a) ACQP="$OPTARG"
    ;;
    o) OUTPUTDIR="$OPTARG"
    ;;
    i) 
        iFlag=true
        TOPUP=0
    ;;
    s) 
        sFlag=true
        MNI_T1_1_MM_FILE=$Synb0_ATLAS/mni_icbm152_t1_tal_nlin_asym_09c_mask.nii.gz
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
    ;;
  esac
done

## Checks
# exit if variable is empty or files does not exist
errorMsg=""

if [ -z "$T1" ] || [ ! -f "$T1" ]; then
    errorMsg+="T1 not provided or file does not exist\n"
fi

if [ -z "$b0" ] || [ ! -f "$b0" ]; then
    errorMsg+="b0 not provided or file does not exist\n"
fi

if [ -z "$OUTPUTDIR" ]; then
    errorMsg+="Output directory not provided\n"
fi

# if TOPUP is set, check if acqparams exists
if [[ $TOPUP -eq 1 ]]; then
    if [ -z "$ACQP" ] || [ ! -f "$ACQP" ]; then
        errorMsg+="acqparams file not found\n"
    fi
fi

# If errorMsg is not empty, print it and exit
if [ ! -z "$errorMsg" ]; then
  echo -e $errorMsg
  exit 1
fi

# check if output directory has trailing slash
if [[ $OUTPUTDIR == */ ]]; then
    OUTPUTDIR=${OUTPUTDIR%/}
fi


#-------------------------------------------------#
# Prepare input data
prepare_input_local.sh $b0 $T1 $MNI_T1_1_MM_FILE $Synb0_ATLAS/mni_icbm152_t1_tal_nlin_asym_09c_2_5.nii.gz $OUTPUTDIR

# Run inference
NUM_FOLDS=5
for i in $(seq 1 $NUM_FOLDS); do 
  echo -- Performing inference on FOLD: "$i" --
  python3 $Synb0_LOCAL/inference_local.py $OUTPUTDIR/T1_norm_lin_atlas_2_5.nii.gz $OUTPUTDIR/b0_d_lin_atlas_2_5.nii.gz $OUTPUTDIR/b0_u_lin_atlas_2_5_FOLD_"$i".nii.gz $Synb0_SRC/train_lin/num_fold_"$i"_total_folds_"$NUM_FOLDS"_seed_1_num_epochs_100_lr_0.0001_betas_\(0.9\,\ 0.999\)_weight_decay_1e-05_num_epoch_*.pth 
done

# Take mean
echo Taking ensemble average
fslmerge -t $OUTPUTDIR/b0_u_lin_atlas_2_5_merged.nii.gz $OUTPUTDIR/b0_u_lin_atlas_2_5_FOLD_*.nii.gz
fslmaths $OUTPUTDIR/b0_u_lin_atlas_2_5_merged.nii.gz -Tmean $OUTPUTDIR/b0_u_lin_atlas_2_5.nii.gz

# Apply inverse xform to undistorted b0
echo Applying inverse xform to undistorted b0
ANTSepi_reg=$OUTPUTDIR/epi_reg_d_ANTS.txt
ANTSGeneric=$OUTPUTDIR/ANTS0GenericAffine.mat
antsApplyTransforms -d 3 -i $OUTPUTDIR/b0_u_lin_atlas_2_5.nii.gz -r $b0 -n BSpline -t [ $ANTSepi_reg,1 ] -t [ $ANTSGeneric,1 ] -o $OUTPUTDIR/b0_u.nii.gz

# Smooth image
echo Applying slight smoothing to distorted b0
fslmaths $b0 -s 1.15 $OUTPUTDIR/b0_d_smooth.nii.gz

# Merge distorted and undistorted b0
fslmerge -t $OUTPUTDIR/b0_all.nii.gz $OUTPUTDIR/b0_d_smooth.nii.gz $OUTPUTDIR/b0_u.nii.gz

# Merge results and run through topup
if [[ $TOPUP -eq 1 ]]; then
    # check dimensions of b0_all.nii.gz (topup requires even dimensions)
    $Synb0_LOCAL/check_nii_dims.sh $OUTPUTDIR/b0_all.nii.gz $OUTPUTDIR/b0_all.nii.gz

    echo Running topup
    topup -v --imain=$OUTPUTDIR/b0_all.nii.gz --datain=$ACQP --config=$Synb0_SRC/synb0.cnf --iout=$OUTPUTDIR/b0_all_topup.nii.gz --out=$OUTPUTDIR/topup
fi

# Done
echo FINISHED!!!
