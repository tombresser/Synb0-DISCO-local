#!/bin/bash
# function to add slice of zeros to the input nii file if the dimensions are odd
#
# Usage: add_slice_with_zeros.sh input_nii output_nii
# Example: add_slice_with_zeros.sh input.nii.gz output.nii.gz

# Get inputs
input_nii=$1
output_nii=$2
ADJUSTED=0

# check is path to output_nii exists
if [ ! -d $(dirname $output_nii) ]; then
    echo "Path to $output_nii does not exist"
    exit 1
fi

# get dimensions
dim1=$(fslhd $1 | grep -w dim1 | awk '{print $2}')
dim2=$(fslhd $1 | grep -w dim2 | awk '{print $2}')
dim3=$(fslhd $1 | grep -w dim3 | awk '{print $2}')

echo "Current dimensions are $dim1 $dim2 $dim3"

# if dim1 is an odd number, then add a slice with zeros to dim1
if ((dim1 % 2 != 0)); then
    ADJUSTED=1
    echo "  - adding slice with zeros to dim1 of $1"

    # extract a slice from the input.nii.gz file
    fslroi $1 zero_slice.nii.gz 0 1 0 $dim2 0 $dim3
    fslmaths zero_slice.nii.gz -mul 0 zero_slice.nii.gz
    fslmerge -x $2 $1 zero_slice.nii.gz
fi

# if dim2 is an odd number, then add a slice with zeros to dim2
if ((dim2 % 2 != 0)); then
    ADJUSTED=1
    echo "  - adding slice with zeros to dim2 of $1"

    # extract a slice from the input.nii.gz file
    fslroi $1 zero_slice.nii.gz 0 $dim1 0 1 0 $dim3
    fslmaths zero_slice.nii.gz -mul 0 zero_slice.nii.gz
    fslmerge -y $2 $1 zero_slice.nii.gz
fi

# if dim3 is an odd number, then add a slice with zeros to dim3
if ((dim3 % 2 != 0)); then
    ADJUSTED=1
    echo "  - adding slice with zeros to dim3 of $1"

    # extract a slice from the input.nii.gz file
    fslroi $1 zero_slice.nii.gz 0 $dim1 0 $dim2 0 1
    fslmaths zero_slice.nii.gz -mul 0 zero_slice.nii.gz
    fslmerge -z $2 $1 zero_slice.nii.gz
fi

# get new dimensions
dim1_new=$(fslhd $2 | grep -w dim1 | awk '{print $2}')
dim2_new=$(fslhd $2 | grep -w dim2 | awk '{print $2}')
dim3_new=$(fslhd $2 | grep -w dim3 | awk '{print $2}')



# if adjusted, print message
if [ $ADJUSTED -eq 1 ]; then
    echo "Finished: new dimensions are $dim1_new $dim2_new $dim3_new"
    echo "IMPORTANT: when running topup and eddy, make sure both the b0 and dwi scan have similair dimensions"
elif [ $ADJUSTED -eq 0 ]; then
    echo "Dimensions are already even"
fi

# remove if exists
if [ -f zero_slice.nii.gz ]; then
    rm zero_slice.nii.gz
fi