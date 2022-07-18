#!/bin/bash
set -e

# Source our common vars
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${scripts_path}/vars.sh

debug_msg "Starting flash.sh"

# We need our vars
check_required_env_vars
board_validation

# The Nano flashes to an SDcard, while the AGX USB flashes. Break the logic based
# on BSP version
if [ "$BSP_VERSION" == "t210" ]; then
    # Make sure we have SDCARD_PATH set
    if [ ! ${SDCARD_PATH} ]; then
        error_msg "SDCARD_PATH is not set! Exiting..."
        exit 1
    fi

	# Check that SDCARD_PATH is a block device
	if [ ! -b ${SDCARD_PATH} ] || [ "$(lsblk | grep -w "$(basename ${SDCARD_PATH})" | awk '{print $6}')" != "disk" ]; then
		printf "\e[31m${SDCARD_PATH} is not a block device\e[0m\n"
		exit 1
	fi

	# Check jetson image file
	IMGPATH=$JETSON_BUILD_DIR/Linux_for_Tegra/tools/jetson.img
	if [ ! -e $IMGPATH ] || [ ! -s $IMGPATH ]; then
		printf "\e[31m$IMGPATH does not exist or has 0 B in size\e[0m\n"
		exit 1
	fi

	# Depending on the block device provided, determine what partition mapping
	# to use when resizing the rootfs
	APP_PART="1"
	if [[ "${SDCARD_PATH}" == *"mmcblk"* ]] || [[ "${SDCARD_PATH}" == *"nvme"* ]]; then
		APP_PART="p1"
	fi

	# Unmount sdcard
	if [ "$(mount | grep ${SDCARD_PATH})" ]; then
		printf "\e[32mUnmount SD card... "
		for mount_point in $(mount | grep ${SDCARD_PATH} | awk '{ print $1}'); do
			sudo umount $mount_point > /dev/null
		done
		printf "[OK]\e[0m\n"
	fi

	# Flash image
	printf "\e[32mFlash the sdcard... \e[0m"
	sudo dd if=$IMGPATH of=${SDCARD_PATH} bs=4M conv=fsync status=progress
	printf "\e[32m[OK]\e[0m\n"

	# Extend the partition
	printf "\e[32mExtend the partition... "
	sudo partprobe ${SDCARD_PATH} &> /dev/null

	sudo sgdisk -e ${SDCARD_PATH} > /dev/null

	end_sector=$(sgdisk -p ${SDCARD_PATH} |  grep -i "Total free space is" | awk '{ print $5 }')
	start_sector=$(sgdisk -i 1 ${SDCARD_PATH} | grep "First sector" | awk '{print $3}')

	# Recrate the partition
	sgdisk -d 1 ${SDCARD_PATH} > /dev/null

	sgdisk -n 1:$start_sector:$end_sector ${SDCARD_PATH} /dev/null

	sgdisk -c 1:APP ${SDCARD_PATH} > /dev/null

	printf "[OK]\e[0m\n"

	# Extend fs
	printf "\e[32mExtend the fs... "
	e2fsck -fp ${SDCARD_PATH}${APP_PART} > /dev/null
	resize2fs ${SDCARD_PATH}${APP_PART} > /dev/null
	sync
	printf "[OK]\e[0m\n"

	printf "\e[32mSuccess!\n"
	printf "\e[32mYour sdcard is ready!\n"
	exit 0
elif [ "$BSP_VERSION" == "t186" ]; then
	# AGX
	read -p "Please plug your board in via USB, put it in recovery, and press any key to start the flashing process..."

	pushd $JETSON_BUILD_DIR/Linux_for_Tegra/ > /dev/null

	printf "\e[32mFlash image...       "

	# Are we mainline, or no?!
	if [ ! $MLKERNEL ]; then
		./nvautoflash.sh > /dev/null 2>&1
		FLASHRC=$?
	else
		./flash.sh -K $JETSON_KERNEL_DIR/arch/arm64/boot/Image \
		  -d $JETSON_KERNEL_DIR/arch/arm64/boot/dts/nvidia/tegra194-p2972-0000.dtb \
		  jetson-agx-xavier-devkit internal > /dev/null 2>&1
		FLASHRC=$?
	fi

	# Did we flash OK?
	if [ $FLASHRC -eq 0 ]; then
		printf "[OK]\e[0m\n"
		printf "\e[32mImage flashed successfully!\n"
	else
		printf "\e[31m[ERR]\e[0m\n"
		printf "\e[31mThere was an issue flashing your board! Exiting...\n"
		exit 1
	fi
fi

debug_msg "Finished flash.sh"