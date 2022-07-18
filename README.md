# Jetson-Image

Scripts to aid in generating Ubuntu images for Nvidia Jetson boards. Currently only tested with the Jetson Nano, and Jetson AGX Xavier.

Currently this builds Ubuntu 22.04 images using the L4T R32.7.2 BSP.

## Usage Instructions

Default login username and password is "jetson".

### Jetson-Nano
Note that the "/dev/sdX" in the last command should point to your SDCard you are flashing
```
JETSON_BOARD=nano make build
JETSON_BOARD=nano SDCARD_PATH=/dev/sdX make flash
```

### Jetson-AGX-Xavier
```
JETSON_BOARD=agx_xavier make build
JETSON_BOARD=agx_xavier make flash
```

### Jetson-AGX-Xavier with Mainline Linux Kernel
Please note that when this setting is used, NO L4T packages are installed! This means
there are no Nvidia libraries or drivers. Expect many things to be broken, such as
no GPU support!!!
```
JETSON_BOARD=agx_xavier_mainline make build
JETSON_BOARD=agx_xavier_mainline make flash

```

## To-Do
* Figure out if there's a good way to "package" releases for the AGX Xavier, so I can post releases to this repo. Most likely gotta wait for the new L4T with OTA A/B support.
* Way more testing!
* Move to the new developer preview which is a big change from this release.

## Credits

This repo is based on the work done by pythops at [pythops/jetson-nano-image](https://github.com/pythops/jetson-nano-image). Without his initial work, this repo would not exist.

## License
MIT
