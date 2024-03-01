#!/bin/bash
# Make sure to set up the following environment variables

# Set up freesurfer
export FREESURFER_HOME=/Applications/freesurfer/7.1.1
source $FREESURFER_HOME/SetUpFreeSurfer.sh

# Set up FSL
export FSLDIR=/usr/local/fsl
. $FSLDIR/etc/fslconf/fsl.sh
export PATH=$PATH:/usr/local/fsl/bin

# Set up ANTS
#https://github.com/ANTsX/ANTs/releases
#https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS
#installANTs.sh
export ANTSPATH=/Users/tombresser/Documents/PhD/proj-subtypes/publication/Biological_Psychiatry/revisions/rerun/install/bin
ANTdir=/Users/tombresser/Documents/PhD/proj-subtypes/publication/Biological_Psychiatry/revisions/rerun/ANTs/Scripts
export PATH=$PATH:$ANTSPATH:$ANTdir

# Set up C3D
# https://sourceforge.net/projects/c3d/
# https://sourceforge.net/projects/c3d/files/c3d/1.0.0/c3d-1.0.0-MacOS-x86_64.dmg/download
export C3DPATH=/Applications/Convert3DGUI.app/Contents/bin
export PATH=$PATH:$C3DPATH

# Set up PyTorch
# https://pytorch.org/get-started/locally/
#pip3 install torch torchvision torchaudio nibabel numpy scipy


