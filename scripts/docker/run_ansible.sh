#!/bin/bash
set -e

scripts_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && cd .. && pwd )"
. ${scripts_path}/vars.sh

# CD into our rootfs mount, and run our ansible
cd ${JETSON_REPO_DIR}/ansible
$(which ansible-playbook) jetson.yaml