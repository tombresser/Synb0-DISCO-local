#!/bin/bash
# Collect version data of the used tools and store in package_versions.txt

DATE=$(date +%Y-%m-%d)

#if src/package_versions.txt exists, rename it to pre{date}_package_versions.txt
if [ -f src/package_versions.txt ]; then
    mv src/package_versions.txt src/pre${DATE}_package_versions.txt.txt
fi

# start file
touch src/package_versions.txt
echo $DATE > package_versions.txt.txt
echo "------" >> package_versions.txt.txt

# python, pytorch and nibabel
python --version >> package_versions.txt
echo "PyTorch" >> package_versions.txt
python -c "import torch; print(torch.__version__)" >> package_versions.txt
echo "nibabel" >> package_versions.txt
python -c "import nibabel; print(nibabel.__version__)" >> package_versions.txt
echo "" >> package_versions.txt

# Freesurfer
#source /usr/local/freesurfer/SetUpFreeSurfer.sh
mri_convert --version >> package_versions.txt
echo "" >> package_versions.txt

# FSL
echo FSL
flirt -version >> package_versions.txt
echo "" >> package_versions.txt

# ANTS
antsRegistration --version >> package_versions.txt
echo "" >> package_versions.txt

# C3D (not working)
c3d --version >> package_versions.txt


