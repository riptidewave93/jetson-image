#! /bin/bash

set -e

# Check if the user is not root
if [ "x$(whoami)" != "xroot" ]; then
  printf "\e[31mThis script requires root privilege\e[0m\n"
  exit 1
fi

# Check for env variables
if [ ! $JETSON_REPO_DIR ]; then
	printf "\e[31mError, JETSON_REPO_DIR is not set. Did you use sudo -E? Please review README.md\e[0m\n"
	exit 1
else
	# shellcheck source=./include/functions.sh
	source $JETSON_REPO_DIR/include/functions.sh
	check_required_env_vars
  board_validation
fi

# Check if $JETSON_ROOTFS_DIR if not empty
if [ ! "$(ls -A $JETSON_ROOTFS_DIR)" ]; then
	printf "\e[31mNo rootfs found in $JETSON_ROOTFS_DIR\e[0m\n"
	exit 1
fi

# If any of our dirs already exist, exit out
if [ -d "$JETSON_BUILD_DIR" ]; then
	printf "ERROR: build directory already exists at $JETSON_BUILD_DIR! Exiting..."
	exit 1
fi
mkdir -p $JETSON_BUILD_DIR

# Dirs for kernel build if we set to mainline
if [ ! -z "$MLKERNEL" ]; then
  if [ -d "$JETSON_KERNEL_DIR" ]; then
  	printf "ERROR: kernel directory already exists at $JETSON_KERNEL_DIR! Exiting..."
  	exit 1
  fi
  mkdir -p $JETSON_KERNEL_DIR
fi

# Ensure Download dir exists to cache the BSP
if [ ! -d "$JETSON_REPO_DIR/downloads" ]; then
  mkdir -p $JETSON_REPO_DIR/downloads
fi

# Download L4T if we need it
if [ ! -f "$JETSON_REPO_DIR/downloads/${BSP##*/}" ]; then
  printf "\e[32mDownload L4T...       "
  wget -q -P $JETSON_REPO_DIR/downloads $BSP
  printf "[OK]\n"
fi

# Extract the L4T if needed
if [ ! "$(ls -A $JETSON_BUILD_DIR)" ]; then
  printf "\e[32mExtract L4T...        "
  tar -jxpf $JETSON_REPO_DIR/downloads/${BSP##*/} -C $JETSON_BUILD_DIR
	rm $JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/README.txt
  printf "[OK]\n"
fi

# Copy RootFS
printf "\e[32mCopy rootfs...        "
cp -rp $JETSON_ROOTFS_DIR/* $JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/ > /dev/null
printf "[OK]\n"

# We doing a mainline kernel?
if [ ! -z "$MLKERNEL" ]; then
  # Download mainline kernel if we need it
  if [ ! -f "$JETSON_REPO_DIR/downloads/${MLKERNEL##*/}" ]; then
    printf "\e[32mDownload Linux...     "
    wget -q -P $JETSON_REPO_DIR/downloads $MLKERNEL
    printf "[OK]\n"
  fi

  # Extract the linux kernel if needed
  if [ ! "$(ls -A $JETSON_KERNEL_DIR)" ]; then
    printf "\e[32mExtract Linux...      "
    tar --strip-components 1 -zxpf $JETSON_REPO_DIR/downloads/${MLKERNEL##*/} -C $JETSON_KERNEL_DIR
    printf "[OK]\n"
  fi

  # Now to build linux quick...
  printf "Build Linux...        "
  pushd $JETSON_KERNEL_DIR > /dev/null
  make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- defconfig > /dev/null
  ./scripts/config --file .config --enable STMMAC_ETH
  ./scripts/config --file .config --enable STMMAC_PLATFORM
  ./scripts/config --file .config --enable DWMAC_DWC_QOS_ETH
  ./scripts/config --file .config --enable MARVELL_PHY
  ./scripts/config --file .config --set-val CMA_SIZE_MBYTES 256
  make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j"$(nproc)" > /dev/null
  make INSTALL_MOD_PATH=$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/ modules_install > /dev/null
  if [ -f "$JETSON_KERNEL_DIR/arch/arm64/boot/Image" ]; then
    printf "[OK]\n"
  else
    printf "\e[31m[ERR]\e[0m\n"
    printf "\e[31mError, something went wrong building the kernel!\e[0m\n"
    exit 1
  fi
  pushd $JETSON_REPO_DIR > /dev/null
fi

# Apply our patches
printf "Apply L4T Patches...  "
# Before we do anything with the BSP, we need to make sure these are gone since
# the newer BSP (5.0+) creates these for us when we run apply_binaries.sh
if [ -z "$MLKERNEL" ]; then
  if [ -c "$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/dev/random" ]; then
    rm -f $JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/dev/random
  fi
  if [ -c "$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/dev/urandom" ]; then
    rm -f $JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/dev/urandom
  fi
fi
patch $JETSON_BUILD_DIR/Linux_for_Tegra/nv_tegra/nv-apply-debs.sh < $JETSON_REPO_DIR/patches/nv-apply-debs.diff > /dev/null
if [ "$BSP_VERSION" == "t186" ]; then
  # AGX needs a few more
  patch $JETSON_BUILD_DIR/Linux_for_Tegra/tools/ota_tools/version_upgrade/ota_make_recovery_img_dtb.sh < $JETSON_REPO_DIR/patches/nv-fixup-ota_make_recovery_img_dtb.diff > /dev/null
  patch $JETSON_BUILD_DIR/Linux_for_Tegra/tools/ota_tools/version_upgrade/recovery_copy_binlist.txt < $JETSON_REPO_DIR/patches/nv-recovery-copy-binlist.diff > /dev/null
fi
printf "[OK]\n"

pushd $JETSON_BUILD_DIR/Linux_for_Tegra/ > /dev/null

printf "Build L4T...          "
if [ -z "$MLKERNEL" ]; then
  ./apply_binaries.sh > /dev/null 2>&1
else
  # Mainline build, manually push what we need
  if [ -f "$JETSON_BUILD_DIR/Linux_for_Tegra/bootloader/extlinux.conf" ]; then
  	mkdir -p "$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/boot/extlinux/"
  	install --owner=root --group=root --mode=644 -D \
      "$JETSON_BUILD_DIR/Linux_for_Tegra/bootloader/extlinux.conf" \
      "$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/boot/extlinux/" > /dev/null
  fi
  # Install kernel files
  install --owner=root --group=root --mode=644 -CD \
    "$JETSON_KERNEL_DIR/arch/arm64/boot/Image" \
    "$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/boot/Image"
  install --owner=root --group=root --mode=644 -CD \
    "$JETSON_KERNEL_DIR/arch/arm64/boot/dts/nvidia/tegra194-p2972-0000.dtb" \
    "$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/boot/"
fi
printf "[OK]\n"

# We manually set hostname, since the nvidia-l4t-init deb, when installed, wipes it
echo "jetson" > $JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/etc/hostname

# We actually generate an SD image here for the nano, otherwise we move on
printf "Create image...       "
if [ "$BSP_VERSION" == "t210" ]; then
  pushd $JETSON_BUILD_DIR/Linux_for_Tegra/tools > /dev/null
  ./jetson-disk-image-creator.sh -o jetson.img -b jetson-nano -r 300 > /dev/null 2>&1
fi
printf "[OK]\n"

printf "\e[32mImage created successfully!\n"
