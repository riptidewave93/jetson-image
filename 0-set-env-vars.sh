#! /bin/bash

set -e

export JETSON_REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export JETSON_ROOTFS_DIR=$JETSON_REPO_DIR/tempdir/rootfs
export JETSON_BUILD_DIR=$JETSON_REPO_DIR/tempdir/builddir
