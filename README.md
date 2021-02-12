# Jetson-Image

Scripts to aid in generating Ubuntu images for Nvidia Jetson boards. Currently only tested with the Jetson Nano, and Jetson AGX Xavier.

Currently this builds Ubuntu 20.04 images using the L4T R32.5 BSP.

## Usage Instructions

### Jetson-Nano
Note that the "/dev/sdX" in the last command should point to your SDCard you are flashing
```
source ./0-set-env-vars.sh
sudo -E ./1-create-rootfs.sh
sudo -E ./2-create-image.sh
sudo -E ./3-flash-image.sh ./tempdir/builddir/Linux_for_Tegra/tools/jetson.img /dev/sdX
```

### Jetson-AGX-Xavier
```
source ./0-set-env-vars.sh
sudo -E ./1-create-rootfs.sh
sudo -E ./2-flash-image-agx.sh
```

## Credits

This repo is based on the work done by pythops at [pythops/jetson-nano-image](https://github.com/pythops/jetson-nano-image). Without his initial work, this repo would not exist.

## License
MIT
