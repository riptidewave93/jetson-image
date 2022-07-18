#!/bin/bash
export JETSON_REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
export JETSON_ROOTFS_DIR=$JETSON_REPO_DIR/tempdir/rootfs
export JETSON_BUILD_DIR=$JETSON_REPO_DIR/tempdir/builddir
export JETSON_KERNEL_DIR=$JETSON_REPO_DIR/tempdir/kernel

# Distro
deb_release="jammy" # 22.04
deb_arch="arm64"

debug_msg () {
    BLU='\033[0;32m'
    NC='\033[0m'
    printf "${BLU}${@}${NC}\n"
}

error_msg () {
    BLU='\033[0;31m'
    NC='\033[0m'
    printf "${BLU}${@}${NC}\n"
}

# Validate our board stuff
function check_required_env_vars {
  # Inputs: None
  # Outputs: None

  # Validate all vars set via user, and 0-set-env-vars, exist for us
  if [ ! $JETSON_REPO_DIR ] || [ ! $JETSON_ROOTFS_DIR ] || \
    [ ! $JETSON_BUILD_DIR ] || [ ! $JETSON_KERNEL_DIR ] || \
    [ ! $JETSON_BOARD ]; then
  	error_msg "There are missing environment variables! Please review README.md"
  	exit 1
  fi
}

function board_validation {
  # Inputs: None
  # Outputs: None
  # Note we do export new env vars, but the function has no "return"

  if [ ! $JETSON_BOARD ]; then
    printf "\e[31mError: JETSON_BOARD is not set, can't run board_validation!\e[0m\n"
    exit 1
  fi

  # Always unset this, so it's ONLY used on boards with it set
  unset MLKERNEL

  case $JETSON_BOARD in
    nano)
      board_bsp_exports t210
      ;;
    nano_mainline)
      error_msg "Error: nano_mainline is not yet implemented!"
      exit 1
      ;;
    agx_xavier)
      board_bsp_exports t186
      ;;
    agx_xavier_mainline)
      printf "\e[31mWarning: Board $JETSON_BOARD is HIGHLY EXPERIMENTAL and many things do not work!\e[0m\n"
      board_bsp_exports t186
      export MLKERNEL=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/snapshot/linux-5.18.y.tar.gz
      ;;
    *)
      error_msg "Board $JETSON_BOARD is unsupported!"
      exit 1
      ;;
  esac
}

function board_bsp_exports {
  # Inputs
  # $1 = BSP codename to export
  case $1 in
    t186)
      # AGX
      export BSP_VERSION=t186
      export BSP=https://developer.nvidia.com/embedded/l4t/r32_release_v7.2/t186/jetson_linux_r32.7.2_aarch64.tbz2
      ;;
    t210)
      # Nano
      export BSP_VERSION=t210
      export BSP=https://developer.nvidia.com/embedded/l4t/r32_release_v7.2/t210/jetson-210_linux_r32.7.2_aarch64.tbz2
      ;;
    *)
      error_msg "Invalid input to board_bsp_exports!"
      exit 1
      ;;
  esac
  export L4TBASENAME=$(basename ${BSP})
}