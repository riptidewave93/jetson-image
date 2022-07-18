#!/bin/bash
set -e

scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# rootfs dir check
if [ -d ${JETSON_ROOTFS_DIR} ]; then
    error_msg "rootfs already exists, this isn't a clean build! Skipping debootstrap as it should already exist."
    exit 0
else
    mkdir ${JETSON_ROOTFS_DIR}
fi

# CD into our rootfs mount, and starts the fun!
cd ${JETSON_ROOTFS_DIR}
debootstrap \
        --arch=$deb_arch \
        --foreign \
        --variant=minbase \
        --include=python3,python3-apt \
        $deb_release \
	${JETSON_ROOTFS_DIR}
cp /usr/bin/qemu-aarch64-static ${JETSON_ROOTFS_DIR}/usr/bin/
chroot ${JETSON_ROOTFS_DIR} /debootstrap/debootstrap --second-stage

# Final cleanup
rm ${JETSON_ROOTFS_DIR}/usr/bin/qemu-aarch64-static