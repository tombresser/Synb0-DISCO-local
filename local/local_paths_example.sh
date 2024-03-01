#!/bin/bash
# This is an example file with installation guide URLS and how to setup the local paths to the required toolboxes.
# Plese make sure that all required tools are installed and the paths are set 
# correctly in a copy of this file named 'src/local_paths.sh'.
#
# Installation guides:
# Freesurfer: 
#    - https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall
# FSL: 
#    - https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation
# ANTS: 
#    - https://github.com/ANTsX/ANTs
#    - local compiling https://github.com/ANTsX/ANTs/wiki/Compiling-ANTs-on-Linux-and-Mac-OS
# C3D: 
#    - https://sourceforge.net/projects/c3d/
#    - version 1.0.0 is also available at https://sourceforge.net/projects/c3d/files/c3d/1.0.0
# PyTorch: 
#    - https://pytorch.org/get-started/locally/
#    - or install using the terminal: `pip3 install torch torchvision torchaudio nibabel numpy scipy`


#-- Local paths --#
# Freesurfer
export FREESURFER_HOME=/Applications/freesurfer/7.1.1
source $FREESURFER_HOME/SetUpFreeSurfer.sh

# FSL
export FSLDIR=/usr/local/fsl
. $FSLDIR/etc/fslconf/fsl.sh
export PATH=$PATH:/usr/local/fsl/bin

# ANTS (binary and scripts location)
export ANTSPATH=/yourdir/install/bin
ANTdir=/yourdir/ANTs/Scripts
export PATH=$PATH:$ANTSPATH:$ANTdir

# C3D
export C3DPATH=/Applications/Convert3DGUI.app/Contents/bin
export PATH=$PATH:$C3DPATH