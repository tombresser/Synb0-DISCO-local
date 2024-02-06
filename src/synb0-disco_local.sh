#!/bin/bash
# This is a wrapper to run Synb0-DISCO locally and is based on pipeline.sh.
# The function is called as follows:
# Synb0-DISCO/src/synb0-disco_local.sh -i -s sub-99_T1w.nii.gz sub-99_b0.nii.gz path/to/outdir
# It takes the following arguments:
# -i|--notopup: if set, topup is not run
# -s|--stripped: if set, the 1mm T1 atlas is stripped

T1=$1
b0=$2
OUTPUTDIR=$3
TOPUP=1

# check if output directory has trailing slash
if [[ $OUTPUTDIR == */ ]]; then
    OUTPUTDIR=${OUTPUTDIR%/}
fi

## Set path for executable
Synb0_path=$(dirname "$0")
Synb0_path=${Synb0_path%/src}
export Synb0_SRC=${Synb0_path}/src
export Synb0_PROC=${Synb0_path}/data_processing
export Synb0_ATLAS=${Synb0_path}/atlases
export PATH=$PATH:$Synb0_SRC:$Synb0_PROC:$Synb0_ATLAS

# can be moved inline
MNI_T1_1_MM_FILE=$Synb0_path/atlases/mni_icbm152_t1_tal_nlin_asym_09c.nii.gz

for arg in "$@"
do
    case $arg in
        -i|--notopup)
            TOPUP=0
	        ;;
    	-s|--stripped)
	        MNI_T1_1_MM_FILE=$Synb0_ATLAS/mni_icbm152_t1_tal_nlin_asym_09c_mask.nii.gz
            ;;
    esac
done

# Set paths for the following tools;
# FreeSurfer, FSL, ANTs, c3d, PyTorch, nibabel
source my_paths.sh

# extract b0 from dwi if missing
# TODO: conditional on existence of b0
#fslroi sub-99_dwi.nii.gz sub-99_b0.nii.gz 0 1

# check and correct dimensions of input
check_nii_dims.sh $b0 $b0
#Synb0-DISCO/src/check_nii_dims.sh sub-99_dwi.nii.gz sub-99_dwi.nii.gz

# Prepare input
#data_processing/prepare_input.sh INPUTS/b0.nii.gz INPUTS/T1.nii.gz $MNI_T1_1_MM_FILE atlases/mni_icbm152_t1_tal_nlin_asym_09c_2_5.nii.gz OUTPUTS
prepare_input.sh $b0 $T1 $Synb0_ATLAS/mni_icbm152_t1_tal_nlin_asym_09c.nii.gz $Synb0_ATLAS/mni_icbm152_t1_tal_nlin_asym_09c_2_5.nii.gz $OUTPUTDIR

# Run inference
NUM_FOLDS=5
for i in $(seq 1 $NUM_FOLDS);
  do echo -- Performing inference on FOLD: "$i" --
  #python3.6 /extra/inference.py /OUTPUTS/T1_norm_lin_atlas_2_5.nii.gz /OUTPUTS/b0_d_lin_atlas_2_5.nii.gz /OUTPUTS/b0_u_lin_atlas_2_5_FOLD_"$i".nii.gz /extra/dual_channel_unet/num_fold_"$i"_total_folds_"$NUM_FOLDS"_seed_1_num_epochs_100_lr_0.0001_betas_\(0.9\,\ 0.999\)_weight_decay_1e-05_num_epoch_*.pth
  python3 $Synb0_SRC/inference.py $OUTPUTDIR/T1_norm_lin_atlas_2_5.nii.gz $OUTPUTDIR/b0_d_lin_atlas_2_5.nii.gz $OUTPUTDIR/b0_u_lin_atlas_2_5_FOLD_"$i".nii.gz $Synb0_SRC/train_lin/num_fold_"$i"_total_folds_"$NUM_FOLDS"_seed_1_num_epochs_100_lr_0.0001_betas_\(0.9\,\ 0.999\)_weight_decay_1e-05_num_epoch_*.pth
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

if [[ $TOPUP -eq 1 ]]; then
    # Merge results and run through topup
    echo Running topup
    fslmerge -t $OUTPUTDIR/b0_all.nii.gz $OUTPUTDIR/b0_d_smooth.nii.gz $OUTPUTDIR/b0_u.nii.gz
    topup -v --imain=$OUTPUTDIR/b0_all.nii.gz --datain=acqparams.txt --config=$Synb0_SRC/synb0.cnf --iout=$OUTPUTDIR/b0_all_topup.nii.gz --out=$OUTPUTDIR/topup
fi

# Done
echo FINISHED!!!
