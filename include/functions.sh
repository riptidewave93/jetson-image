#! /bin/bash
#
# An easy functions script we can call in everything to load in defaults
# and required env vars

function check_required_env_vars {
  # Inputs: None
  # Outputs: None

  # Validate all vars set via user, and 0-set-env-vars, exist for us
  if [ ! $JETSON_REPO_DIR ] || [ ! $JETSON_ROOTFS_DIR ] || \
    [ ! $JETSON_BUILD_DIR ] || [ ! $JETSON_KERNEL_DIR ] || \
    [ ! $JETSON_BOARD ]; then
  	printf "\e[31mThere are missing environment variables! Did you use sudo -E? Please review README.md\e[0m\n"
  	exit 1
  fi
}

function board_bsp_exports {
  # Inputs
  # $1 = BSP codename to export
  case $1 in
    t186)
      # AGX
      export BSP_VERSION=t186
      export BSP=https://developer.nvidia.com/embedded/l4t/r32_release_v6.1/t186/jetson_linux_r32.6.1_aarch64.tbz2
      ;;
    t210)
      # Nano
      export BSP_VERSION=t210
      export BSP=https://developer.nvidia.com/embedded/l4t/r32_release_v6.1/t210/jetson-210_linux_r32.6.1_aarch64.tbz2
      ;;
    *)
      printf "\e[31mError: invalid input to board_bsp_exports!\e[0m\n"
      exit 1
      ;;
  esac
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
      printf "\e[31mError: nano_mainline is not yet implemented!\e[0m\n"
      exit 1
      ;;
    agx_xavier)
      board_bsp_exports t186
      ;;
    agx_xavier_mainline)
      printf "\e[31mWarning: Board $JETSON_BOARD is HIGHLY EXPERIMENTAL and many things do not work!\e[0m\n"
      board_bsp_exports t186
      export MLKERNEL=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/snapshot/linux-5.14.y.tar.gz
      ;;
    *)
      printf "\e[31mError: board $JETSON_BOARD is unsupported!\e[0m\n"
      exit 1
      ;;
  esac
}
