#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

KERNEL_VERSION=${KERNEL_VERSION:-"6.1.33"}

download_kernel_source() {
    echo ">> Downloading the kernel source"
    local url_base="https://cdn.kernel.org/pub/linux/kernel"
    local major_version=${1}
    # local download_url="${url_base}/v${major_version}.x/$LATEST_VERSION.tar.xz"
    curl -L https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz > linux-${KERNEL_VERSION}.tar.xz
}

extract_kernel_source() {
    echo ">> extracting"
    mkdir -p linux-${KERNEL_VERSION}
    tar --skip-old-files --strip-components=1 -xf linux-${KERNEL_VERSION}.tar.xz -C linux-${KERNEL_VERSION}
}

build_kernel() {
    echo ">> Building the kernel"
    cd linux-${KERNEL_VERSION}
    make defconfig
    make -j "$(nproc)"
    # copy it somewhere useful
    # build/kernel/...
}

download_kernel_source 6
extract_kernel_source
build_kernel
