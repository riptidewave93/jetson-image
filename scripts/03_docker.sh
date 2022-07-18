#!/bin/bash
set -e

# Source our common vars
scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${scripts_path}/vars.sh

debug_msg "Starting 03_docker.sh"

# SAFETY NET - trap it, even tho we have makefile with set -e
debug_msg "Docker: debootstraping..."
docker run --rm --privileged --cap-add=ALL -v /dev:/dev -v "${JETSON_REPO_DIR}:/repo:Z" -it jetson-image:builder /repo/scripts/docker/run_debootstrap.sh

debug_msg "Docker: Running ansible..."
docker run --rm --privileged --cap-add=ALL -v /dev:/dev -v "${JETSON_REPO_DIR}:/repo:Z" -it jetson-image:builder /repo/scripts/docker/run_ansible.sh

debug_msg "Finished 03_docker.sh"
