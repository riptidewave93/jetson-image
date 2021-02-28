#! /bin/bash

#
# Author: Badr BADRI © pythops
#

set -e

ARCH=arm64
RELEASE=focal

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

# If root dir already exists, exit out
if [ -d "$JETSON_ROOTFS_DIR" ]; then
	printf "ERROR: root dir already exists at $JETSON_ROOTFS_DIR! Exiting..."
	exit 1
fi

# Install prerequisites packages
printf "\e[32mInstall the dependencies...     "
apt-get update > /dev/null
apt-get install --no-install-recommends -y qemu-user-static debootstrap \
	binfmt-support coreutils parted wget gdisk e2fsprogs ansible \
	build-essential libncurses-dev bison flex libssl-dev libelf-dev \
	gcc-aarch64-linux-gnu > /dev/null
printf "[OK]\n"

# Create rootfs directory
printf "Create rootfs directory...      "
mkdir -p $JETSON_ROOTFS_DIR
printf "[OK]\n"

# Run debootstrap first stage
printf "Run debootstrap first stage...  "
debootstrap \
        --arch=$ARCH \
        --foreign \
        --variant=minbase \
        --include=python3,python3-apt \
        $RELEASE \
	$JETSON_ROOTFS_DIR > /dev/null
printf "[OK]\n"

cp /usr/bin/qemu-aarch64-static $JETSON_ROOTFS_DIR/usr/bin

# Run debootstrap second stage
printf "Run debootstrap second stage... "
chroot $JETSON_ROOTFS_DIR /bin/bash -c "/debootstrap/debootstrap --second-stage" > /dev/null
printf "[OK]\n"

# Kick off ansible on the rootfs
printf "Run ansible against rootfs...   "
cd $JETSON_REPO_DIR/ansible
$(which ansible-playbook) jetson.yaml > /dev/null
printf "[OK]\n"

printf "Success!\n"
