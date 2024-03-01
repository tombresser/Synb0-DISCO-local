#!/bin/bash
# Collect version data of the used tools and store in package_versions.txt

DATE=$(date +%Y-%m-%d)

# get location of this script
DIR=$(dirname "$0")
echo $DIR

#if src/package_versions.txt exists, rename it to pre{date}_package_versions.txt
if [ -f package_versions.txt ]; then
    # get first line from package_versions.txt
    OLD_DATE=$(head -n 1 package_versions.txt)
    mv package_versions.txt ${OLD_DATE}_package_versions.txt
fi

# start file
echo $DATE > package_versions.txt
echo "------" >> package_versions.txt

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
echo FSL version>> package_versions.txt
#flirt -version >> package_versions.txt
cat $FSLDIR/etc/fslversion >> package_versions.txt
echo "" >> package_versions.txt
echo "" >> package_versions.txt

# ANTS
antsRegistration --version >> package_versions.txt
#echo "" >> package_versions.txt

# Get C3D version from Info.plis
echo C3D version >> package_versions.txt
/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" /Applications/Convert3DGUI.app/Contents/Info.plist >> package_versions.txt



