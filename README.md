# Jetson-Image

Scripts to aid in generating Ubuntu images for Nvidia Jetson boards. Currently only tested with the Jetson Nano, and Jetson AGX Xavier.

Currently this builds Ubuntu 20.04 images using the L4T R32.6.1 BSP.

## Usage Instructions

Default login username and password is "jetson".

### Jetson-Nano
Note that the "/dev/sdX" in the last command should point to your SDCard you are flashing
```
export JETSON_BOARD=nano
source ./0-set-env-vars.sh
sudo -E ./1-create-rootfs.sh
sudo -E ./2-create-image.sh
sudo -E ./3-flash-image.sh /dev/sdX
```

### Jetson-AGX-Xavier
```
export JETSON_BOARD=agx_xavier
source ./0-set-env-vars.sh
sudo -E ./1-create-rootfs.sh
sudo -E ./2-create-image.sh
sudo -E ./3-flash-image.sh
```

### Jetson-AGX-Xavier with Mainline Linux Kernel
Please note that when this setting is used, NO L4T packages are installed! This means
there are no Nvidia libraries or drivers. Expect many things to be broken, such as
no GPU support!!!
```
export JETSON_BOARD=agx_xavier_mainline
source ./0-set-env-vars.sh
sudo -E ./1-create-rootfs.sh
sudo -E ./2-create-image.sh
sudo -E ./3-flash-image.sh
```

## To-Do
* Figure out if there's a good way to "package" releases for the AGX Xavier, so I can post releases to this repo. Most likely gotta wait for the new L4T with OTA A/B support.

## Credits

This repo is based on the work done by pythops at [pythops/jetson-nano-image](https://github.com/pythops/jetson-nano-image). Without his initial work, this repo would not exist.

## License
MIT
