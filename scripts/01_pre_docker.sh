#!/bin/bash
set -e

# Source our common vars
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${scripts_path}/vars.sh

debug_msg "Starting 01_pre_docker.sh"

# Make sure our BuildEnv dir exists
if [ -d ${JETSON_REPO_DIR}/tempdir ]; then
    error_msg "tempdir already exists, this isn't a clean build! Things might fail, but we're going to try!"
else
    mkdir ${JETSON_REPO_DIR}/tempdir
fi

# Always build to pickup changes/updates/improvements
debug_msg "Building jetson-image:builder"
docker build -t jetson-image:builder ${JETSON_REPO_DIR}

debug_msg "Finished 01_pre_docker.sh"