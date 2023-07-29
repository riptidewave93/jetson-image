#!/bin/bash
set -e

# Source our common vars
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${scripts_path}/vars.sh

debug_msg "Starting 04_post_docker.sh"

if [ -d ${JETSON_BUILD_DIR} ]; then
    debug_msg "WARNING: builddir already exists! Cleaning up..."
    sudo rm -rf ${JETSON_BUILD_DIR}
fi
mkdir -p ${JETSON_BUILD_DIR}

# Run to get our vars
check_required_env_vars
board_validation

# Extract L4T
export L4TBASENAME=$(basename ${BSP})
tar -jxpf ${JETSON_REPO_DIR}/downloads/${L4TBASENAME} -C ${JETSON_BUILD_DIR}
rm ${JETSON_BUILD_DIR}/Linux_for_Tegra/rootfs/README.txt

# Copy rootfs
sudo cp -rp $JETSON_ROOTFS_DIR/* ${JETSON_BUILD_DIR}/Linux_for_Tegra/rootfs/

# Apply our patches
printf "Apply L4T Patches...  "
# Before we do anything with the BSP, we need to make sure these are gone since
# the newer BSP (5.0+) creates these for us when we run apply_binaries.sh
if [ -z "$MLKERNEL" ]; then
  if [ -c "$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/dev/random" ]; then
    sudo rm -f $JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/dev/random
  fi
  if [ -c "$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/dev/urandom" ]; then
    sudo rm -f $JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/dev/urandom
  fi
fi
patch $JETSON_BUILD_DIR/Linux_for_Tegra/nv_tegra/nv-apply-debs.sh < $JETSON_REPO_DIR/patches/l4t/nv-apply-debs.diff > /dev/null
rm $JETSON_BUILD_DIR/Linux_for_Tegra/tools/python-jetson-gpio_2.0.17_arm64.deb # Be gone old cruft
if [ "$BSP_VERSION" == "t186" ]; then
  # AGX needs a few more
  patch $JETSON_BUILD_DIR/Linux_for_Tegra/tools/ota_tools/version_upgrade/ota_make_recovery_img_dtb.sh < $JETSON_REPO_DIR/patches/l4t/nv-fixup-ota_make_recovery_img_dtb.diff > /dev/null
  patch $JETSON_BUILD_DIR/Linux_for_Tegra/tools/ota_tools/version_upgrade/recovery_copy_binlist.txt < $JETSON_REPO_DIR/patches/l4t/nv-recovery-copy-binlist.diff > /dev/null
else
  # Nano
  cp $JETSON_REPO_DIR/patches/l4t/python-jetson-gpio_2.0.17_arm64.deb-patched $JETSON_BUILD_DIR/Linux_for_Tegra/tools/python-jetson-gpio_2.0.17_arm64.deb
fi
printf "[OK]\n"

pushd $JETSON_BUILD_DIR/Linux_for_Tegra/ > /dev/null

printf "Build L4T...          "
if [ -z "$MLKERNEL" ]; then
  sudo ./apply_binaries.sh
else
  # Mainline build, manually push what we need
  if [ -f "$JETSON_BUILD_DIR/Linux_for_Tegra/bootloader/extlinux.conf" ]; then
  	sudo mkdir -p "$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/boot/extlinux/"
  	sudo install --owner=root --group=root --mode=644 -D \
      "$JETSON_BUILD_DIR/Linux_for_Tegra/bootloader/extlinux.conf" \
      "$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/boot/extlinux/" > /dev/null
  fi
  # Install kernel files
  sudo install --owner=root --group=root --mode=644 -CD \
    "$JETSON_KERNEL_DIR/arch/arm64/boot/Image" \
    "$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/boot/Image"
  sudo install --owner=root --group=root --mode=644 -CD \
    "$JETSON_KERNEL_DIR/arch/arm64/boot/dts/nvidia/tegra194-p2972-0000.dtb" \
    "$JETSON_BUILD_DIR/Linux_for_Tegra/rootfs/boot/"
fi
printf "[OK]\n"

# We manually set hostname, since the nvidia-l4t-init deb, when installed, wipes it
echo "jetson" | sudo tee "${JETSON_BUILD_DIR}/Linux_for_Tegra/rootfs/etc/hostname"

debug_msg "Finished 04_post_docker.sh"