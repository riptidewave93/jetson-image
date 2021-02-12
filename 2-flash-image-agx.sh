#! /bin/bash

#
# Author: Badr BADRI © pythops
#

set -e

BSP=https://developer.nvidia.com/embedded/L4T/r32_Release_v5.0/T186/Tegra186_Linux_R32.5.0_aarch64.tbz2

# Check if the user is not root
if [ "x$(whoami)" != "xroot" ]; then
        printf "\e[31mThis script requires root privilege\e[0m\n"
        exit 1
fi

# Check for env variables
if [ ! $JETSON_ROOTFS_DIR ] || [ ! $JETSON_BUILD_DIR ]; then
	printf "\e[31mYou need to set the env variables \$JETSON_ROOTFS_DIR and \$JETSON_BUILD_DIR\e[0m\n"
	exit 1
fi

# Check if $JETSON_ROOTFS_DIR if not empty
if [ ! "$(ls -A $JETSON_ROOTFS_DIR)" ]; then
	printf "\e[31mNo rootfs found in $JETSON_ROOTFS_DIR\e[0m\n"
	exit 1
fi

printf "\e[32mBuild the image ...\n"

# Create the build dir if it does not exists
mkdir -p $JETSON_BUILD_DIR

# Ensure Download dir exists to cache the BSP
if [ ! -d "./downloads" ]; then
  mkdir downloads
fi

# Download L4T if we need it
if [ ! -f "./downloads/${BSP##*/}" ]; then
  printf "\e[32mDownload L4T...       "
  wget -q -P ./downloads $BSP
  printf "[OK]\n"
fi

# Extract the L4T if needed
if [ ! "$(ls -A $JETSON_BUILD_DIR)" ]; then
  printf "\e[32mExtract L4T...       "
  tar -jxpf ./downloads/${BSP##*/} -C $JETSON_BUILD_DIR
	rm $JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/README.txt
  printf "[OK]\n"
fi

cp -rp $JETSON_ROOTFS_DIR/*  $JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/ > /dev/null

# Before we do anything with the BSP, we need to make sure these are gone since
# the newer BSP (5.0+) creates these for us when we run apply_binaries.sh
if [ -c "$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/dev/random" ]; then
  rm -f $JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/dev/random
fi
if [ -c "$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/dev/urandom" ]; then
  rm -f $JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/dev/urandom
fi

# Apply our patches
patch $JETSON_BUILD_DIR/Linux_for_Tegra/nv_tegra/nv-apply-debs.sh < patches/nv-apply-debs.diff
patch $JETSON_BUILD_DIR/Linux_for_Tegra/tools/ota_tools/version_upgrade/ota_make_recovery_img_dtb.sh < patches/nv-fixup-ota_make_recovery_img_dtb.diff
patch $JETSON_BUILD_DIR/Linux_for_Tegra/tools/ota_tools/version_upgrade/recovery_copy_binlist.txt < patches/nv-recovery-copy-binlist.diff

pushd $JETSON_BUILD_DIR/Linux_for_Tegra/ > /dev/null

printf "Extract L4T...       "
./apply_binaries.sh > /dev/null 2>&1
printf "[OK]\n"

# We manually set hostname, since the nvidia-l4t-init deb, when installed, wipes it
echo "jetson" > $JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/etc/hostname

read -p "Plug board in via USB, put in recovery, and press any key to resume...        "

printf "Flash image...       "
./nvautoflash.sh > /dev/null 2>&1
printf "[OK]\n"

printf "\e[32mImage flashed successfully!\n"
