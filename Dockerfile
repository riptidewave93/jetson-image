# Our AIO builder docker file
FROM ubuntu:22.04

RUN mkdir /repo

ARG JETSON_BOARD

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -yq \
    ansible \
	binfmt-support \
    bison \
	build-essential \
    coreutils \
    debootstrap \
    e2fsprogs \
    flex \
	gcc-aarch64-linux-gnu \
    gdisk \
    libelf-dev \
    libncurses-dev \
    libssl-dev \
    parted \
    qemu-user-static \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*