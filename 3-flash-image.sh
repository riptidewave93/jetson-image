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

# Check the arguments (only matters for nano)
if [ "$#" -ne 1 ] && [ "$BSP_VERSION" == "t210" ] ; then
	echo "3-flash-image.sh </path/to/sdcard>"
	echo "example: ./3-flash-image.sh /dev/mmcblk0"
	echo "Note, if this is used with the Jetson AGX Xavier, please ommit providing an sdcard path."
	exit 1
fi

# The Nano flashes to an SDcard, while the AGX USB flashes. Break the logic based
# on BSP version
if [ "$BSP_VERSION" == "t210" ]; then
	# Check that $2 is a block device
	if [ ! -b $2 ] || [ "$(lsblk | grep -w "$(basename $2)" | awk '{print $6}')" != "disk" ]; then
		printf "\e[31m$2 is not a block device\e[0m\n"
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
	if [[ "$2" == *"mmcblk"* ]] || [[ "$2" == *"nvme"* ]]; then
		APP_PART="p1"
	fi

	# Unmount sdcard
	if [ "$(mount | grep $2)" ]; then
		printf "\e[32mUnmount SD card... "
		for mount_point in $(mount | grep $2 | awk '{ print $1}'); do
			sudo umount $mount_point > /dev/null
		done
		printf "[OK]\e[0m\n"
	fi

	# Flash image
	printf "\e[32mFlash the sdcard... \e[0m"
	dd if=$IMGPATH of=$2 bs=4M conv=fsync status=progress
	printf "\e[32m[OK]\e[0m\n"

	# Extend the partition
	printf "\e[32mExtend the partition... "
	partprobe $2 &> /dev/null

	sgdisk -e $2 > /dev/null

	end_sector=$(sgdisk -p $2 |  grep -i "Total free space is" | awk '{ print $5 }')
	start_sector=$(sgdisk -i 1 $2 | grep "First sector" | awk '{print $3}')

	# Recrate the partition
	sgdisk -d 1 $2 > /dev/null

	sgdisk -n 1:$start_sector:$end_sector $2 /dev/null

	sgdisk -c 1:APP $2 > /dev/null

	printf "[OK]\e[0m\n"

	# Extend fs
	printf "\e[32mExtend the fs... "
	e2fsck -fp $2${APP_PART} > /dev/null
	resize2fs $2${APP_PART} > /dev/null
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
