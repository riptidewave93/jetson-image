#!/bin/bash
set -e

# Source our common vars
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${scripts_path}/vars.sh

debug_msg "Starting 02_download_dependencies.sh"

# Make sure our BuildEnv dir exists
if [ ! -d ${JETSON_REPO_DIR}/downloads ]; then
    mkdir ${JETSON_REPO_DIR}/downloads
fi

# Run to get our vars
check_required_env_vars
board_validation

# L4T
if [ ! -f ${JETSON_REPO_DIR}/downloads/${L4TBASENAME} ]; then
    debug_msg "Downloading L4T..."
    wget ${BSP} -O ${JETSON_REPO_DIR}/downloads/${L4TBASENAME}
    printf "[OK]\n"
fi

# If mainline build, we got more things to do
if [ -n "${MLKERNEL}" ]; then
  # Download mainline kernel if we need it
  if [ ! -f "${JETSON_REPO_DIR}/downloads/${MLKERNEL##*/}" ]; then
    printf "\e[32mDownload Linux...     "
    wget -q -P $J{ETSON_REPO_DIR}/downloads ${MLKERNEL}
    printf "[OK]\n"
  fi
fi

debug_msg "Finished 02_download_dependencies.sh"
